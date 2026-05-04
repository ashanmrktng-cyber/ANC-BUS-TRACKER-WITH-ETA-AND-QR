import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});
  @override State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final now = DateTime.now();

  // Sample attendance data
  final Map<int, String> _attendance = {
    1: 'present', 2: 'present', 3: 'absent', 4: 'present', 5: 'present',
    6: 'late',    7: 'present', 8: 'present', 9: 'absent', 10: 'present',
    11: 'present',12: 'present',13: 'present',14: 'late',  15: 'present',
    16: 'present',17: 'absent', 18: 'present',19: 'present',20: 'present',
  };

  Color _statusColor(String s) {
    switch (s) {
      case 'present': return AppColors.success;
      case 'absent':  return AppColors.error;
      case 'late':    return AppColors.warning;
      default: return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final present = _attendance.values.where((v) => v == 'present').length;
    final absent  = _attendance.values.where((v) => v == 'absent').length;
    final late    = _attendance.values.where((v) => v == 'late').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Attendance'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // Summary row
          Row(children: [
            _summaryCard('Present', present, AppColors.success, AppColors.cardGreen),
            const SizedBox(width: 8),
            _summaryCard('Absent', absent, AppColors.error, AppColors.cardRed),
            const SizedBox(width: 8),
            _summaryCard('Late', late, AppColors.warning, AppColors.cardOrange),
          ]),
          const SizedBox(height: 20),

          // Calendar-style grid
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(DateFormat('MMMM yyyy').format(now),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                IconButton(icon: const Icon(Icons.calendar_today, color: AppColors.primary), onPressed: () {}),
              ]),
              const SizedBox(height: 12),

              // Day headers
              Row(children: ['Mon','Tue','Wed','Thu','Fri','Sat','Sun']
                .map((d) => Expanded(child: Center(child: Text(d,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textSecondary)))))
                .toList()),
              const SizedBox(height: 8),

              // Days grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7, mainAxisSpacing: 4, crossAxisSpacing: 4),
                itemCount: 31,
                itemBuilder: (_, i) {
                  final day = i + 1;
                  final status = _attendance[day];
                  if (status == null) {
                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                      child: Center(child: Text('$day',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11))),
                    );
                  }
                  return Container(
                    decoration: BoxDecoration(
                      color: _statusColor(status).withOpacity(0.15),
                      border: Border.all(color: _statusColor(status).withOpacity(0.4)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(child: Text('$day',
                      style: TextStyle(color: _statusColor(status),
                        fontWeight: FontWeight.bold, fontSize: 11))),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Legend
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _legend('Present', AppColors.success),
                const SizedBox(width: 16),
                _legend('Absent', AppColors.error),
                const SizedBox(width: 16),
                _legend('Late', AppColors.warning),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _summaryCard(String label, int count, Color color, Color bg) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        Text('$count', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
      ]),
    ));
  }

  Widget _legend(String label, Color color) {
    return Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
    ]);
  }
}
