import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../models.dart';
import '../services/api_client.dart';
import '../services/session.dart';
import '../theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/common.dart';
import '../widgets/shell.dart';
import 'list_detail_screen.dart';

/// Frame 06. "Start Calling Now" opens the calling-lists bottom sheet.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final name = context.watch<Session>().user?.username ?? 'there';

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: calleyAppBar(context),
      bottomNavigationBar: const CalleyBottomNav(),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    GreetingCard(name: name, subtitle: 'Welcome to Calley!'),
                    const SizedBox(height: 12),
                    const _LoadNumbersCard(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            CallActionRow(onStartCalling: () => showCallingListsSheet(context)),
          ],
        ),
      ),
    );
  }
}

class _LoadNumbersCard extends StatelessWidget {
  const _LoadNumbersCard();

  @override
  Widget build(BuildContext context) {
    const body = TextStyle(fontSize: 13.5, height: 1.5, color: AppColors.textPrimary);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.navy,
            padding: const EdgeInsets.all(12),
            child: const Text(
              'LOAD NUMBER TO CALL',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text.rich(
              TextSpan(style: body, children: [
                const TextSpan(text: 'Visit '),
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: GestureDetector(
                    onTap: () => openExternal(context, kWebPanelUrl),
                    child: Text(kWebPanelUrl,
                        style: body.copyWith(color: AppColors.primary)),
                  ),
                ),
                const TextSpan(
                    text: ' to upload numbers that you wish to call using Calley '
                        'Mobile App.'),
              ]),
              textAlign: TextAlign.center,
            ),
          ),
          const _Illustration(),
        ],
      ),
    );
  }
}

/// Stand-in for the Figma illustration (agent with headset and phone).
class _Illustration extends StatelessWidget {
  const _Illustration();

  @override
  Widget build(BuildContext context) {
    return const ExcludeSemantics(
      child: SizedBox(
        height: 170,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircleAvatar(radius: 72, backgroundColor: AppColors.lightBlue),
            Icon(Icons.phone_iphone, size: 120, color: AppColors.navy),
            Positioned(
              top: 50,
              child: CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primary,
                child: Icon(Icons.upload, size: 16, color: Colors.white),
              ),
            ),
            Positioned(
              bottom: 16,
              right: 90,
              child: CircleAvatar(
                radius: 26,
                backgroundColor: Color(0xFFF97316),
                child: Icon(Icons.headset_mic, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showCallingListsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const CallingListsSheet(),
  );
}

/// Frame 07. Lists come from GET /list?userId=...
class CallingListsSheet extends StatefulWidget {
  const CallingListsSheet({super.key});

  @override
  State<CallingListsSheet> createState() => _CallingListsSheetState();
}

class _CallingListsSheetState extends State<CallingListsSheet> {
  late Future<List<CallingList>> _lists = _fetch();

  Future<List<CallingList>> _fetch() {
    final user = context.read<Session>().user;
    if (user == null) {
      return Future.error(const ApiException('Please sign in again.'));
    }
    return context.read<ApiClient>().getLists(userId: user.id, email: user.email);
  }

  void _refresh() {
    setState(() {
      _lists = _fetch();
    });
  }

  void _open(CallingList list) {
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(
      MaterialPageRoute<void>(builder: (_) => ListDetailScreen(list: list)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'CALLING LISTS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Flexible(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _SheetRow(
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text('Select Calling List',
                                    style: TextStyle(fontWeight: FontWeight.w600)),
                              ),
                              FilledButton.icon(
                                onPressed: _refresh,
                                icon: const Icon(Icons.refresh, size: 18),
                                label: const Text('Refresh'),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(0, 34),
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  textStyle: const TextStyle(fontSize: 13),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Flexible(child: _buildLists()),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLists() {
    return FutureBuilder<List<CallingList>>(
      future: _lists,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return ErrorRetry(message: '${snapshot.error}', onRetry: _refresh);
        }
        final lists = snapshot.data!;
        if (lists.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No calling lists yet. Upload numbers from the Calley web panel, '
              'then tap Refresh.',
              textAlign: TextAlign.center,
            ),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          itemCount: lists.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) => _SheetRow(
            onTap: () => _open(lists[i]),
            child: Row(
              children: [
                Expanded(
                  child: Text(lists[i].name,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                ),
                const Icon(Icons.arrow_circle_right_outlined,
                    color: AppColors.primary),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SheetRow extends StatelessWidget {
  const _SheetRow({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.lightBlue,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: child,
        ),
      ),
    );
  }
}
