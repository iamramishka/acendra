import 'dart:convert';
import 'dart:async';
import 'package:acendra/core/config/env_config.dart';
import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/pdf_reader/data/protected_pdf_repository.dart';
import 'package:acendra/features/pdf_reader/data/pdf_document_lease.dart';
import 'package:acendra/features/pdf_reader/data/pdf_reading_store.dart';
import 'package:acendra/features/pdf_reader/data/pdf_outline.dart'
    if (dart.library.js_interop) 'package:acendra/features/pdf_reader/data/pdf_outline_web.dart'
    as outline;
import 'package:acendra/features/pdf_reader/data/pdf_transport.dart'
    if (dart.library.js_interop) 'package:acendra/features/pdf_reader/data/pdf_transport_web.dart'
    as transport;
import 'package:acendra/features/pdf_reader/domain/entities/pdf_outline_entry.dart';
import 'package:acendra/features/pdf_reader/presentation/widgets/pdf_error_state.dart';
import 'package:acendra/features/pdf_reader/presentation/widgets/pdf_loading_state.dart';
import 'package:acendra/features/pdf_reader/presentation/widgets/pdf_lesson_reader.dart';
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
  const ProtectedPdfLesson({
    super.key,
    required this.lessonId,
    this.title = 'PDF guide',
  });
  final String lessonId, title;
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
      userId: session.user.id,
      bearer: session.accessToken,
      title: title,
    );
  }
}

class _AuthenticatedPdf extends StatefulWidget {
  const _AuthenticatedPdf({
    super.key,
    required this.lessonId,
    required this.userId,
    required this.bearer,
    required this.title,
  });
  final String lessonId, userId, bearer, title;
  @override
  State<_AuthenticatedPdf> createState() => _AuthenticatedPdfState();
}

class _AuthenticatedPdfState extends State<_AuthenticatedPdf> {
  PdfTransport? _transport;
  PdfDocumentLease<pdfx.PdfDocument>? _lease;
  pdfx.PdfDocument? _document;
  List<PdfOutlineEntry> _entries = [];
  String? _error;
  bool _loading = true, _watermarked = false, _outlineUnavailable = false;
  int _generation = 0;

  void _release() {
    _document = null;
    final lease = _lease;
    _lease = null;
    if (lease != null) {
      unawaited(
        lease.release().catchError((Object _) {
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
    _release();
    super.dispose();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    _transport?.cancel();
    _release();
    setState(() {
      _loading = true;
      _error = null;
      _watermarked = false;
      _entries = [];
      _outlineUnavailable = false;
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
      final data = await repository.loadDocument(
        widget.lessonId,
        widget.bearer,
      );
      if (!mounted || generation != _generation) return;
      if (data == null) {
        throw const ProtectedPdfFailure(
          'Your personalized PDF is preparing. Please retry shortly.',
        );
      }
      List<PdfOutlineEntry> entries;
      var unavailable = false;
      try {
        entries = await outline.loadPdfOutline(data.bytes);
      } catch (_) {
        entries = [];
        unavailable = true;
      }
      if (!mounted || generation != _generation) return;
      final lease = PdfDocumentLease<pdfx.PdfDocument>(
        pdfx.PdfDocument.openData(data.bytes),
        (document) => document.close(),
      );
      _lease = lease;
      final opened = await lease.document;
      if (!mounted || generation != _generation) {
        await lease.release();
        return;
      }
      if (opened.pagesCount < 1 || opened.pagesCount > 500) {
        throw const ProtectedPdfFailure(
          'This PDF exceeds the supported page limit.',
        );
      }
      setState(() {
        _document = opened;
        _entries = entries;
        _watermarked = data.watermarkApplied;
        _outlineUnavailable = unavailable;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || generation != _generation) return;
      _release();
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
    if (_loading) return const PdfLoadingState();
    if (_error != null) {
      return PdfErrorState(errorMessage: _error!, onRetry: _load);
    }
    final document = _document;
    if (document == null) return const SizedBox.shrink();
    return PdfLessonReader(
      key: ValueKey(document.id),
      document: document,
      store: PdfReadingStore(userId: widget.userId, lessonId: widget.lessonId),
      title: widget.title,
      outline: _entries,
      watermarkApplied: _watermarked,
      outlineUnavailable: _outlineUnavailable,
    );
  }
}
