import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../services/session.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'register_screen.dart';

/// Frame 01. Only English is available for now; the others are shown as in
/// the design but not selectable.
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  static const _languages = [
    ('English', 'Hi'),
    ('Hindi', 'नमस्ते'),
    ('Bengali', 'হ্যালো'),
    ('Kannada', 'ನಮಸ್ಕಾರ'),
    ('Punjabi', 'ਸਤ ਸ੍ਰੀ ਅਕਾਲ'),
    ('Tamil', 'வணக்கம்'),
    ('Telugu', 'హలో'),
    ('French', 'Bonjour'),
    ('Spanish', 'Hola'),
  ];
  static const _available = {'English'};

  String _selected = 'English';

  void _choose(String language) {
    if (!_available.contains(language)) {
      showSnack(context, '$language is coming soon. English is available for now.');
      return;
    }
    setState(() => _selected = language);
  }

  Future<void> _continue() async {
    await context.read<Session>().setLanguage(_selected);
    if (!mounted) return;
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const RegisterScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            children: [
              const Text(
                'Choose Your Language',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Material(
                  color: Colors.white,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _languages.length,
                    itemBuilder: (context, i) {
                      final (name, greeting) = _languages[i];
                      final selected = name == _selected;
                      return ListTile(
                        onTap: () => _choose(name),
                        selected: selected,
                        title: Text(name,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                        subtitle: Text(greeting,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                        trailing: Icon(
                          selected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: selected
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(label: 'Select', onPressed: _continue),
            ],
          ),
        ),
      ),
    );
  }
}
