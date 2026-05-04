enum UserRole { parent, driver }

class UserModel {
  final String phoneNumber;
  final String name;
  final String userId;
  final String accountCode;
  final String? profilePic;
  final UserRole role;
  final String? email; // For Username login
  final List<ChildModel> children;

  UserModel({
    required this.phoneNumber,
    required this.name,
    required this.userId,
    required this.accountCode,
    this.profilePic,
    this.role = UserRole.parent,
    this.email,
    this.children = const [],
  });

  factory UserModel.fromMap(Map<String, dynamic> d) {
    return UserModel(
      phoneNumber: d['phone'] ?? '',
      name: d['name'] ?? '',
      userId: d['userId'] ?? d['parentid'] ?? '',
      accountCode: d['accountCode'] ?? '',
      profilePic: d['userpic'],
      role: d['role'] == 'driver' ? UserRole.driver : UserRole.parent,
      email: d['email'],
      children: (d['children'] as List?)?.map((c) => ChildModel.fromMap(c)).toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() => {
    'phone': phoneNumber,
    'name': name,
    'userId': userId,
    'accountCode': accountCode,
    'userpic': profilePic,
    'role': role.name,
    'email': email,
  };
}

class ChildModel {
  final String id;
  final String studentId; // e.g., ANC001
  final String name;
  final String busNumber;
  final String? routeName;
  final String? profilePic;
  final String status; // inBus, arrived, absent
  final double? latitude; // Student home location
  final double? longitude;

  ChildModel({
    required this.id,
    required this.studentId,
    required this.name,
    required this.busNumber,
    this.routeName,
    this.profilePic,
    this.status = 'absent',
    this.latitude,
    this.longitude,
  });

  factory ChildModel.fromMap(Map<String, dynamic> d) {
    return ChildModel(
      id: d['id'] ?? '',
      studentId: d['studentId'] ?? '',
      name: d['name'] ?? '',
      busNumber: d['busNumber'] ?? '',
      routeName: d['routeName'],
      profilePic: d['pic'],
      status: d['status'] ?? 'absent',
      latitude: d['latitude'],
      longitude: d['longitude'],
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'studentId': studentId,
    'name': name,
    'busNumber': busNumber,
    'routeName': routeName,
    'pic': profilePic,
    'status': status,
    'latitude': latitude,
    'longitude': longitude,
  };
}
