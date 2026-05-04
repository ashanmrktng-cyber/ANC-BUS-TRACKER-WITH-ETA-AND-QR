import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final np   = Provider.of<NotificationProvider>(context);
    final notifs = np.notifications;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (notifs.isNotEmpty)
          TextButton(
            onPressed: () {
              for (var n in notifs) {
                if (!n.isRead) np.markRead(auth.user!.userId, n.id);
              }
            },
            child: const Text('Mark all read', style: TextStyle(color: Colors.white70, fontSize: 12)),
          ),
        ],
      ),
      body: notifs.isEmpty 
      ? const Center(child: Text('No notifications yet', style: TextStyle(color: AppColors.textSecondary)))
      : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifs.length,
        itemBuilder: (_, i) {
          final n = notifs[i];
          final isRead = n.isRead;
          final type = n.type;

          Color typeColor;
          IconData typeIcon;
          switch (type) {
            case 'status_update': typeColor = AppColors.success; typeIcon = Icons.directions_bus; break;
            case 'broadcast':     typeColor = AppColors.primary; typeIcon = Icons.campaign; break;
            case 'eta':           typeColor = AppColors.warning; typeIcon = Icons.access_time; break;
            default:              typeColor = AppColors.info;    typeIcon = Icons.info;
          }

          return GestureDetector(
            onTap: () => np.markRead(auth.user!.userId, n.id),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: isRead ? Colors.white : AppColors.primary.withOpacity(0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isRead ? AppColors.divider : AppColors.primary.withOpacity(0.2)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(14),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                  child: Icon(typeIcon, color: typeColor, size: 22),
                ),
                title: Text(n.title,
                  style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    fontSize: 14, color: AppColors.textPrimary)),
                subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const SizedBox(height: 4),
                  Text(n.body, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM dd, hh:mm a').format(n.timestamp),
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted)
                  ),
                ]),
                trailing: !isRead ? Container(width: 8, height: 8,
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)) : null,
              ),
            ),
          );
        },
      ),
    );
  }
}
