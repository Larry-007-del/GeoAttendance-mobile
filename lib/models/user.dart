import 'dart:convert';

class User {
  final String id;
  final String name;
  final String email;
  final String password;
  final String address;
  final String type;
  final String token;
  final String? role;
  final String? studentId;
  final String? staffId;
  final String? username;

  User(
      {required this.id,
      required this.name,
      required this.email,
      required this.password,
      required this.address,
      required this.type,
      required this.token,
      this.role,
      this.studentId,
      this.staffId,
      this.username});

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'address': address,
      'type': type,
      'token': token,
      'role': role,
      'student_id': studentId,
      'staff_id': staffId,
      'username': username,
    };
  }

  // Django API response format
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['user_id']?.toString() ?? map['id']?.toString() ?? '',
      name: map['name'] ?? map['first_name'] ?? '',
      password: map['password'] ?? '',
      email: map['email'] ?? '',
      address: map['address'] ?? '',
      type: map['type'] ?? '',
      token: map['token'] ?? '',
      role: map['role'],
      studentId: map['student_id'],
      staffId: map['staff_id'],
      username: map['username'],
    );
  }

  factory User.fromJson(String source) => User.fromMap(json.decode(source));
}