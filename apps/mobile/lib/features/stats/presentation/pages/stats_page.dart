import 'package:flutter/material.dart';
import 'package:mobile/core/auth/auth_service.dart';
import 'package:mobile/core/services/analysis_history_service.dart';
import 'package:mobile/features/upload/presentation/pages/analysis_page.dart';
import 'package:mobile/shared/components/header.dart';
import 'package:mobile/shared/localization/app_localizations.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  List<AnalysisHistoryEntry>? _history;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final userId = AuthService().userId;
    if (userId == null) {
      if (!mounted) return;
      setState(() => _history = []);
      return;
    }
    final entries = await AnalysisHistoryService().getHistory(userId);
    if (!mounted) return;
    setState(() => _history = entries);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: Header(
        title: l10n.t('stats.title'),
        description: l10n.t('stats.description'),
      ),
      body: RefreshIndicator(onRefresh: _loadHistory, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    final l10n = AppLocalizations.of(context);
    final history = _history;
    if (history == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 200),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }
    if (history.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          Column(
            children: [
              Icon(Icons.history_rounded, size: 72, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                l10n.t('stats.emptyTitle'),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.t('stats.emptySubtitle'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey[400]),
              ),
            ],
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: history.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _AnalysisCard(entry: history[index]),
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  final AnalysisHistoryEntry entry;
  const _AnalysisCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isCompleted = entry.isCompleted;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCompleted
              ? colorScheme.secondary.withValues(alpha: 0.25)
              : Colors.redAccent.withValues(alpha: 0.25),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──
            Row(
              children: [
                Icon(
                  isCompleted
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  size: 18,
                  color: isCompleted ? colorScheme.secondary : Colors.redAccent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _formatDate(context, entry.createdAt),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? colorScheme.secondary.withValues(alpha: 0.12)
                        : Colors.redAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isCompleted
                        ? l10n.t('stats.statusCompleted')
                        : l10n.t('stats.statusFailed'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isCompleted
                          ? colorScheme.secondary
                          : Colors.redAccent,
                    ),
                  ),
                ),
              ],
            ),
            if (isCompleted) ...[
              const SizedBox(height: 12),
              // ── Stats row ──
              Row(
                children: [
                  if (entry.processingTimeMs != null)
                    _StatChip(
                      icon: Icons.timer_outlined,
                      label:
                          '${(entry.processingTimeMs! / 1000).toStringAsFixed(1)} s',
                    ),
                  if (entry.frameCount > 0) ...[
                    const SizedBox(width: 8),
                    _StatChip(
                      icon: Icons.video_file_outlined,
                      label: l10n.tr('stats.frames', {
                        'count': '${entry.frameCount}',
                      }),
                    ),
                  ],
                  if (entry.frameCount > 0) ...[
                    const SizedBox(width: 8),
                    _StatChip(
                      icon: Icons.person_outlined,
                      label: l10n.tr('stats.detectedRate', {
                        'rate': entry.detectionRate.toStringAsFixed(0),
                      }),
                    ),
                  ],
                ],
              ),
              if (entry.resultJson != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AnalysisViewPage(
                            resultJson: entry.resultJson!,
                            processingMs: entry.processingTimeMs,
                            videoFile: null,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.play_circle_outline_rounded,
                      size: 18,
                    ),
                    label: Text(l10n.t('stats.view')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.secondary,
                      side: BorderSide(color: colorScheme.secondary, width: 1),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime dt) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final diff = now.difference(dt);
    final time = '${_pad(dt.hour)}:${_pad(dt.minute)}';
    final date = '${_pad(dt.day)}/${_pad(dt.month)}/${dt.year}';

    if (diff.inDays == 0) {
      return l10n.tr('date.todayAt', {'time': time});
    } else if (diff.inDays == 1) {
      return l10n.tr('date.yesterdayAt', {'time': time});
    } else if (diff.inDays < 7) {
      final days = [
        l10n.t('date.day.monday'),
        l10n.t('date.day.tuesday'),
        l10n.t('date.day.wednesday'),
        l10n.t('date.day.thursday'),
        l10n.t('date.day.friday'),
        l10n.t('date.day.saturday'),
        l10n.t('date.day.sunday'),
      ];
      return l10n.tr('date.at', {'day': days[dt.weekday - 1], 'time': time});
    } else {
      return l10n.tr('date.full', {'date': date, 'time': time});
    }
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      ],
    );
  }
}
