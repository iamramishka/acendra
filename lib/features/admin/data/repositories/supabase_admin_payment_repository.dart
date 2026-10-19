import 'package:acendra/features/admin/data/repositories/admin_directory_client.dart';
import 'package:acendra/features/admin/data/repositories/admin_payment_repository.dart';
import 'package:acendra/features/admin/domain/entities/payment_record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Session-scoped adapter. Cursors stay opaque and are never converted through
/// DateTime, which would discard the backend's microsecond keyset position.
class SupabaseAdminPaymentRepository implements AdminPaymentRepository {
  SupabaseAdminPaymentRepository(SupabaseClient client)
    : _client = AdminDirectoryClient(client);

  final AdminDirectoryClient _client;
  final _cursors = <String, Map<int, String?>>{};
  bool hasMore({
    PaymentStatus? status,
    PaymentMethod? method,
    String? searchQuery,
    DateTime? fromDate,
    DateTime? toDate,
    required int page,
    int pageSize = 20,
  }) {
    final filters = _filters(
      status: status,
      method: method,
      searchQuery: searchQuery,
      fromDate: fromDate,
      toDate: toDate,
    );
    final key = [pageSize, ...filters.values].join('|');
    return _cursors[key]?[page + 1] != null;
  }

  static const _invalid = AdminDataException(
    'Payment reporting is unavailable. Refresh or contact your administrator.',
  );
  static final _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );
  static final _decimal = RegExp(r'^(0|[1-9][0-9]{0,18})$');
  static final _timestamp = RegExp(
    r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{6}Z$',
  );
  static final _maxAmount = BigInt.parse('9223372036854775807');
  static final _maxCount = BigInt.parse('9007199254740991');

  BigInt _integer(dynamic value, BigInt maximum) {
    if (value is! String || !_decimal.hasMatch(value)) throw _invalid;
    final parsed = BigInt.parse(value);
    if (parsed > maximum) throw _invalid;
    return parsed;
  }

  DateTime _date(dynamic value) {
    if (value is! String || !_timestamp.hasMatch(value)) throw _invalid;
    final parsed = DateTime.tryParse(value);
    if (parsed == null) throw _invalid;
    return parsed;
  }

  PaymentRecord _record(dynamic raw) {
    if (raw is! Map) throw _invalid;
    for (final key in ['payment_id', 'order_id', 'course_id']) {
      if (raw[key] is! String || !_uuid.hasMatch(raw[key] as String)) {
        throw _invalid;
      }
    }
    if (raw['payment_id'] != raw['order_id'] || raw['currency_code'] != 'LKR') {
      throw _invalid;
    }
    final number = raw['order_number'];
    final title = raw['course_title'];
    if (number is! String ||
        number.trim().isEmpty ||
        number.length > 100 ||
        title is! String ||
        title.trim().isEmpty ||
        title.length > 200) {
      throw _invalid;
    }
    final amount = _integer(raw['amount_minor'], _maxAmount);
    final status = switch (raw['status']) {
      'pending' => PaymentStatus.pending,
      'processing' => PaymentStatus.processing,
      'approved' => PaymentStatus.approved,
      'rejected' => PaymentStatus.rejected,
      _ => throw _invalid,
    };
    final method = switch (raw['method']) {
      'online' => PaymentMethod.online,
      'bank_transfer' => PaymentMethod.bankTransfer,
      _ => throw _invalid,
    };
    final created = _date(raw['created_at']);
    _date(raw['updated_at']);
    final settled = raw['settled_at'];
    if (status != PaymentStatus.approved && settled != null) throw _invalid;
    return PaymentRecord(
      id: raw['payment_id'] as String,
      orderId: raw['order_id'] as String,
      orderNumber: number,
      studentId: '',
      studentEmail: '',
      courseId: raw['course_id'] as String,
      courseTitle: title,
      amountMinor: amount,
      amount: amount.toDouble() / 100,
      currency: 'LKR',
      paymentMethod: method,
      status: status,
      createdAt: created,
      processedAt: status == PaymentStatus.approved ? _date(settled) : null,
    );
  }

  Map<PaymentStatus, int> _counts(dynamic raw) {
    if (raw is! Map) throw _invalid;
    final counts = {
      for (final status in PaymentStatus.values)
        status: _integer(raw[status.name], _maxCount).toInt(),
    };
    final total = _integer(raw['total'], _maxCount);
    if (counts.values.fold(
          BigInt.zero,
          (sum, value) => sum + BigInt.from(value),
        ) !=
        total) {
      throw _invalid;
    }
    return counts;
  }

  Map<String, dynamic> _filters({
    PaymentStatus? status,
    PaymentMethod? method,
    String? searchQuery,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    final prefix = searchQuery?.trim();
    if (prefix != null &&
        prefix.isNotEmpty &&
        !RegExp(r'^[A-Za-z0-9-]{1,40}$').hasMatch(prefix)) {
      throw const AdminDataException(
        'Search by an order-number prefix (letters, numbers or hyphens).',
      );
    }
    if (method == PaymentMethod.adminGrant) {
      throw const AdminDataException('Administrative grants are not payments.');
    }
    String? day(DateTime? value) => value == null
        ? null
        : '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
    final from = day(fromDate), to = day(toDate);
    if ((from == null) != (to == null) ||
        (from != null &&
            (to!.compareTo(from) < 0 ||
                DateTime.parse(to).difference(DateTime.parse(from)).inDays >
                    365))) {
      throw _invalid;
    }
    return {
      'status': status?.name,
      'method': method == null
          ? null
          : method == PaymentMethod.online
          ? 'online'
          : 'bank_transfer',
      'from': from,
      'to': to,
      'order_number_prefix': prefix == null || prefix.isEmpty ? null : prefix,
    };
  }

  Future<Map<String, dynamic>> _page(
    Map<String, dynamic> filters,
    int size,
    String? cursor,
  ) async {
    final data = await _client.invoke('admin-payment-list', {
      'mode': 'list',
      'page_size': size,
      'cursor': cursor,
      ...filters,
    });
    if (data['items'] is! List ||
        (data['items'] as List).length > size ||
        data['count_basis'] != 'current_snapshot') {
      throw _invalid;
    }
    _date(data['as_of']);
    _date(data['count_as_of']);
    if ((data['count_as_of'] as String).compareTo(data['as_of'] as String) <
        0) {
      throw _invalid;
    }
    final next = data['next_cursor'];
    if (next != null &&
        (next is! String ||
            next.isEmpty ||
            next.length > 512 ||
            next == cursor ||
            (data['items'] as List).length != size)) {
      throw _invalid;
    }
    _counts(data['counts']);
    for (final raw in data['items'] as List) {
      _record(raw);
    }
    return data;
  }

  @override
  Future<List<PaymentRecord>> listPayments({
    PaymentStatus? status,
    PaymentMethod? method,
    String? searchQuery,
    DateTime? fromDate,
    DateTime? toDate,
    int page = 0,
    int pageSize = 20,
  }) async {
    if (page < 0 || pageSize < 1 || pageSize > 100) throw _invalid;
    final filters = _filters(
      status: status,
      method: method,
      searchQuery: searchQuery,
      fromDate: fromDate,
      toDate: toDate,
    );
    final key = [pageSize, ...filters.values].join('|');
    final positions = page == 0 ? <int, String?>{0: null} : _cursors[key];
    if (positions == null || !positions.containsKey(page)) throw _invalid;
    if (page == 0) _cursors[key] = positions;
    if (page > 0 && positions[page] == null) return [];
    var cursor = positions[page];
    final records = <PaymentRecord>[];
    do {
      final remaining = pageSize - records.length;
      final data = await _page(
        filters,
        remaining > 50 ? 50 : remaining,
        cursor,
      );
      records.addAll((data['items'] as List).map(_record));
      cursor = data['next_cursor'] as String?;
    } while (cursor != null && records.length < pageSize);
    positions[page + 1] = cursor;
    // An older request only updates its own map if a refresh replaced the chain.
    return records;
  }

  @override
  Future<PaymentRecord> getPayment(String paymentId) async {
    if (!_uuid.hasMatch(paymentId)) throw _invalid;
    final data = await _client.invoke('admin-payment-list', {
      'mode': 'detail',
      'payment_id': paymentId,
    });
    _date(data['as_of']);
    final record = _record(data['item']);
    if (record.id != paymentId) throw _invalid;
    return record;
  }

  @override
  Future<Map<PaymentStatus, int>> countAllStatuses() async =>
      _counts((await _page(_filters(), 1, null))['counts']);

  @override
  Future<int> countPayments({
    PaymentStatus? status,
    PaymentMethod? method,
  }) async {
    final counts = _counts(
      (await _page(_filters(method: method), 1, null))['counts'],
    );
    return status == null
        ? counts.values.fold<int>(0, (sum, value) => sum + value)
        : counts[status]!;
  }
}
