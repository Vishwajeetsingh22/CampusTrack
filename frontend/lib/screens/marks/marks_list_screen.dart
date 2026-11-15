import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/marks_model.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/marks_provider.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/error_state_view.dart';
import '../../widgets/loading_indicator.dart';
import 'marks_form_screen.dart';

class MarksListScreen extends StatefulWidget {
  const MarksListScreen({super.key});

  @override
  State<MarksListScreen> createState() => _MarksListScreenState();
}

class _MarksListScreenState extends State<MarksListScreen> {
  final List<String> _subjects = [
    'All',
    'NoSQL Databases',
    'Cloud Computing',
    'Mobile Application Dev',
    'Operating Systems',
  ];

  final List<String> _exams = ['All', 'Mid-Term', 'Final'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = Provider.of<MarksProvider>(context, listen: false);
      prov.loadMarks();
      prov.loadSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MarksProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          body: Column(
            children: [
              // Filter Header
              Container(
                color: AppTheme.surfaceWhite,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: Column(
                  children: [
                    // Subject Filter Dropdown & Exam Chips
                    Row(
                      children: [
                        // Subject Dropdown
                        Expanded(
                          flex: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.scaffoldBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.cardBorder),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: provider.selectedSubject,
                                isExpanded: true,
                                style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                                items: _subjects.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList(),
                                onChanged: (val) {
                                  if (val != null) provider.setSubjectFilter(val);
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Exam Filter Dropdown
                        Expanded(
                          flex: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.scaffoldBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.cardBorder),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: provider.selectedExam,
                                isExpanded: true,
                                style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                                items: _exams.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                onChanged: (val) {
                                  if (val != null) provider.setExamFilter(val);
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Content List
              Expanded(
                child: _buildMarksContent(context, provider),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const MarksFormScreen()),
              );
            },
            backgroundColor: AppTheme.indigoAccent,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_task_rounded),
            label: const Text('Add Marks'),
          ),
        );
      },
    );
  }

  Widget _buildMarksContent(BuildContext context, MarksProvider provider) {
    if (provider.isLoading && provider.records.isEmpty) {
      return const LoadingIndicator(message: 'Loading examination marks...');
    }

    if (provider.errorMessage != null && provider.records.isEmpty) {
      return ErrorStateView(
        message: provider.errorMessage!,
        onRetry: () => provider.loadMarks(refresh: true),
      );
    }

    if (provider.records.isEmpty) {
      return EmptyStateView(
        icon: Icons.grade_outlined,
        title: 'No Marks Records Found',
        message: 'No examination scores match the selected filters.',
        actionLabel: 'Record First Score',
        onAction: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (ctx) => const MarksFormScreen()),
          );
        },
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadMarks(refresh: true),
      color: AppTheme.indigoAccent,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: provider.records.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final mark = provider.records[index];
          return _buildMarksCard(context, mark, provider);
        },
      ),
    );
  }

  Widget _buildMarksCard(BuildContext context, MarksModel mark, MarksProvider provider) {
    Color pctColor = AppTheme.successGreen;
    Color pctBg = AppTheme.successBg;
    if (mark.percentage < 50) {
      pctColor = AppTheme.errorRed;
      pctBg = AppTheme.errorBg;
    } else if (mark.percentage < 75) {
      pctColor = const Color(0xFF0284C7);
      pctBg = const Color(0xFFF0F9FF);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Score Percentage Circle Badge
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: pctBg,
                shape: BoxShape.circle,
                border: Border.all(color: pctColor.withValues(alpha: 0.3), width: 1.5),
              ),
              child: Center(
                child: Text(
                  '${mark.percentage.round()}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: pctColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Subject and Student Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        mark.studentName ?? mark.studentId,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.navyPrimary),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.scaffoldBg,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: Text(
                          mark.studentId,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${mark.subject} • ${mark.exam}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Score: ${mark.marksObtained.toStringAsFixed(1)} / ${mark.maxMarks.toStringAsFixed(0)} marks',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),

            // Actions Menu
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, size: 20, color: AppTheme.textSecondary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              onSelected: (val) async {
                if (val == 'edit') {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => MarksFormScreen(marks: mark)),
                  );
                } else if (val == 'delete' && mark.id != null) {
                  final confirm = await ConfirmDialog.show(
                    context: context,
                    title: 'Delete Marks Entry?',
                    content: 'Are you sure you want to remove ${mark.exam} marks for ${mark.studentId} in ${mark.subject}?',
                  );
                  if (confirm) {
                    final ok = await provider.deleteMarks(mark.id!);
                    if (ok && context.mounted) {
                      Provider.of<DashboardProvider>(context, listen: false).loadDashboard(refresh: true);
                    }
                  }
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_rounded, size: 18, color: AppTheme.indigoAccent),
                      SizedBox(width: 8),
                      Text('Edit Score'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_rounded, size: 18, color: AppTheme.errorRed),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: AppTheme.errorRed)),
                    ],
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
