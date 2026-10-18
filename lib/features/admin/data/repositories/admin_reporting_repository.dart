import 'package:acendra/features/admin/data/repositories/admin_directory_client.dart';
import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Reporting is not activated, or the caller's role does not receive the metric.
/// Absence never means zero.
class ReportingUnavailable implements Exception {
  const ReportingUnavailable();
}

/// Gross confirmed settlement receipts for the trailing 30 days (CSA-158/172).
///
/// Refund and net figures are deliberately not modelled: the backend has no
/// confirmed adjustment ledger, so they are unavailable rather than zero.
class ConfirmedReceipts {
  const ConfirmedReceipts({
    required this.grossReceiptsMinor,
    required this.currency,
  });

  /// Exact minor units (bigint-safe); never converted through a double.
  final BigInt grossReceiptsMinor;
  final String currency;

  bool get refundsAvailable => false;
  bool get netAvailable => false;

  String get formattedGross {
    final major = (grossReceiptsMinor ~/ BigInt.from(100)).toString();
    final cents = (grossReceiptsMinor % BigInt.from(100)).toString().padLeft(
      2,
      '0',
    );
    final grouped = major.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    return '$currency $grouped.$cents';
  }
}

abstract interface class AdminReportingRepository {
  Future<ConfirmedReceipts> confirmedReceipts();
}

/// Default until reporting activation is reviewed and released.
class UnavailableAdminReportingRepository implements AdminReportingRepository {
  const UnavailableAdminReportingRepository();

  @override
  Future<ConfirmedReceipts> confirmedReceipts() async =>
      throw const ReportingUnavailable();
}

class SupabaseAdminReportingRepository implements AdminReportingRepository {
  SupabaseAdminReportingRepository(SupabaseClient client)
    : _directory = AdminDirectoryClient(client);
  final AdminDirectoryClient _directory;

  static const _invalid = AdminDataException(
    'Reporting data is unavailable. Retry or contact your administrator.',
  );
  static final _minorUnits = RegExp(r'^\d{1,30}$');
  static const _noLedger = 'confirmed_adjustment_ledger_unavailable';

  @override
  Future<ConfirmedReceipts> confirmedReceipts() async {
    final data = await _directory.invoke('admin-dashboard-stats', {
      'period': 'last_30_days',
    });
    final raw = data['confirmed_receipts'];
    // Omitted for roles without finance authority: unavailable, not zero.
    if (raw == null) throw const ReportingUnavailable();
    if (raw is! Map) throw _invalid;

    final gross = raw['gross_receipts_minor'];
    final confirmed = raw['confirmed_amount_minor'];
    if (gross is! String ||
        !_minorUnits.hasMatch(gross) ||
        confirmed != gross ||
        raw['currency_code'] != 'LKR' ||
        raw['basis'] != 'verified_settlement_receipts' ||
        raw['recognition_status'] != 'approved' ||
        raw['refunds_status'] != _noLedger ||
        raw['net_status'] != _noLedger) {
      throw _invalid;
    }
    return ConfirmedReceipts(
      grossReceiptsMinor: BigInt.parse(gross),
      currency: 'LKR',
    );
  }
}

/// Wired to the `admin-dashboard-stats` function. While that endpoint is
/// disabled it answers 503, which surfaces as unavailable on the dashboard.
final adminReportingRepositoryProvider = Provider<AdminReportingRepository>((
  ref,
) {
  final session = ref.watch(currentSessionProvider);
  if (session == null) {
    throw const AdminDataException('Your session expired. Sign in again.');
  }
  return SupabaseAdminReportingRepository(Supabase.instance.client);
});
