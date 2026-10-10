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
  bool _failed = false;
  bool _isVisible = false;
  bool _loading = false;

  Future signIn() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      await firebaseAuth
          .signInWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),)
          .then((value) async {
        showTextToast('Logged In Successfully!');
        if (value.user != null) {
          try {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(value.user!.uid)
                .set({
              'lastLogin': FieldValue.serverTimestamp(),
              'email': _emailController.text.trim(),
            }, SetOptions(merge: true));
          } catch (_) {}
        }
      });
    } catch (e) {
      setState(() {
        _failed = true;
      });
    }
    if (mounted) {
      setState(() {
        _loading = false;
      });
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
                      color: const Color(0xff000000).withOpacity(0.16),
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
                      color: ColorPalette.nileBlue.withOpacity(0.58),
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
                      color: const Color(0xff000000).withOpacity(0.16),
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
                            color: ColorPalette.nileBlue.withOpacity(0.58),
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
              Center(
                child: Text(
                  _failed ? "Enter valid credentials!" : "",
                  style: const TextStyle(
                    color: ColorPalette.mandy,
                    fontFamily: "Nunito",
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
                            color: const Color(0xff000000).withOpacity(0.16),
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
                            color: const Color(0xff000000).withOpacity(0.08),
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
