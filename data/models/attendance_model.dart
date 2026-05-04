class AttendanceModel {
  final String date;
  final String status; // present, absent, late
  final String? boardingTime;
  final String? alightingTime;
  final String childName;

  AttendanceModel({
    required this.date,
    required this.status,
    this.boardingTime,
    this.alightingTime,
    required this.childName,
  });

  factory AttendanceModel.fromMap(Map<String, dynamic> d) {
    return AttendanceModel(
      date:         d['date'] ?? '',
      status:       d['status'] ?? 'absent',
      boardingTime: d['boardingTime'],
      alightingTime: d['alightingTime'],
      childName:    d['childName'] ?? '',
    );
  }
}
