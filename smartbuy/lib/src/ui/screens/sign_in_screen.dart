import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/auth_providers.dart';
import 'package:go_router/go_router.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool _isLoading = false;

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
                  SizedBox(height: isSmallScreen ? 20 : 40),

                  SizedBox(
                    height: isSmallScreen ? 80 : 100,
                    child: Image.asset(
                      "assets/icons/smartbuy_cart_green.png",
                      fit: BoxFit.contain,
                    ),
                  ),

                  SizedBox(height: isSmallScreen ? 16 : 24),

                  Text(
                    "Welcome to",
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 26 : 32,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade900,
                    ),
                  ),

                  Text(
                    "SmartBuy",
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 30 : 36,
                      fontWeight: FontWeight.w700,
                      color: Colors.green.shade900,
                    ),
                  ),

                  SizedBox(height: isSmallScreen ? 8 : 12),

                  Text(
                    "Your modern grocery companion.\nOrganize smarter, shop faster!",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 14 : 16,
                      color: Colors.grey.shade800,
                    ),
                  ),

                  SizedBox(height: isSmallScreen ? 20 : 28),

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

                  const SizedBox(height: 12),

                  TextField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: "Password",
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

                  const SizedBox(height: 6),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        GoRouter.of(context).push("/forgot-password");
                      },
                      child: Text(
                        "Forgot password?",
                        style: GoogleFonts.poppins(
                          color: Colors.green.shade800,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () async {
                        setState(() => _isLoading = true);
                        try {
                          await ref.read(authServiceProvider).signInWithEmailAndPassword(
                              emailCtrl.text,
                              passCtrl.text,
                          );
                          if (mounted) GoRouter.of(context).go("/lists");
                        } on FirebaseAuthException catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.message ?? "An unknown error occurred")),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _isLoading = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00B200),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: TextStyle(fontSize: isSmallScreen ? 16 : 18, fontWeight: FontWeight.w600),
                      ),
                      child: _isLoading 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("Sign in"),
                    ),
                  ),

                  const SizedBox(height: 14),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () async {
                        setState(() => _isLoading = true);
                        try {
                          await ref.read(authServiceProvider).signInWithGoogle();
                          if (mounted) GoRouter.of(context).go("/lists");
                        } on FirebaseAuthException catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.message ?? "An unknown error occurred")),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Google sign-in error: $e")),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _isLoading = false);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFF00B200), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            "assets/icons/google_logo.png",
                            height: 22,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "Sign in with Google",
                            style: GoogleFonts.poppins(
                              fontSize: isSmallScreen ? 15 : 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          )
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: isSmallScreen ? 14 : 18),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?",
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 13 : 14,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          GoRouter.of(context).push("/register");
                        },
                        child: Text(
                          "Sign up",
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 13 : 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: isSmallScreen ? 20 : 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
