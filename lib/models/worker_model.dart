class WorkerModel {
  final String workerId;
  final String name;
  final String email;
  final String phone;
  final String password;

  WorkerModel({
    required this.workerId,
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'workerId': workerId,
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
    };
  }

  factory WorkerModel.fromJson(Map<String, dynamic> json) {
    return WorkerModel(
      workerId: json['workerId'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      password: json['password'] ?? '',
    );
  }
}

