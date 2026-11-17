import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../theme.dart';

/// Material Icons has no WhatsApp logo; a chat bubble in WhatsApp green is
/// used instead (swap for the exported Figma asset if available).
const whatsappIcon = Icons.chat_rounded;

void showSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? AppColors.error : null,
    ));
}

void showComingSoon(BuildContext context, String feature) =>
    showSnack(context, '$feature is coming soon.');

Future<void> openExternal(BuildContext context, String url) async {
  var opened = false;
  try {
    opened = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } on Object {
    opened = false;
  }
  if (!opened && context.mounted) {
    showSnack(context, 'Could not open $url', error: true);
  }
}

String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  final first = parts.first.characters.first;
  final last = parts.length > 1 ? parts.last.characters.first : '';
  return (first + last).toUpperCase();
}

/// Placeholder for the Calley logo (swap for an Image.asset of the exported
/// Figma logo when available).
class CalleyLogo extends StatelessWidget {
  const CalleyLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Calley, automatic call dialer',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (rect) => const SweepGradient(colors: [
                Color(0xFF22C55E),
                Color(0xFF06B6D4),
                Color(0xFF2563EB),
                Color(0xFFA855F7),
                Color(0xFFEF4444),
                Color(0xFFF59E0B),
                Color(0xFF22C55E),
              ]).createShader(rect),
              child: const Text(
                'C',
                style: TextStyle(
                  fontSize: 52,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'CALLEY',
                  style: TextStyle(
                    fontSize: 24,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w300,
                    color: Color(0xFF38BDF8),
                  ),
                ),
                Text(
                  'AUTOMATIC CALL DIALER',
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Logo on grey, then a white rounded panel holding the form (frames 02-04).
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.body, required this.footer});

  final Widget body;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            const CalleyLogo(),
            const SizedBox(height: 24),
            Expanded(
              child: Material(
                color: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  side: BorderSide(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
                        child: body,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: footer,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
            )
          : Text(label),
    );
  }
}

/// "Question? Action" line under the auth forms.
class FooterLink extends StatelessWidget {
  const FooterLink({super.key, required this.text, required this.action, this.onTap});

  final String text;
  final String action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(text, style: const TextStyle(fontSize: 13)),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            minimumSize: const Size(0, 36),
          ),
          child: Text(action, style: const TextStyle(fontSize: 13)),
        ),
      ],
    );
  }
}

class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.name, this.size = 40});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFFFE4D6),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Text(
        initialsOf(name),
        style: TextStyle(
          color: const Color(0xFFEA580C),
          fontWeight: FontWeight.w700,
          fontSize: size * 0.38,
        ),
      ),
    );
  }
}

/// Blue "Hello {name}" banner (frames 05 and 06).
class GreetingCard extends StatelessWidget {
  const GreetingCard({super.key, required this.name, required this.subtitle});

  final String name;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          UserAvatar(name: name, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hello $name',
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WhatsAppButton extends StatelessWidget {
  const WhatsAppButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 50,
      child: OutlinedButton(
        onPressed: () => openExternal(context, kWhatsAppUrl),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          side: const BorderSide(color: AppColors.whatsapp),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: const Icon(whatsappIcon,
            color: AppColors.whatsapp, semanticLabel: 'Open WhatsApp'),
      ),
    );
  }
}

/// WhatsApp button + main call-to-action, pinned to the bottom of a screen.
class CallActionRow extends StatelessWidget {
  const CallActionRow({super.key, required this.onStartCalling});

  final VoidCallback onStartCalling;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const WhatsAppButton(),
        const SizedBox(width: 10),
        Expanded(
          child: PrimaryButton(label: 'Start Calling Now', onPressed: onStartCalling),
        ),
      ],
    );
  }
}

class ErrorRetry extends StatelessWidget {
  const ErrorRetry({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 36, color: AppColors.textSecondary),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}
