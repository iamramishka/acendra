import 'dart:convert';
import 'dart:async';
import 'package:acendra/core/config/env_config.dart';
import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/pdf_reader/data/protected_pdf_repository.dart';
import 'package:acendra/features/pdf_reader/data/pdf_document_lease.dart';
import 'package:acendra/features/pdf_reader/data/pdf_progress_local.dart';
import 'package:acendra/features/pdf_reader/data/pdf_transport.dart'
    if (dart.library.js_interop) 'package:acendra/features/pdf_reader/data/pdf_transport_web.dart'
    as transport;
import 'package:acendra/features/pdf_reader/presentation/widgets/pdf_error_state.dart';
import 'package:acendra/features/pdf_reader/presentation/widgets/pdf_loading_state.dart';
import 'package:acendra/features/pdf_reader/presentation/widgets/pdf_reader_footer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart' as pdfx;

String? pdfSessionIdentity(String? token) {
  if (token == null) {
    return null;
  }
  try {
    final claims =
        jsonDecode(
              utf8.decode(
                base64Url.decode(base64Url.normalize(token.split('.')[1])),
              ),
            )
            as Map;
    return claims['session_id'] as String?;
  } catch (_) {
    return null;
  }
}

class ProtectedPdfLesson extends ConsumerWidget {
  const ProtectedPdfLesson({super.key, required this.lessonId});
  final String lessonId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(currentSessionProvider);
    if (session == null) {
      return const Center(child: Text('Sign in to access this PDF.'));
    }
    return _AuthenticatedPdf(
      key: ValueKey((
        lessonId,
        session.user.id,
        pdfSessionIdentity(session.accessToken),
      )),
      lessonId: lessonId,
      bearer: session.accessToken,
    );
  }
}

class _AuthenticatedPdf extends StatefulWidget {
  const _AuthenticatedPdf({
    super.key,
    required this.lessonId,
    required this.bearer,
  });
  final String lessonId, bearer;
  @override
  State<_AuthenticatedPdf> createState() => _AuthenticatedPdfState();
}

class _AuthenticatedPdfState extends State<_AuthenticatedPdf> {
  PdfTransport? _transport;
  pdfx.PdfController? _controller;
  PdfDocumentLease<pdfx.PdfDocument>? _document;
  String? _error;
  bool _loading = true;
  int _page = 1, _pages = 1;
  int _generation = 0;
  static const _minZoom = 1.0, _maxZoom = 3.0;
  final _zoomController = TransformationController();
  double _zoom = 1.0;

  void _setZoom(double zoom) {
    final clamped = zoom.clamp(_minZoom, _maxZoom);
    _zoomController.value = Matrix4.diagonal3Values(clamped, clamped, 1);
    setState(() => _zoom = clamped);
  }

  void _releaseRenderer() {
    _controller?.dispose();
    _controller = null;
    final document = _document;
    _document = null;
    if (document != null) {
      unawaited(
        document.release().catchError((Object _) {
          // Release failure cannot restore the detached reader or content.
          if (mounted) {
            setState(() => _error = 'The PDF reader could not close cleanly.');
          }
        }),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _generation++;
    _transport?.cancel();
    _releaseRenderer();
    _zoomController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    _transport?.cancel();
    _releaseRenderer();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final base = Uri.tryParse(EnvConfig.supabaseUrl);
      if (base == null ||
          base.host.isEmpty ||
          (base.scheme != 'https' &&
              !{'localhost', '127.0.0.1'}.contains(base.host))) {
        throw const ProtectedPdfFailure(
          'Protected PDF delivery is currently unavailable.',
        );
      }
      final client = transport.createPdfTransport();
      _transport = client;
      final repository = ProtectedPdfRepository(
        base.replace(
          path: '/functions/v1/pdf-content',
          query: null,
          fragment: null,
        ),
        client,
      );
      final bytes = await repository.load(widget.lessonId, widget.bearer);
      if (!mounted || generation != _generation) {
        return;
      }
      if (bytes == null) {
        setState(() {
          _loading = false;
          _error = 'Your personalized PDF is preparing. Please retry shortly.';
        });
        return;
      }
      final lease = PdfDocumentLease<pdfx.PdfDocument>(
        pdfx.PdfDocument.openData(bytes),
        (document) => document.close(),
      );
      _document = lease;
      final opened = await lease.document;
      if (!mounted || generation != _generation) {
        await lease.release();
        return;
      }
      _controller = pdfx.PdfController(document: Future.value(opened));
      setState(() => _loading = false);
    } catch (error) {
      if (!mounted || generation != _generation) {
        return;
      }
      setState(() {
        _loading = false;
        _error = error is ProtectedPdfFailure
            ? error.message
            : 'PDF delivery could not be confirmed. Please retry.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const PdfLoadingState();
    }
    if (_error != null) {
      return PdfErrorState(errorMessage: _error!, onRetry: _load);
    }
    final controller = _controller;
    final generation = _generation;
    if (controller == null) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        Expanded(
          child: InteractiveViewer(
            transformationController: _zoomController,
            minScale: _minZoom,
            maxScale: _maxZoom,
            panEnabled: _zoom > _minZoom,
            scaleEnabled: false,
            child: pdfx.PdfView(
              controller: controller,
              onDocumentLoaded: (document) {
                if (mounted &&
                    generation == _generation &&
                    _controller == controller) {
                  setState(() {
                    _pages = document.pagesCount;
                    _page = 1;
                  });
                  final saved = PdfProgressLocal.loadPage(widget.lessonId);
                  if (saved != null &&
                      saved > 1 &&
                      saved <= document.pagesCount) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted &&
                          generation == _generation &&
                          _controller == controller) {
                        controller.jumpToPage(saved);
                        setState(() => _page = saved);
                      }
                    });
                  }
                }
              },
              onPageChanged: (page) {
                if (mounted &&
                    generation == _generation &&
                    _controller == controller) {
                  setState(() => _page = page);
                  PdfProgressLocal.savePage(widget.lessonId, page);
                }
              },
              onDocumentError: (_) {
                if (mounted &&
                    generation == _generation &&
                    _controller == controller) {
                  setState(
                    () => _error =
                        'This PDF could not be rendered. Please retry.',
                  );
                }
              },
            ),
          ),
        ),
        const PdfWatermarkDisclosure(),
        PdfReaderFooter(
          currentPage: _page,
          totalPages: _pages,
          zoom: _zoom,
          isFitWidth: _zoom == _minZoom,
          onPrevious: _page > 1 ? () => controller.jumpToPage(_page - 1) : null,
          onNext: _page < _pages
              ? () => controller.jumpToPage(_page + 1)
              : null,
          onZoomIn: _zoom < _maxZoom ? () => _setZoom(_zoom + 0.25) : null,
          onZoomOut: _zoom > _minZoom ? () => _setZoom(_zoom - 0.25) : null,
          onFitWidth: () => _setZoom(_minZoom),
        ),
      ],
    );
  }
}
