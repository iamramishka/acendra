import 'dart:convert';
import 'package:acendra/core/config/env_config.dart';
import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/pdf_reader/data/protected_pdf_repository.dart';
import 'package:acendra/features/pdf_reader/data/pdf_transport.dart'
    if (dart.library.js_interop) 'package:acendra/features/pdf_reader/data/pdf_transport_web.dart'
    as transport;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart' as pdfx;

String? pdfSessionIdentity(String? token) {
  if (token == null) return null;
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
    if (session == null)
      return const Center(child: Text('Sign in to access this PDF.'));
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
  String? _message;
  bool _loading = true;
  int _page = 1, _pages = 1;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _generation++;
    _transport?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    _transport?.cancel();
    _controller?.dispose();
    _controller = null;
    setState(() {
      _loading = true;
      _message = null;
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
      if (!mounted || generation != _generation) return;
      if (bytes == null) {
        setState(() {
          _loading = false;
          _message =
              'Your personalized PDF is preparing. Please retry shortly.';
        });
        return;
      }
      _controller = pdfx.PdfController(
        document: pdfx.PdfDocument.openData(bytes),
      );
      setState(() => _loading = false);
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _loading = false;
        _message = error is ProtectedPdfFailure
            ? error.message
            : 'PDF delivery could not be confirmed. Please retry.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_message != null)
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_message!),
            TextButton(onPressed: _load, child: const Text('Retry PDF')),
          ],
        ),
      );
    final controller = _controller;
    if (controller == null) return const SizedBox.shrink();
    return Column(
      children: [
        Expanded(
          child: pdfx.PdfView(
            controller: controller,
            onDocumentLoaded: (document) {
              if (mounted)
                setState(() {
                  _pages = document.pagesCount;
                  _page = 1;
                });
            },
            onPageChanged: (page) {
              if (mounted) setState(() => _page = page);
            },
            onDocumentError: (_) {
              if (mounted)
                setState(
                  () => _message =
                      'This PDF could not be rendered. Please retry.',
                );
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: 'Previous PDF page',
              onPressed: _page > 1
                  ? () => controller.jumpToPage(_page - 1)
                  : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Text('$_page / $_pages'),
            IconButton(
              tooltip: 'Next PDF page',
              onPressed: _page < _pages
                  ? () => controller.jumpToPage(_page + 1)
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ],
    );
  }
}
