import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailCtrl = TextEditingController();
  bool _isLoading = false;
  String? _message;
  bool _isSuccess = false;

  Future<void> _sendResetLink() async {
    final email = emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() {
        _message = "Please enter your email address";
        _isSuccess = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        setState(() {
          _message = "Password reset link sent! Check your email.";
          _isSuccess = true;
          _isLoading = false;
        });
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _message = e.message ?? "Failed to send reset email";
          _isSuccess = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _message = "An error occurred. Please try again.";
          _isSuccess = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth > 500 ? screenWidth * 0.15 : 24,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: screenHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: isSmallScreen ? 40 : 80),

                  SizedBox(
                    height: isSmallScreen ? 80 : 100,
                    child: Image.asset(
                      "assets/icons/smartbuy_cart_green.png",
                      fit: BoxFit.contain,
                    ),
                  ),

                  SizedBox(height: isSmallScreen ? 20 : 28),

                  Text(
                    "Forgot Password",
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 26 : 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.green.shade900,
                    ),
                  ),

                  SizedBox(height: isSmallScreen ? 10 : 14),

                  Text(
                    "Enter your email and we will\nsend you a password reset link",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 14 : 16,
                      color: Colors.grey.shade800,
                    ),
                  ),

                  SizedBox(height: isSmallScreen ? 24 : 32),

                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: "Email",
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.green, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.green, width: 2),
                      ),
                    ),
                  ),

                  if (_message != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: _isSuccess ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isSuccess ? Icons.check_circle : Icons.error,
                            color: _isSuccess ? Colors.green.shade700 : Colors.red.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _message!,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: _isSuccess ? Colors.green.shade800 : Colors.red.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _sendResetLink,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00B200),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: TextStyle(
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.w600,
                        ),
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
                          : const Text("Send reset link"),
                    ),
                  ),

                  SizedBox(height: isSmallScreen ? 16 : 22),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Remember your password?",
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 13 : 14,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          GoRouter.of(context).go("/sign-in");
                        },
                        child: Text(
                          "Sign in",
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 13 : 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: isSmallScreen ? 40 : 70),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
