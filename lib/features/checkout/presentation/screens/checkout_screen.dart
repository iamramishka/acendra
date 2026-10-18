import 'package:acendra/app/router/route_names.dart';
import 'package:go_router/go_router.dart';
import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:acendra/core/widgets/feedback/app_skeleton.dart';
import 'package:acendra/core/widgets/feedback/app_state_views.dart';
import 'package:acendra/core/widgets/inputs/app_text_field.dart';
import 'package:acendra/core/widgets/layout/responsive_container.dart';
import 'package:acendra/features/checkout/domain/entities/checkout_order.dart';
import 'package:acendra/features/checkout/domain/entities/payment_method.dart';
import 'package:acendra/features/checkout/domain/entities/customer_info.dart';
import 'package:acendra/features/checkout/domain/entities/payment_handoff.dart';
import 'package:acendra/features/checkout/data/repositories/checkout_submission_repository.dart';
import 'package:acendra/features/checkout/data/repositories/student_order_repository.dart';
import 'package:acendra/features/marketplace/presentation/providers/marketplace_provider.dart';
import 'package:acendra/features/marketplace/presentation/widgets/course_art.dart';
import 'package:acendra/features/checkout/presentation/providers/payment_launcher_provider.dart';
import 'package:acendra/features/checkout/presentation/providers/checkout_actor_provider.dart';
import 'package:acendra/features/checkout/presentation/providers/checkout_provider.dart';
import 'package:acendra/features/checkout/presentation/widgets/payment_method_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key, required this.courseId});

  final String courseId;

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();

  // Validation error strings
  String? _firstNameError;
  String? _lastNameError;
  String? _phoneError;
  String? _addressError;
  String? _cityError;
  String? _countryError;
  bool _isPaying = false;
  bool _isCreating = false;
  String? _paymentKey;
  String? _paymentOrderId;
  int _identityEpoch = 0;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  bool _validate() {
    bool valid = true;

    setState(() {
      _firstNameError = _firstNameController.text.trim().isEmpty
          ? 'Required'
          : null;
      _lastNameError = _lastNameController.text.trim().isEmpty
          ? 'Required'
          : null;
      _phoneError = _phoneController.text.trim().length < 7
          ? 'Enter a valid phone number'
          : null;
      _addressError = _addressController.text.trim().isEmpty
          ? 'Required'
          : null;
      _cityError = _cityController.text.trim().isEmpty ? 'Required' : null;
      _countryError = _countryController.text.trim().isEmpty
          ? 'Required'
          : null;

      if (_firstNameError != null ||
          _lastNameError != null ||
          _phoneError != null ||
          _addressError != null ||
          _cityError != null ||
          _countryError != null) {
        valid = false;
      }
    });

    return valid;
  }

  Future<void> _onProceed(PaymentMethod method) async {
    if (_isCreating || (method == PaymentMethod.online && !_validate())) return;
    final actor = ref.read(checkoutActorProvider);
    final epoch = _identityEpoch;
    setState(() => _isCreating = true);
    try {
      final existing = await ref.refresh(
        openCourseOrderProvider(widget.courseId).future,
      );
      if (!mounted ||
          epoch != _identityEpoch ||
          actor != ref.read(checkoutActorProvider)) {
        return;
      }
      if (existing != null) {
        if (existing.method == 'online' &&
            existing.status == 'pending_payment') {
          await ref
              .read(checkoutProvider.notifier)
              .resumeOnlineOrder(
                courseId: widget.courseId,
                orderId: existing.id,
              );
          return;
        }
        context.push(
          RouteNames.orderStatus.replaceFirst(':orderId', existing.id),
        );
        return;
      }
      await ref
          .read(checkoutProvider.notifier)
          .createOrder(courseId: widget.courseId, method: method);
      if (!mounted ||
          epoch != _identityEpoch ||
          actor != ref.read(checkoutActorProvider)) {
        return;
      }
      final order = ref.read(checkoutProvider).asData?.value;
      ref.invalidate(openCourseOrderProvider(widget.courseId));
      if (order == null || order.courseId != widget.courseId) return;
      if (method == PaymentMethod.online) {
        await _onPayNow();
      } else {
        context.push(
          RouteNames.bankTransfer.replaceFirst(':orderId', order.orderId),
        );
      }
    } catch (_) {
      if (mounted && epoch == _identityEpoch) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Payment status could not be checked. Please retry before starting another order.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _onPayNow() async {
    if (_isPaying || !_validate()) return;
    final actor = ref.read(checkoutActorProvider);
    if (actor == null) return;
    final epoch = _identityEpoch;
    final order = ref.read(checkoutProvider).value;
    if (order == null ||
        order.courseId != widget.courseId ||
        order.paymentMethod != PaymentMethod.online ||
        order.status != 'pending_payment') {
      return;
    }
    if (_paymentOrderId != order.orderId) {
      _paymentOrderId = order.orderId;
      _paymentKey = 'online-${DateTime.now().microsecondsSinceEpoch}';
    }
    setState(() => _isPaying = true);
    try {
      final payment = await ref
          .read(checkoutSubmissionRepositoryProvider)
          .initialize(
            orderId: order.orderId,
            amountMinor: order.amountMinor,
            key: _paymentKey!,
            customer: CustomerInfo(
              firstName: _firstNameController.text,
              lastName: _lastNameController.text,
              phone: _phoneController.text,
              address: _addressController.text,
              city: _cityController.text,
              country: _countryController.text,
            ),
          );
      if (!mounted ||
          epoch != _identityEpoch ||
          ref.read(checkoutActorProvider) != actor ||
          ref.read(checkoutProvider).value?.orderId != order.orderId) {
        return;
      }
      await ref.read(paymentLauncherProvider)(payment);
    } catch (error) {
      if (!mounted ||
          epoch != _identityEpoch ||
          ref.read(checkoutActorProvider) != actor ||
          ref.read(checkoutProvider).value?.orderId != order.orderId) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is CheckoutFlowException
                ? error.message
                : 'Online payment could not be started. Please retry.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isPaying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(checkoutActorProvider, (previous, next) {
      if (previous == next) return;
      _identityEpoch++;
      setState(() {
        _paymentKey = null;
        _paymentOrderId = null;
      });
    });
    final checkoutState = ref.watch(checkoutProvider);
    final selectedMethod = ref.watch(selectedPaymentMethodProvider);
    final order = checkoutState.asData?.value;
    if (order != null && order.courseId != widget.courseId) {
      return Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => ref.read(checkoutProvider.notifier).reset(),
            child: const Text('Load this course checkout'),
          ),
        ),
      );
    }
    final course = order == null
        ? ref.watch(courseDetailProvider(widget.courseId))
        : null;
    final existing = order == null
        ? ref.watch(openCourseOrderProvider(widget.courseId))
        : null;
    final waiting =
        checkoutState.isLoading ||
        _isCreating ||
        _isPaying ||
        (order == null &&
            (course?.isLoading == true || existing?.isLoading == true));
    final blocked =
        order == null &&
        (course?.hasError == true || existing?.hasError == true);
    final openOrder = existing?.asData?.value;
    final canResume =
        openOrder?.method == 'online' && openOrder?.status == 'pending_payment';
    void back() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(
          RouteNames.courseDetail.replaceFirst(':courseId', widget.courseId),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Checkout'),
        leading: BackButton(onPressed: back),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Total Amount',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              Text(
                order?.formattedAmount ??
                    course?.asData?.value.formattedPrice ??
                    'Unavailable',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              AppButton(
                label: canResume
                    ? 'Resume Payment'
                    : openOrder != null
                    ? 'Payment Status'
                    : order != null &&
                          order.paymentMethod == PaymentMethod.online
                    ? 'Pay Now'
                    : selectedMethod == PaymentMethod.online
                    ? 'Continue to PayHere'
                    : 'Continue to Bank Transfer',
                isLoading: waiting,
                onPressed: waiting || blocked
                    ? null
                    : () {
                        if (canResume) {
                          ref
                              .read(checkoutProvider.notifier)
                              .resumeOnlineOrder(
                                courseId: widget.courseId,
                                orderId: openOrder!.id,
                              );
                        } else if (openOrder != null) {
                          context.push(
                            RouteNames.orderStatus.replaceFirst(
                              ':orderId',
                              openOrder.id,
                            ),
                          );
                        } else if (order == null) {
                          _onProceed(selectedMethod);
                        } else if (order.courseId != widget.courseId) {
                          ref.read(checkoutProvider.notifier).reset();
                        } else if (order.paymentMethod ==
                            PaymentMethod.online) {
                          _onPayNow();
                        } else {
                          context.push(
                            RouteNames.bankTransfer.replaceFirst(
                              ':orderId',
                              order.orderId,
                            ),
                          );
                        }
                      },
              ),
              if (blocked)
                TextButton(
                  onPressed: () {
                    ref.invalidate(courseDetailProvider(widget.courseId));
                    ref.invalidate(openCourseOrderProvider(widget.courseId));
                  },
                  child: const Text('Retry checkout details'),
                ),
            ],
          ),
        ),
      ),
      body: checkoutState.when(
        loading: () => _buildLoadingBody(),
        error: (err, _) => AppErrorState(
          message: 'Something went wrong. Please try again.',
          actionLabel: 'Retry',
          onRetry: () => ref.read(checkoutProvider.notifier).reset(),
        ),
        data: (order) => _buildBody(context, order, selectedMethod),
      ),
    );
  }

  Widget _buildLoadingBody() {
    return const ResponsiveContainer(
      maxWidth: 600,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSkeleton(width: double.infinity, height: 120),
            SizedBox(height: AppSpacing.lg),
            AppSkeleton(width: double.infinity, height: 100),
            SizedBox(height: AppSpacing.lg),
            AppSkeleton(width: double.infinity, height: 200),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    CheckoutOrder? order,
    PaymentMethod selectedMethod,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ResponsiveContainer(
      maxWidth: 600,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Wrap(
              alignment: WrapAlignment.spaceAround,
              spacing: 16,
              runSpacing: 8,
              children: [Text('✓ Order'), Text('2 Payment'), Text('3 Confirm')],
            ),
            const SizedBox(height: 24),
            Text(
              'Complete Your Purchase',
              style: theme.textTheme.headlineMedium,
            ),
            const Text('Choose how you would like to pay.'),
            const SizedBox(height: 20),
            // ── Section 1: Order Summary ──────────────────────────────────────
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Summary',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (order != null) ...[
                    Text(order.courseTitle, style: theme.textTheme.bodyLarge),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      order.formattedAmount,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _StatusBadge(status: order.status),
                  ] else ...[
                    ref
                        .watch(courseDetailProvider(widget.courseId))
                        .when(
                          loading: () => const CircularProgressIndicator(),
                          error: (_, _) => const Text(
                            'Course details are unavailable. Retry below.',
                          ),
                          data: (course) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const CourseArt(height: 100),
                              const SizedBox(height: 12),
                              Text(
                                course.title,
                                style: theme.textTheme.titleLarge,
                              ),
                              Text(
                                '${course.totalLessons} lessons · Online Course',
                              ),
                              Text(
                                course.formattedPrice,
                                style: theme.textTheme.headlineSmall,
                              ),
                            ],
                          ),
                        ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Section 2: Payment Method ─────────────────────────────────────
            if (order == null) ...[
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Method',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    PaymentMethodSelector(
                      selected: selectedMethod,
                      onChanged: (method) {
                        ref.read(selectedPaymentMethodProvider.notifier).state =
                            method;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),
            ],
            _SectionCard(
              child: Text(
                selectedMethod == PaymentMethod.online
                    ? 'Continue to PayHere to pay securely. Your card details are entered on PayHere, not in Acedra. Course access starts after payment is verified.'
                    : 'Continue to bank transfer for our bank details and your order reference. Submit your receipt for review; access starts only after verification.',
              ),
            ),
            const SizedBox(height: 20),

            // Keep contact inputs available for an existing pending online
            // order: Pay Now validates and submits these actual controller values.
            if ((order == null && selectedMethod == PaymentMethod.online) ||
                order?.paymentMethod == PaymentMethod.online) ...[
              // ── Section 3: Customer Info form ─────────────────────────────────
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Billing Details',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // First Name + Last Name row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: 'First Name',
                            hint: 'John',
                            controller: _firstNameController,
                            errorText: _firstNameError,
                            onChanged: (_) {
                              if (_firstNameError != null) {
                                setState(() => _firstNameError = null);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: AppTextField(
                            label: 'Last Name',
                            hint: 'Doe',
                            controller: _lastNameController,
                            errorText: _lastNameError,
                            onChanged: (_) {
                              if (_lastNameError != null) {
                                setState(() => _lastNameError = null);
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.md),

                    AppTextField(
                      label: 'Phone',
                      hint: '+94 77 123 4567',
                      controller: _phoneController,
                      errorText: _phoneError,
                      keyboardType: TextInputType.phone,
                      onChanged: (_) {
                        if (_phoneError != null) {
                          setState(() => _phoneError = null);
                        }
                      },
                    ),

                    const SizedBox(height: AppSpacing.md),

                    AppTextField(
                      label: 'Address',
                      hint: '123 Main Street',
                      controller: _addressController,
                      errorText: _addressError,
                      onChanged: (_) {
                        if (_addressError != null) {
                          setState(() => _addressError = null);
                        }
                      },
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // City + Country row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: 'City',
                            hint: 'Colombo',
                            controller: _cityController,
                            errorText: _cityError,
                            onChanged: (_) {
                              if (_cityError != null) {
                                setState(() => _cityError = null);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: AppTextField(
                            label: 'Country',
                            hint: 'Sri Lanka',
                            controller: _countryController,
                            errorText: _countryError,
                            onChanged: (_) {
                              if (_countryError != null) {
                                setState(() => _countryError = null);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            // ── Section 4: Bank Instructions ──────────────────────────────────
            if (order != null &&
                order.paymentMethod == PaymentMethod.bankTransfer &&
                order.bankInstructions != null) ...[
              const SizedBox(height: AppSpacing.lg),
              _BankInstructionsCard(instructions: order.bankInstructions!),
            ],

            const SizedBox(height: AppSpacing.xl),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: child,
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = status.replaceAll('_', ' ').toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: cs.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _BankInstructionsCard extends StatelessWidget {
  const _BankInstructionsCard({required this.instructions});

  final BankInstructions instructions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_outlined, color: cs.primary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Bank Transfer Instructions',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _BankInfoRow(label: 'Bank', value: instructions.bankName),
          _BankInfoRow(
            label: 'Account Holder',
            value: instructions.accountHolder,
          ),
          _BankInfoRow(
            label: 'Account Number',
            value: instructions.accountNumber,
          ),
          _BankInfoRow(label: 'Branch', value: instructions.branch),
          _BankInfoRow(label: 'Currency', value: instructions.currency),
        ],
      ),
    );
  }
}

class _BankInfoRow extends StatelessWidget {
  const _BankInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
