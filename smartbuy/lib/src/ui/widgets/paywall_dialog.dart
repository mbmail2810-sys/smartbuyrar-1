import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../models/subscription_model.dart';
import '../../providers/subscription_provider.dart';

class PaywallDialog extends ConsumerWidget {
  final String feature;
  final SubscriptionPlan requiredPlan;
  final String? customMessage;

  const PaywallDialog({
    super.key,
    required this.feature,
    required this.requiredPlan,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPlan = ref.watch(currentPlanProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF00B200).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline,
                color: Color(0xFF00B200),
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Unlock $feature',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              customMessage ??
                  'Upgrade to ${requiredPlan.displayName} plan or higher to access $feature.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(
                    requiredPlan.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          requiredPlan.displayName,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          requiredPlan.description,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₹${requiredPlan.priceInr}/mo',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF00B200),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      'Maybe Later',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/subscription');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00B200),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Upgrade Now',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void showPaywallDialog(
  BuildContext context, {
  required String feature,
  required SubscriptionPlan requiredPlan,
  String? customMessage,
}) {
  showDialog(
    context: context,
    builder: (context) => PaywallDialog(
      feature: feature,
      requiredPlan: requiredPlan,
      customMessage: customMessage,
    ),
  );
}

class FeatureGate extends ConsumerWidget {
  final Widget child;
  final Widget? lockedChild;
  final SubscriptionPlan requiredPlan;
  final String featureName;

  const FeatureGate({
    super.key,
    required this.child,
    this.lockedChild,
    required this.requiredPlan,
    required this.featureName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPlan = ref.watch(currentPlanProvider);
    final hasAccess = currentPlan.index >= requiredPlan.index;

    if (hasAccess) {
      return child;
    }

    return lockedChild ??
        GestureDetector(
          onTap: () => showPaywallDialog(
            context,
            feature: featureName,
            requiredPlan: requiredPlan,
          ),
          child: Opacity(
            opacity: 0.5,
            child: AbsorbPointer(child: child),
          ),
        );
  }
}
