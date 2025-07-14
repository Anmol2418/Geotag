class UserModel {
  final String employeeId;
  final String name;

  UserModel({
    required this.employeeId,
    required this.name,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      employeeId: map['employee_id'] as String,
      name: map['name'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'employee_id': employeeId,
      'name': name,
    };
  }
}
