import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../services/api_client.dart';
import '../services/session.dart';
import '../theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/common.dart';
import '../widgets/shell.dart';

/// Frame 08. Totals and status breakdown from GET /list/{id}.
class ListDetailScreen extends StatefulWidget {
  const ListDetailScreen({super.key, required this.list});

  final CallingList list;

  @override
  State<ListDetailScreen> createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends State<ListDetailScreen> {
  late Future<ListDetails> _details = _fetch();

  Future<ListDetails> _fetch() => context.read<ApiClient>().getListDetails(
        listId: widget.list.id,
        email: context.read<Session>().user?.email ?? '',
      );

  Future<void> _refresh() async {
    final future = _fetch();
    setState(() {
      _details = future;
    });
    try {
      await future;
    } on ApiException {
      // Shown by the FutureBuilder.
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = context.watch<Session>().user?.username ?? '';

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: calleyAppBar(context),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<ListDetails>(
                future: _details,
                builder: (context, snapshot) {
                  final children = <Widget>[];
                  if (snapshot.connectionState != ConnectionState.done) {
                    children.add(const Padding(
                      padding: EdgeInsets.only(top: 120),
                      child: Center(child: CircularProgressIndicator()),
                    ));
                  } else if (snapshot.hasError) {
                    children.add(ErrorRetry(
                        message: '${snapshot.error}', onRetry: _refresh));
                  } else {
                    final d = snapshot.data!;
                    children.addAll([
                      _SummaryCard(
                          listName: widget.list.name, total: d.total, userName: name),
                      const SizedBox(height: 28),
                      CallStatusDonut(details: d),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          _StatTile(
                              label: 'Pending',
                              count: d.pending,
                              color: AppColors.pending,
                              background: AppColors.pendingBg),
                          const SizedBox(width: 8),
                          _StatTile(
                              label: 'Done',
                              count: d.called,
                              color: AppColors.done,
                              background: AppColors.doneBg),
                          const SizedBox(width: 8),
                          _StatTile(
                              label: 'Schedule',
                              count: d.rescheduled,
                              color: AppColors.scheduled,
                              background: AppColors.scheduledBg),
                        ],
                      ),
                    ]);
                  }
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: children,
                  );
                },
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: PrimaryButton(
                label: 'Start Calling Now',
                onPressed: () => showComingSoon(context, 'Auto dialing'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.listName,
    required this.total,
    required this.userName,
  });

  final String listName;
  final int total;
  final String userName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(listName,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('$total',
                        style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary)),
                    const SizedBox(width: 4),
                    const Text('CALLS',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              initialsOf(userName).characters.first,
              style: const TextStyle(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// Donut of pending / done / scheduled calls, drawn with fl_chart.
class CallStatusDonut extends StatelessWidget {
  const CallStatusDonut({super.key, required this.details});

  final ListDetails details;

  @override
  Widget build(BuildContext context) {
    const radius = 34.0;
    final parts = [
      (details.pending, AppColors.pending),
      (details.called, AppColors.done),
      (details.rescheduled, AppColors.scheduled),
    ].where((p) => p.$1 > 0).toList();

    final sections = parts.isEmpty
        ? [
            PieChartSectionData(
                value: 1, color: AppColors.border, radius: radius, showTitle: false)
          ]
        : [
            for (final (value, color) in parts)
              PieChartSectionData(
                  value: value.toDouble(),
                  color: color,
                  radius: radius,
                  showTitle: false),
          ];

    return Semantics(
      label: 'Call status chart: ${details.pending} pending, '
          '${details.called} done, ${details.rescheduled} scheduled',
      child: ExcludeSemantics(
        child: SizedBox(
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 112,
                height: 112,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFF1F3F6),
                ),
              ),
              PieChart(PieChartData(
                sections: sections,
                sectionsSpace: parts.length > 1 ? 4 : 0,
                centerSpaceRadius: 64,
                startDegreeOffset: -90,
              )),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.count,
    required this.color,
    required this.background,
  });

  final String label;
  final int count;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 38,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(count.toString().padLeft(2, '0'),
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w800)),
                        const SizedBox(width: 3),
                        const Text('Calls',
                            style: TextStyle(
                                fontSize: 10, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
