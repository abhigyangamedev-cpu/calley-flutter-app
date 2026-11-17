import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';
import '../services/session.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'register_screen.dart';
import 'validators.dart';
import 'welcome_screen.dart';

/// Frame 04. Not part of the required flow, but wired to the login endpoint
/// so returning users can get back in.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final api = context.read<ApiClient>();
    final session = context.read<Session>();

    setState(() => _loading = true);
    try {
      final user =
          await api.login(email: _email.text.trim(), password: _password.text);
      await session.signIn(user);
      if (!mounted) return;
      await Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const WelcomeScreen()),
        (_) => false,
      );
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goToSignUp() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const RegisterScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            const Text('Welcome',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Please sign-in to continue',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: validateEmail,
              decoration: const InputDecoration(
                hintText: 'Email address',
                suffixIcon: Icon(Icons.mail_outline),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: 'Password',
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Show password' : 'Hide password',
                  icon: Icon(_obscure ? Icons.lock_outline : Icons.lock_open_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => showComingSoon(context, 'Password reset'),
                child: const Text('Forgot Password?'),
              ),
            ),
          ],
        ),
      ),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FooterLink(
              text: "Don't have an account?", action: 'Sign Up', onTap: _goToSignUp),
          const SizedBox(height: 4),
          PrimaryButton(label: 'Sign In', loading: _loading, onPressed: _submit),
        ],
      ),
    );
  }
}
