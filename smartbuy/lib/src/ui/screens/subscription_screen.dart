import 'dart:js' as js;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/subscription_model.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/auth_providers.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool _isLoading = false;
  SubscriptionPlan? _selectedPlan;

  @override
  Widget build(BuildContext context) {
    final currentSubscription = ref.watch(userSubscriptionProvider);
    final currentPlan = currentSubscription.valueOrNull?.plan ?? SubscriptionPlan.free;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade50,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Upgrade Your Plan',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCurrentPlanBanner(currentPlan),
            const SizedBox(height: 24),
            Text(
              'Choose Your Plan',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Unlock more features with our premium plans',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            ...SubscriptionPlan.values.map((plan) => _buildPlanCard(plan, currentPlan)),
            const SizedBox(height: 24),
            _buildFeatureComparison(),
          ],
        ),
      ),
      bottomNavigationBar: _selectedPlan != null && _selectedPlan != currentPlan && _selectedPlan != SubscriptionPlan.free
          ? _buildCheckoutButton()
          : null,
    );
  }

  Widget _buildCurrentPlanBanner(SubscriptionPlan currentPlan) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF00B200), const Color(0xFF00D100)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              currentPlan.emoji,
              style: const TextStyle(fontSize: 28),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Plan',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                Text(
                  currentPlan.displayName,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          if (currentPlan != SubscriptionPlan.free)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Active',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF00B200),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan, SubscriptionPlan currentPlan) {
    final isSelected = _selectedPlan == plan;
    final isCurrent = currentPlan == plan;
    final isPopular = plan == SubscriptionPlan.family;

    return GestureDetector(
      onTap: () {
        if (!isCurrent && plan != SubscriptionPlan.free) {
          setState(() {
            _selectedPlan = plan;
          });
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00B200)
                : isCurrent
                    ? const Color(0xFF00B200).withOpacity(0.5)
                    : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: const Color(0xFF00B200).withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Stack(
          children: [
            if (isPopular)
              Positioned(
                top: 0,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF6B00),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: Text(
                    'POPULAR',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getPlanColor(plan).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        plan.emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              plan.displayName,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            if (isCurrent) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00B200).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Current',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF00B200),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          plan.description,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        plan.priceInr == 0 ? 'Free' : '₹${plan.priceInr}',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF00B200),
                        ),
                      ),
                      if (plan.priceInr > 0)
                        Text(
                          '/month',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Radio<SubscriptionPlan>(
                    value: plan,
                    groupValue: isCurrent ? plan : _selectedPlan,
                    onChanged: isCurrent || plan == SubscriptionPlan.free
                        ? null
                        : (value) {
                            setState(() {
                              _selectedPlan = value;
                            });
                          },
                    activeColor: const Color(0xFF00B200),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPlanColor(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.free:
        return Colors.grey;
      case SubscriptionPlan.plus:
        return Colors.blue;
      case SubscriptionPlan.family:
        return Colors.orange;
      case SubscriptionPlan.pro:
        return Colors.purple;
    }
  }

  Widget _buildFeatureComparison() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Feature Comparison',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildFeatureRow('Lists', ['1', '5', '∞', '∞']),
          _buildFeatureRow('Share Lists', [false, true, true, true]),
          _buildFeatureRow('Reminders', [false, true, true, true]),
          _buildFeatureRow('Collaboration', [false, false, true, true]),
          _buildFeatureRow('AI Insights', [false, false, false, true]),
          _buildFeatureRow('Cloud Backup', [false, false, false, true]),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String feature, List<dynamic> values) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              feature,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
          ),
          ...values.map((value) => Expanded(
                child: Center(
                  child: value is bool
                      ? Icon(
                          value ? Icons.check_circle : Icons.cancel,
                          color: value ? const Color(0xFF00B200) : Colors.grey[300],
                          size: 20,
                        )
                      : Text(
                          value.toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildCheckoutButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _isLoading ? null : _initiatePayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00B200),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  'Subscribe to ${_selectedPlan?.displayName} - ₹${_selectedPlan?.priceInr}/month',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _initiatePayment() async {
    if (_selectedPlan == null) return;

    final user = ref.read(authStateProvider).value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to subscribe')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final subscriptionService = ref.read(subscriptionServiceProvider);
      final orderData = await subscriptionService.createOrder(
        userId: user.uid,
        plan: _selectedPlan!,
      );

      // Open Razorpay checkout using JavaScript interop for web
      _openRazorpayCheckout(orderData, user.uid, user.email ?? '');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _openRazorpayCheckout(Map<String, dynamic> orderData, String userId, String email) {
    final options = {
      'key': orderData['key'],
      'amount': orderData['amount'],
      'currency': orderData['currency'],
      'name': orderData['name'],
      'description': orderData['description'],
      'order_id': orderData['orderId'],
      'prefill': {
        'email': email,
      },
      'theme': {
        'color': '#00B200',
      },
    };

    // Create JavaScript callback functions
    js.context['razorpaySuccessCallback'] = (dynamic response) {
      _handlePaymentSuccess(
        userId: userId,
        orderId: orderData['orderId'],
        paymentId: response['razorpay_payment_id']?.toString() ?? '',
      );
    };

    js.context['razorpayFailureCallback'] = (dynamic error) {
      _handlePaymentFailure(error.toString());
    };

    // Inject Razorpay script and open checkout
    js.context.callMethod('eval', ['''
      if (typeof Razorpay === 'undefined') {
        var script = document.createElement('script');
        script.src = 'https://checkout.razorpay.com/v1/checkout.js';
        script.onload = function() {
          openRazorpayCheckout();
        };
        document.head.appendChild(script);
      } else {
        openRazorpayCheckout();
      }
      
      function openRazorpayCheckout() {
        var options = ${_jsonEncode(options)};
        options.handler = function(response) {
          razorpaySuccessCallback(response);
        };
        var rzp = new Razorpay(options);
        rzp.on('payment.failed', function(response) {
          razorpayFailureCallback(response.error.description);
        });
        rzp.open();
      }
    ''']);
  }

  String _jsonEncode(Map<String, dynamic> data) {
    return data.entries.map((e) {
      final value = e.value;
      if (value is String) {
        return "'${e.key}': '${value.replaceAll("'", "\\'")}'";
      } else if (value is Map) {
        return "'${e.key}': ${_jsonEncode(value.cast<String, dynamic>())}";
      } else {
        return "'${e.key}': $value";
      }
    }).join(', ').let((s) => '{$s}');
  }

  Future<void> _handlePaymentSuccess({
    required String userId,
    required String orderId,
    required String paymentId,
  }) async {
    try {
      final subscriptionService = ref.read(subscriptionServiceProvider);
      final success = await subscriptionService.verifyAndActivateSubscription(
        userId: userId,
        orderId: orderId,
        paymentId: paymentId,
        plan: _selectedPlan!,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully subscribed to ${_selectedPlan?.displayName}!'),
              backgroundColor: const Color(0xFF00B200),
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Subscription activation failed. Please contact support.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _handlePaymentFailure(String error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

extension _StringExtension on String {
  T let<T>(T Function(String) block) => block(this);
}
