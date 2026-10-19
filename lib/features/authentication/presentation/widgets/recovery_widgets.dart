import 'package:flutter/material.dart';

class RecoveryHero extends StatelessWidget {
  const RecoveryHero({super.key, required this.icon, required this.badge});
  final IconData icon;
  final IconData badge;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 220,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [cs.primaryContainer, cs.surface]),
        borderRadius: BorderRadius.circular(24),
      ),
      alignment: Alignment.center,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(icon, size: 56, color: cs.onPrimary),
          ),
          Positioned(
            right: -12,
            top: -12,
            child: CircleAvatar(
              radius: 24,
              backgroundColor: cs.tertiaryContainer,
              child: Icon(badge, color: cs.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

class RecoveryInfo extends StatelessWidget {
  const RecoveryInfo(this.message, {super.key});
  final String message;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(message)),
      ],
    ),
  );
}
