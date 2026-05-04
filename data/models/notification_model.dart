class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type; // boarding, alighting, delay, alert
  final DateTime timestamp;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> d) {
    return NotificationModel(
      id:        d['id']?.toString() ?? '',
      title:     d['title'] ?? '',
      body:      d['body'] ?? d['message'] ?? '',
      type:      d['type'] ?? 'alert',
      timestamp: d['timestamp'] != null
          ? DateTime.tryParse(d['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isRead:    d['isRead'] == true || d['isRead'] == 1,
    );
  }

  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
