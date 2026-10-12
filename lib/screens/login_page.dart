import 'package:flutter/material.dart';
import 'package:warehouse_management/core/app_scope.dart';
import 'package:warehouse_management/core/ui.dart';
import 'package:warehouse_management/core/validators.dart';
import 'package:warehouse_management/screens/signup_page.dart';
import 'package:warehouse_management/services/auth_service.dart';
import 'package:warehouse_management/utils/color_palette.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.onDemo});

  /// Called when user taps "Try demo" (offline sample data, no account).
  final VoidCallback onDemo;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hide = true;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final auth = AppScope.of(context).auth;
    if (auth == null) {
      showMessage(context, 'Cloud sign-in is unavailable. Try the demo.',
          error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await auth.signIn(_email.text, _password.text);
    } catch (e) {
      if (mounted)
        showMessage(context, AuthService.friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reset() async {
    final err = Validators.email(_email.text);
    if (err != null) {
      showMessage(context, 'Enter your email above first.', error: true);
      return;
    }
    final auth = AppScope.of(context).auth;
    if (auth == null) {
      showMessage(context, 'Cloud sign-in is unavailable.', error: true);
      return;
    }
    try {
      await auth.sendPasswordReset(_email.text);
      if (mounted) showMessage(context, 'Password reset email sent.');
    } catch (e) {
      if (mounted)
        showMessage(context, AuthService.friendlyError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _form,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.warehouse_rounded,
                      size: 64, color: ColorPalette.pacificBlue),
                  const SizedBox(height: 12),
                  const Text('Warehouse Management',
                      style: TextStyle(
                          fontSize: 26, color: ColorPalette.timberGreen)),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.next,
                    validator: Validators.email,
                    decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline)),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _password,
                    obscureText: _hide,
                    autofillHints: const [AutofillHints.password],
                    onFieldSubmitted: (_) => _submit(),
                    validator: (v) => Validators.required(v, 'Password'),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                            _hide ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _hide = !_hide),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                        onPressed: _reset,
                        child: const Text('Forgot password?')),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Sign in'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SignupPage())),
                    child: const Text('Create an account'),
                  ),
                  const Divider(height: 28),
                  OutlinedButton.icon(
                    onPressed: widget.onDemo,
                    icon: const Icon(Icons.play_circle_outline),
                    label: const Text('Try demo (sample data, no account)'),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
