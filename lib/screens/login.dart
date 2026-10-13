import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:warehouse_management/functions/toast.dart';
import 'package:warehouse_management/screens/signup.dart';
import 'package:warehouse_management/utils/color_palette.dart';
import 'package:warehouse_management/utils/svg_strings.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  String _errorMessage = "";
  bool _isVisible = false;
  bool _loading = false;

  Future signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = "Please enter both email and password.";
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = "";
    });
    try {
      final value = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      showTextToast('Logged In Successfully!');
      if (value.user != null) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(value.user!.uid)
              .set({
            'uid': value.user!.uid,
            'email': email,
            'lastLogin': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true),);
        } catch (_) {}
      }
    } on FirebaseAuthException catch (e) {
      String msg = "Login failed!";
      final code = e.code.toLowerCase();
      final errorStr = (e.message ?? "").toLowerCase();

      if (code.contains('configuration-not-found') ||
          errorStr.contains('configuration_not_found') ||
          code == 'configuration_not_found') {
        msg =
            "Firebase Auth is not enabled in Firebase Console! Go to Authentication > Click 'Get started' > Enable 'Email/Password'.";
      } else if (code == 'operation-not-allowed') {
        msg =
            "Email/Password sign-in is disabled in Firebase Console > Authentication > Sign-in method.";
      } else if (code == 'user-not-found' || code == 'invalid-credential') {
        msg =
            "User not found or invalid credentials. Click 'Sign Up' to create an account.";
      } else if (code == 'wrong-password') {
        msg = "Incorrect password. Please try again.";
      } else if (code == 'invalid-email') {
        msg = "Invalid email address format.";
      } else if (e.message != null && e.message!.isNotEmpty) {
        msg = e.message!;
      }
      setState(() {
        _errorMessage = msg;
      });
      showTextToast(msg);
    } catch (e) {
      if (e.toString().contains('CONFIGURATION_NOT_FOUND')) {
        _errorMessage =
            "Firebase Auth is not enabled in Firebase Console! Go to Authentication > Click 'Get started' > Enable 'Email/Password'.";
      } else {
        _errorMessage = "Error: $e";
      }
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // onTap: () {
      //   final FocusScopeNode currentFocus = FocusScope.of(context);
      //   if (!currentFocus.hasPrimaryFocus) {
      //     currentFocus.unfocus();
      //   }
      // },
      child: Scaffold(
        backgroundColor: ColorPalette.aquaHaze,
        resizeToAvoidBottomInset: false,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(child: SizedBox()),
              SvgPicture.string(SvgStrings.warehouse),
              const SizedBox(
                height: 18,
              ),
              const Text(
                "Warehouse\nManagement",
                style: TextStyle(
                  fontFamily: "Nunito",
                  fontSize: 40,
                ),
              ),
              const SizedBox(
                height: 15,
              ),
              Row(
                children: [
                  SvgPicture.string(SvgStrings.location),
                  const SizedBox(
                    width: 10,
                  ),
                  const Text(
                    "XYZ's Godown",
                    style: TextStyle(fontFamily: "Open_Sans", fontSize: 20),
                  ),
                ],
              ),
              const SizedBox(
                height: 50,
              ),
              Container(
                decoration: BoxDecoration(
                  color: ColorPalette.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      offset: const Offset(0, 3),
                      blurRadius: 6,
                      color: const Color(0xff000000).withValues(alpha: 0.16),
                    ),
                  ],
                ),
                height: 50,
                child: TextField(
                  textInputAction: TextInputAction.next,
                  key: UniqueKey(),
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(
                    fontFamily: "Nunito",
                    fontSize: 16,
                    color: ColorPalette.nileBlue,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Email",
                    filled: true,
                    fillColor: Colors.transparent,
                    hintStyle: TextStyle(
                      fontFamily: "Nunito",
                      fontSize: 16,
                      color: ColorPalette.nileBlue.withValues(alpha: 0.58),
                    ),
                  ),
                  cursorColor: ColorPalette.timberGreen,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Container(
                decoration: BoxDecoration(
                  color: ColorPalette.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      offset: const Offset(0, 3),
                      blurRadius: 6,
                      color: const Color(0xff000000).withValues(alpha: 0.16),
                    ),
                  ],
                ),
                height: 50,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: UniqueKey(),
                        obscureText: !_isVisible,
                        controller: _passwordController,
                        textInputAction: TextInputAction.done,
                        keyboardType: TextInputType.visiblePassword,
                        style: const TextStyle(
                          fontFamily: "Nunito",
                          fontSize: 16,
                          color: ColorPalette.nileBlue,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Password",
                          filled: true,
                          fillColor: Colors.transparent,
                          hintStyle: TextStyle(
                            fontFamily: "Nunito",
                            fontSize: 16,
                            color: ColorPalette.nileBlue.withValues(alpha: 0.58),
                          ),
                        ),
                        cursorColor: ColorPalette.timberGreen,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.remove_red_eye,
                        color: _isVisible ? Colors.black : Colors.grey,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _isVisible = !_isVisible;
                        });
                      },
                      splashColor: Colors.transparent,
                      splashRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 15,
              ),
              if (_errorMessage.isNotEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
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
                ),
              const SizedBox(
                height: 15,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () async {
                      await signIn();
                    },
                    child: Container(
                      height: 50,
                      width: 105,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: ColorPalette.pacificBlue,
                        boxShadow: [
                          BoxShadow(
                            offset: const Offset(0, 3),
                            blurRadius: 6,
                            color: const Color(0xff000000).withValues(alpha: 0.16),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _loading
                            ? const SizedBox(
                                height: 15,
                                width: 15,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: ColorPalette.aquaHaze,
                                ),
                              )
                            : const Text(
                                "Login",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontFamily: "Nunito",
                                  fontWeight: FontWeight.bold,
                                  color: ColorPalette.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => SignUp(),
                        ),
                      );
                    },
                    child: Container(
                      height: 50,
                      width: 105,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: ColorPalette.white,
                        border: Border.all(
                          color: ColorPalette.pacificBlue,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            offset: const Offset(0, 3),
                            blurRadius: 6,
                            color: const Color(0xff000000).withValues(alpha: 0.08),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          "Sign Up",
                          style: TextStyle(
                            fontSize: 15,
                            fontFamily: "Nunito",
                            fontWeight: FontWeight.bold,
                            color: ColorPalette.pacificBlue,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        ),
      ),
    );
  }
}
