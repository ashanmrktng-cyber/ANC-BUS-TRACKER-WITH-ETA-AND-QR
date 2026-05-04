class BusModel {
  final String busId;
  final String busNumber;
  final String driverName;
  final String driverPhone;
  final double? latitude;
  final double? longitude;
  final String status; // moving, stopped, offline
  final DateTime? lastUpdate;
  final String? routeName;
  final double? speed;
  final String? eta; // AI estimated arrival

  BusModel({
    required this.busId,
    required this.busNumber,
    required this.driverName,
    required this.driverPhone,
    this.latitude,
    this.longitude,
    this.status = 'offline',
    this.lastUpdate,
    this.routeName,
    this.speed,
    this.eta,
  });

  factory BusModel.fromMap(Map<String, dynamic> d) {
    return BusModel(
      busId:       d['assetID']?.toString() ?? '',
      busNumber:   d['assetName'] ?? d['busNumber'] ?? '',
      driverName:  d['driverName'] ?? '',
      driverPhone: d['driverPhone'] ?? '',
      latitude:    double.tryParse(d['latitude']?.toString() ?? ''),
      longitude:   double.tryParse(d['longitude']?.toString() ?? ''),
      status:      d['status'] ?? 'offline',
      routeName:   d['routeName'],
      speed:       double.tryParse(d['speed']?.toString() ?? ''),
      eta:         d['eta'],
    );
  }

  bool get isOnline => status != 'offline';
  bool get isMoving => status == 'moving';
}
