import 'protected_pdf_repository.dart';

PdfTransport createPdfTransport() => _UnavailableTransport();

class _UnavailableTransport implements PdfTransport {
  @override
  Future<PdfTransportResponse> get(Uri url, String bearer) async =>
      throw const ProtectedPdfFailure(
        'Protected PDF delivery requires a web browser.',
      );
  @override
  void cancel() {}
}
