import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/attendance_model.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/error_state_view.dart';
import '../../widgets/loading_indicator.dart';
import 'mark_attendance_screen.dart';

class AttendanceListScreen extends StatefulWidget {
  const AttendanceListScreen({super.key});

  @override
  State<AttendanceListScreen> createState() => _AttendanceListScreenState();
}

class _AttendanceListScreenState extends State<AttendanceListScreen> {
  final List<String> _statuses = ['All', 'Present', 'Absent', 'Late'];
  final List<String> _subjects = [
    'All',
    'NoSQL Databases',
    'Cloud Computing',
    'Mobile Application Dev',
    'Operating Systems',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = Provider.of<AttendanceProvider>(context, listen: false);
      prov.loadAttendance();
      prov.loadSummary();
    });
  }

  Future<void> _pickDate(AttendanceProvider provider) async {
    final initial = provider.selectedDate != null ? DateTime.tryParse(provider.selectedDate!) ?? DateTime.now() : DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      provider.setDateFilter(DateFormat('yyyy-MM-dd').format(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AttendanceProvider>(
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
                    // Date & Subject filters
                    Row(
                      children: [
                        // Date picker chip
                        Expanded(
                          flex: 5,
                          child: InkWell(
                            onTap: () => _pickDate(provider),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: provider.selectedDate != null ? AppTheme.indigoSoftBg : AppTheme.scaffoldBg,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: provider.selectedDate != null ? AppTheme.indigoAccent : AppTheme.cardBorder,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 16,
                                    color: provider.selectedDate != null ? AppTheme.indigoAccent : AppTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      provider.selectedDate ?? 'Select Date',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: provider.selectedDate != null ? AppTheme.indigoAccent : AppTheme.textPrimary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (provider.selectedDate != null)
                                    GestureDetector(
                                      onTap: () => provider.setDateFilter(null),
                                      child: const Icon(Icons.close, size: 16, color: AppTheme.textSecondary),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Subject Dropdown
                        Expanded(
                          flex: 5,
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
                                items: _subjects.map((sub) => DropdownMenuItem(value: sub, child: Text(sub, overflow: TextOverflow.ellipsis))).toList(),
                                onChanged: (val) {
                                  if (val != null) provider.setSubjectFilter(val);
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Status Chips
                    SizedBox(
                      height: 34,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _statuses.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final st = _statuses[i];
                          final isSelected = provider.selectedStatus == st;
                          Color chipColor = AppTheme.indigoAccent;
                          if (st == 'Present') chipColor = AppTheme.successGreen;
                          if (st == 'Absent') chipColor = AppTheme.errorRed;
                          if (st == 'Late') chipColor = AppTheme.warningOrange;

                          return ChoiceChip(
                            label: Text(st),
                            selected: isSelected,
                            selectedColor: chipColor.withValues(alpha: 0.14),
                            labelStyle: TextStyle(
                              color: isSelected ? chipColor : AppTheme.textSecondary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 11,
                            ),
                            onSelected: (selected) {
                              if (selected) provider.setStatusFilter(st);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Content List
              Expanded(
                child: _buildAttendanceContent(context, provider),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const MarkAttendanceScreen()),
              );
            },
            backgroundColor: AppTheme.indigoAccent,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: const Text('Mark Attendance'),
          ),
        );
      },
    );
  }

  Widget _buildAttendanceContent(BuildContext context, AttendanceProvider provider) {
    if (provider.isLoading && provider.records.isEmpty) {
      return const LoadingIndicator(message: 'Loading attendance logs...');
    }

    if (provider.errorMessage != null && provider.records.isEmpty) {
      return ErrorStateView(
        message: provider.errorMessage!,
        onRetry: () => provider.loadAttendance(refresh: true),
      );
    }

    if (provider.records.isEmpty) {
      return EmptyStateView(
        icon: Icons.fact_check_outlined,
        title: 'No Attendance Records',
        message: 'No records match the selected date or subject filters.',
        actionLabel: 'Mark Attendance Now',
        onAction: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (ctx) => const MarkAttendanceScreen()),
          );
        },
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadAttendance(refresh: true),
      color: AppTheme.indigoAccent,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: provider.records.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final record = provider.records[index];
          return _buildAttendanceCard(context, record, provider);
        },
      ),
    );
  }

  Widget _buildAttendanceCard(BuildContext context, AttendanceModel record, AttendanceProvider provider) {
    Color statusColor = AppTheme.successGreen;
    Color statusBg = AppTheme.successBg;
    if (record.status == 'Absent') {
      statusColor = AppTheme.errorRed;
      statusBg = AppTheme.errorBg;
    } else if (record.status == 'Late') {
      statusColor = AppTheme.warningOrange;
      statusBg = AppTheme.warningBg;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Status Icon Indicator
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                record.status == 'Present'
                    ? Icons.check_circle_rounded
                    : (record.status == 'Absent' ? Icons.cancel_rounded : Icons.schedule_rounded),
                size: 22,
                color: statusColor,
              ),
            ),
            const SizedBox(width: 14),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        record.studentName ?? record.studentId,
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
                          record.studentId,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${record.subject} • ${record.date}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  if (record.remarks != null && record.remarks!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Note: ${record.remarks}',
                      style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppTheme.textMuted),
                    ),
                  ],
                ],
              ),
            ),

            // Status Badge & Action Menu
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    record.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.textMuted),
                  tooltip: 'Delete Log',
                  onPressed: () async {
                    if (record.id == null) return;
                    final confirm = await ConfirmDialog.show(
                      context: context,
                      title: 'Delete Attendance Record?',
                      content: 'Are you sure you want to remove attendance record for ${record.studentId} on ${record.date}?',
                    );
                    if (confirm) {
                      final ok = await provider.deleteAttendance(record.id!);
                      if (ok && context.mounted) {
                        Provider.of<DashboardProvider>(context, listen: false).loadDashboard(refresh: true);
                      }
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
