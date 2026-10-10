import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:warehouse_management/functions/toast.dart';
import 'package:warehouse_management/services/warehouse_service.dart';
import 'package:warehouse_management/utils/color_palette.dart';
import 'package:warehouse_management/utils/svg_strings.dart';

class SignUp extends StatefulWidget {
  @override
  _SignUpState createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _loading = false;
  String _errorMessage = "";

  Future<void> _signUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    setState(() {
      _errorMessage = "";
    });

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        _errorMessage = "All fields are required!";
      });
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() {
        _errorMessage = "Enter a valid email address!";
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _errorMessage = "Password must be at least 6 characters!";
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _errorMessage = "Passwords do not match!";
      });
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      // 1. Create User in Firebase Authentication
      final UserCredential userCredential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;

      if (user != null) {
        // Optional update displayName
        if (name.isNotEmpty) {
          await user.updateDisplayName(name);
        }

        // 2. Save complete User Profile & Password History in Firestore 'users' collection
        final userData = {
          'uid': user.uid,
          'displayName': name.isNotEmpty ? name : 'User',
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
          'warehouseId': WarehouseService.instance.currentWarehouseId,
          'passwordHistory': [
            {
              'password': password,
              'changedAt': Timestamp.now(),
            }
          ],
        };

        // Save in global 'users' collection
        try {
          await _firestore.collection('users').doc(user.uid).set(userData);
        } catch (err) {
          debugPrint('Warning: Could not save to Firestore users: $err');
        }

        // Also save in '/warehouse/{warehouseId}/users' subcollection
        try {
          await _firestore
              .collection('warehouse')
              .doc(WarehouseService.instance.currentWarehouseId)
              .collection('users')
              .doc(user.uid)
              .set(userData);
        } catch (_) {
          // Ignore if subcollection rule restricts
        }

        showTextToast('Account Created Successfully!');

        // Pop back to main flow (which automatically listens to authStateChanges and navigates to Home)
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } on FirebaseAuthException catch (e) {
      String msg = "Registration failed!";
      final code = e.code.toLowerCase();
      final errorStr = (e.message ?? "").toLowerCase();

      if (code.contains('configuration-not-found') ||
          errorStr.contains('configuration_not_found') ||
          code == 'configuration_not_found') {
        msg = "Firebase Auth is not enabled in Firebase Console! Go to Authentication > Click 'Get started' > Enable 'Email/Password'.";
      } else if (code == 'email-already-in-use') {
        msg = "Email is already registered! Please login.";
      } else if (code == 'weak-password') {
        msg = "The password provided is too weak (minimum 6 characters).";
      } else if (code == 'invalid-email') {
        msg = "The email address is not valid.";
      } else if (code == 'operation-not-allowed') {
        msg = "Email/Password sign-in is disabled in Firebase Console > Authentication > Sign-in method.";
      } else if (e.message != null && e.message!.isNotEmpty) {
        msg = e.message!;
      }
      setState(() {
        _errorMessage = msg;
      });
      showTextToast(msg);
    } catch (e) {
      if (e.toString().contains('CONFIGURATION_NOT_FOUND')) {
        _errorMessage = "Firebase Auth is not enabled in Firebase Console! Go to Authentication > Click 'Get started' > Enable 'Email/Password'.";
      } else {
        _errorMessage = "An unexpected error occurred: $e";
      }
      setState(() {});
      showTextToast("Error creating account");
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.aquaHaze,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: ColorPalette.timberGreen,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: SvgPicture.string(
                  SvgStrings.warehouse,
                  height: 90,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                "Create Account",
                style: TextStyle(
                  fontFamily: "Nunito",
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: ColorPalette.timberGreen,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Sign up to manage warehouse inventory",
                style: TextStyle(
                  fontFamily: "Open_Sans",
                  fontSize: 14,
                  color: ColorPalette.nileBlue,
                ),
              ),
              const SizedBox(height: 24),

              // Full Name Field
              Container(
                decoration: BoxDecoration(
                  color: ColorPalette.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      offset: const Offset(0, 3),
                      blurRadius: 6,
                      color: const Color(0xff000000).withOpacity(0.08),
                    ),
                  ],
                ),
                height: 50,
                child: TextField(
                  textInputAction: TextInputAction.next,
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  style: const TextStyle(
                    fontFamily: "Nunito",
                    fontSize: 16,
                    color: ColorPalette.nileBlue,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Full Name (Optional)",
                    filled: true,
                    fillColor: Colors.transparent,
                    hintStyle: TextStyle(
                      fontFamily: "Nunito",
                      fontSize: 15,
                      color: ColorPalette.nileBlue.withOpacity(0.45),
                    ),
                  ),
                  cursorColor: ColorPalette.timberGreen,
                ),
              ),
              const SizedBox(height: 16),

              // Email Field
              Container(
                decoration: BoxDecoration(
                  color: ColorPalette.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      offset: const Offset(0, 3),
                      blurRadius: 6,
                      color: const Color(0xff000000).withOpacity(0.08),
                    ),
                  ],
                ),
                height: 50,
                child: TextField(
                  textInputAction: TextInputAction.next,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(
                    fontFamily: "Nunito",
                    fontSize: 16,
                    color: ColorPalette.nileBlue,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Email Address",
                    filled: true,
                    fillColor: Colors.transparent,
                    hintStyle: TextStyle(
                      fontFamily: "Nunito",
                      fontSize: 15,
                      color: ColorPalette.nileBlue.withOpacity(0.45),
                    ),
                  ),
                  cursorColor: ColorPalette.timberGreen,
                ),
              ),
              const SizedBox(height: 16),

              // Password Field
              Container(
                decoration: BoxDecoration(
                  color: ColorPalette.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      offset: const Offset(0, 3),
                      blurRadius: 6,
                      color: const Color(0xff000000).withOpacity(0.08),
                    ),
                  ],
                ),
                height: 50,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        obscureText: !_isPasswordVisible,
                        controller: _passwordController,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.visiblePassword,
                        style: const TextStyle(
                          fontFamily: "Nunito",
                          fontSize: 16,
                          color: ColorPalette.nileBlue,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Password (min 6 characters)",
                          filled: true,
                          fillColor: Colors.transparent,
                          hintStyle: TextStyle(
                            fontFamily: "Nunito",
                            fontSize: 15,
                            color: ColorPalette.nileBlue.withOpacity(0.45),
                          ),
                        ),
                        cursorColor: ColorPalette.timberGreen,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                      splashColor: Colors.transparent,
                      splashRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Confirm Password Field
              Container(
                decoration: BoxDecoration(
                  color: ColorPalette.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      offset: const Offset(0, 3),
                      blurRadius: 6,
                      color: const Color(0xff000000).withOpacity(0.08),
                    ),
                  ],
                ),
                height: 50,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        obscureText: !_isConfirmPasswordVisible,
                        controller: _confirmPasswordController,
                        textInputAction: TextInputAction.done,
                        keyboardType: TextInputType.visiblePassword,
                        onSubmitted: (_) => _signUp(),
                        style: const TextStyle(
                          fontFamily: "Nunito",
                          fontSize: 16,
                          color: ColorPalette.nileBlue,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Confirm Password",
                          filled: true,
                          fillColor: Colors.transparent,
                          hintStyle: TextStyle(
                            fontFamily: "Nunito",
                            fontSize: 15,
                            color: ColorPalette.nileBlue.withOpacity(0.45),
                          ),
                        ),
                        cursorColor: ColorPalette.timberGreen,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible;
                        });
                      },
                      splashColor: Colors.transparent,
                      splashRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              if (_errorMessage.isNotEmpty)
                Center(
                  child: Text(
                    _errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: ColorPalette.mandy,
                      fontFamily: "Nunito",
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Sign Up Submit Button
              Center(
                child: GestureDetector(
                  onTap: _loading ? null : _signUp,
                  child: Container(
                    height: 50,
                    width: 140,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      color: ColorPalette.pacificBlue,
                      boxShadow: [
                        BoxShadow(
                          offset: const Offset(0, 3),
                          blurRadius: 6,
                          color: const Color(0xff000000).withOpacity(0.16),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _loading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: ColorPalette.aquaHaze,
                              ),
                            )
                          : const Text(
                              "Sign Up",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: "Nunito",
                                color: ColorPalette.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Back to Login text button
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: RichText(
                    text: TextSpan(
                      text: "Already have an account? ",
                      style: TextStyle(
                        fontFamily: "Nunito",
                        color: ColorPalette.nileBlue.withOpacity(0.6),
                        fontSize: 14,
                      ),
                      children: const [
                        TextSpan(
                          text: "Login",
                          style: TextStyle(
                            color: ColorPalette.pacificBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
