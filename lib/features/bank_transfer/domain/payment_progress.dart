import 'package:acendra/features/bank_transfer/domain/entities/receipt_submission.dart';

enum ProgressState { done, current, failed, todo }

class ProgressStep {
  const ProgressStep(this.title, this.description, this.state);
  final String title;
  final String description;
  final ProgressState state;
}

/// Maps the backend receipt status to the four-step bank payment timeline.
/// Display only: the status itself always comes from the trusted backend.
List<ProgressStep> paymentProgressSteps(ReceiptStatus status) {
  const created = 'Order Created';
  const receipt = 'Receipt Submitted';
  const verify = 'Bank Verification';
  const enrol = 'Enrollment Activated';
  const createdText = 'Your order has been created.';
  const verifyText = 'Our team checks the transfer reached our account.';
  const enrolText = 'Your course opens after verification.';

  return switch (status) {
    ReceiptStatus.awaitingReceipt => const [
      ProgressStep(created, createdText, ProgressState.done),
      ProgressStep(
        receipt,
        'Upload your transfer receipt.',
        ProgressState.current,
      ),
      ProgressStep(verify, verifyText, ProgressState.todo),
      ProgressStep(enrol, enrolText, ProgressState.todo),
    ],
    ReceiptStatus.submitted || ReceiptStatus.underReview => const [
      ProgressStep(created, createdText, ProgressState.done),
      ProgressStep(
        receipt,
        'Your payment receipt has been uploaded.',
        ProgressState.done,
      ),
      ProgressStep(verify, verifyText, ProgressState.current),
      ProgressStep(enrol, enrolText, ProgressState.todo),
    ],
    ReceiptStatus.approved => const [
      ProgressStep(created, createdText, ProgressState.done),
      ProgressStep(
        receipt,
        'Your payment receipt has been uploaded.',
        ProgressState.done,
      ),
      ProgressStep(
        verify,
        'Your transfer has been verified.',
        ProgressState.done,
      ),
      ProgressStep(enrol, 'Your course access is active.', ProgressState.done),
    ],
    ReceiptStatus.rejected => const [
      ProgressStep(created, createdText, ProgressState.done),
      ProgressStep(
        receipt,
        'Your payment receipt has been uploaded.',
        ProgressState.done,
      ),
      ProgressStep(
        verify,
        'The receipt could not be verified. Submit a new one.',
        ProgressState.failed,
      ),
      ProgressStep(enrol, enrolText, ProgressState.todo),
    ],
  };
}
