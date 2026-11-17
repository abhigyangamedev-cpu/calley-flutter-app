import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../services/api_client.dart';
import '../services/demo_backend.dart';
import '../services/session.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'welcome_screen.dart';

const _otpLength = 6;
const _resendCooldown = 30;

/// Frame 03. Title kept as WhatsApp per the design; the API emails the OTP
/// (in demo mode the OTP is shown on screen instead).
class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.registration});

  final PendingRegistration registration;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otp = TextEditingController();
  final _focus = FocusNode();
  Timer? _timer;
  int _resendIn = _resendCooldown;
  bool _loading = false;

  /// Set once verify-otp succeeds, so a failed login can be retried without
  /// re-submitting an OTP the server has already consumed.
  bool _verified = false;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otp.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    _resendIn = _resendCooldown;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _resendIn--);
      if (_resendIn <= 0) timer.cancel();
    });
  }

  Future<void> _resend() async {
    try {
      await context.read<ApiClient>().sendOtp(widget.registration.email);
      if (!mounted) return;
      setState(_startCooldown);
      _otp.clear();
      showSnack(context, 'A new OTP has been sent to ${widget.registration.email}.');
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  Future<void> _verify() async {
    // Typing the 6th digit auto-submits; ignore a tap on Verify meanwhile.
    if (_loading) return;
    final otp = _otp.text;
    if (otp.length != _otpLength) {
      showSnack(context, 'Enter the $_otpLength-digit OTP.', error: true);
      return;
    }
    final api = context.read<ApiClient>();
    final session = context.read<Session>();
    final reg = widget.registration;

    setState(() => _loading = true);
    try {
      if (!_verified) {
        await api.verifyOtp(email: reg.email, otp: otp);
        _verified = true;
      }
      // Register doesn't return the user id that the list endpoints need,
      // so sign in with the same credentials to fetch it.
      final user = await api.login(email: reg.email, password: reg.password);
      await session.signIn(user, registeredAt: DateTime.now());
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

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      body: Column(
        children: [
          const SizedBox(height: 12),
          const Text(
            'Whatsapp OTP\nVerification',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, height: 1.15),
          ),
          const SizedBox(height: 10),
          const Text(
            'Please ensure that the email id mentioned is valid as we have sent '
            'an OTP to your email.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          if (context.read<ApiClient>().demoMode.value) ...[
            const SizedBox(height: 10),
            const Text(
              'Demo mode: no email is sent. Use OTP ${DemoBackend.otp}',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ],
          const SizedBox(height: 28),
          OtpInput(controller: _otp, focusNode: _focus, onCompleted: _verify),
          const SizedBox(height: 16),
          Text(widget.registration.email,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Wrong email? Edit'),
          ),
        ],
      ),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FooterLink(
            text: "Didn't receive OTP code?",
            action: _resendIn > 0
                ? 'Resend in 0:${_resendIn.toString().padLeft(2, '0')}'
                : 'Resend OTP',
            onTap: _resendIn > 0 ? null : _resend,
          ),
          const SizedBox(height: 4),
          PrimaryButton(label: 'Verify', loading: _loading, onPressed: _verify),
        ],
      ),
    );
  }
}

/// Six boxes backed by one invisible TextField, so typing, backspace, paste and
/// SMS/email code autofill all behave like a normal text field.
class OtpInput extends StatelessWidget {
  const OtpInput({
    super.key,
    required this.controller,
    required this.focusNode,
    this.onCompleted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback? onCompleted;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListenableBuilder(
          listenable: Listenable.merge([controller, focusNode]),
          builder: (context, _) {
            final text = controller.text;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _otpLength; i++)
                  Container(
                    width: 44,
                    height: 52,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: focusNode.hasFocus &&
                                i == text.length.clamp(0, _otpLength - 1)
                            ? AppColors.primary
                            : AppColors.border,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      i < text.length ? text[i] : '',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            );
          },
        ),
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              showCursor: false,
              enableInteractiveSelection: false,
              maxLength: _otpLength,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) {
                if (value.length == _otpLength) onCompleted?.call();
              },
              decoration: const InputDecoration(
                counterText: '',
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
