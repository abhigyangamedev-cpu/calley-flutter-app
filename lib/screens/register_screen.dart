import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../services/api_client.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'otp_screen.dart';
import 'sign_in_screen.dart';
import 'validators.dart';

/// Frame 02. Registers the user, then asks the API to email an OTP.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _whatsapp = TextEditingController();
  final _mobile = TextEditingController();
  bool _agreed = false;
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [_name, _email, _password, _whatsapp, _mobile]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (!_agreed) {
      showSnack(context, 'Please agree to the Terms and Conditions.', error: true);
      return;
    }

    final api = context.read<ApiClient>();
    final registration = PendingRegistration(
      name: _name.text.trim(),
      email: _email.text.trim(),
      password: _password.text,
    );

    setState(() => _loading = true);
    try {
      await api.register(
        username: registration.name,
        email: registration.email,
        password: registration.password,
      );
      await api.sendOtp(registration.email);
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => OtpScreen(registration: registration),
      ));
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 14);
    final digitsOnly = [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(10),
    ];

    return AuthScaffold(
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Welcome!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Please register to continue',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            TextFormField(
              controller: _name,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.name],
              validator: validateName,
              decoration: const InputDecoration(
                hintText: 'Name',
                suffixIcon: Icon(Icons.person_outline),
              ),
            ),
            gap,
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
            gap,
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              validator: validatePassword,
              decoration: InputDecoration(
                hintText: 'Password',
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Show password' : 'Hide password',
                  icon: Icon(_obscure ? Icons.lock_outline : Icons.lock_open_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            gap,
            TextFormField(
              controller: _whatsapp,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              inputFormatters: digitsOnly,
              validator: validateMobile,
              decoration: const InputDecoration(
                hintText: 'WhatsApp number',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(left: 12, right: 8),
                  child: Text('🇮🇳  +91', style: TextStyle(fontSize: 14)),
                ),
                prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
                suffixIcon: Icon(whatsappIcon, color: AppColors.whatsapp),
              ),
            ),
            gap,
            TextFormField(
              controller: _mobile,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              inputFormatters: digitsOnly,
              validator: validateMobile,
              onFieldSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                hintText: 'Mobile number',
                suffixIcon: Icon(Icons.smartphone_outlined),
              ),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _agreed,
              onChanged: (v) => setState(() => _agreed = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text.rich(TextSpan(
                style: TextStyle(fontSize: 13),
                children: [
                  TextSpan(text: 'I agree to the '),
                  TextSpan(
                    text: 'Terms and Conditions',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ],
              )),
            ),
          ],
        ),
      ),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FooterLink(
            text: 'Already have an account?',
            action: 'Sign In',
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SignInScreen())),
          ),
          const SizedBox(height: 4),
          PrimaryButton(label: 'Sign Up', loading: _loading, onPressed: _submit),
        ],
      ),
    );
  }
}
