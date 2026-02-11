import 'dart:convert';
import 'package:edi/constants/error_handling.dart';
import 'package:edi/constants/global_variables.dart';
import 'package:edi/constants/utils.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DjangoApiService {
  // Get auth headers with JWT Bearer token
  Future<Map<String, String>> _getHeaders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');
    
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // Login with JWT
  Future<Map<String, dynamic>> login({
    required BuildContext context,
    required String username,
    required String password,
  }) async {
    try {
      http.Response res = await http.post(
        Uri.parse('$uri/api/auth/token/'),
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );

      httpErrorHandle(
        response: res,
        context: context,
        onSuccess: () {},
      );

      // Save token and user info
      if (res.statusCode == 200) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        var responseData = jsonDecode(res.body);
        await prefs.setString('jwt_token', responseData['access']);
        await prefs.setString('refresh_token', responseData['refresh']);
        await prefs.setString('user_role', responseData['role']);
        await prefs.setInt('user_id', responseData['user_id']);
        await prefs.setString('username', responseData['username']);
      }

      return jsonDecode(res.body);
    } catch (e) {
      print(e.toString());
      showSnackBar(context, e.toString());
      return {'error': e.toString()};
    }
  }

  // Refresh JWT token
  Future<bool> refreshToken(BuildContext context) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? refreshToken = prefs.getString('refresh_token');

      if (refreshToken == null) {
        return false;
      }

      http.Response res = await http.post(
        Uri.parse('$uri/api/auth/token/refresh/'),
        body: jsonEncode({'refresh': refreshToken}),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );

      if (res.statusCode == 200) {
        var responseData = jsonDecode(res.body);
        await prefs.setString('jwt_token', responseData['access']);
        return true;
      }

      return false;
    } catch (e) {
      print(e.toString());
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_role');
    await prefs.remove('user_id');
    await prefs.remove('username');
  }

  // Get courses list
  Future<List<dynamic>> getCourses(BuildContext context) async {
    try {
      http.Response res = await http.get(
        Uri.parse('$uri/api/courses/'),
        headers: await _getHeaders(),
      );

      httpErrorHandle(
        response: res,
        context: context,
        onSuccess: () {
          return jsonDecode(res.body);
        },
      );

      return jsonDecode(res.body);
    } catch (e) {
      print(e.toString());
      showSnackBar(context, e.toString());
      return [];
    }
  }

  // Get student enrolled courses
  Future<List<dynamic>> getEnrolledCourses(BuildContext context) async {
    try {
      http.Response res = await http.get(
        Uri.parse('$uri/api/student/enrolled_courses/'),
        headers: await _getHeaders(),
      );

      httpErrorHandle(
        response: res,
        context: context,
        onSuccess: () {},
      );

      return jsonDecode(res.body);
    } catch (e) {
      print(e.toString());
      showSnackBar(context, e.toString());
      return [];
    }
  }

  // Get lecturer's courses
  Future<List<dynamic>> getLecturerCourses(BuildContext context) async {
    try {
      http.Response res = await http.get(
        Uri.parse('$uri/api/lecturers/my-courses/'),
        headers: await _getHeaders(),
      );

      httpErrorHandle(
        response: res,
        context: context,
        onSuccess: () {},
      );

      return jsonDecode(res.body);
    } catch (e) {
      print(e.toString());
      showSnackBar(context, e.toString());
      return [];
    }
  }

  // Generate attendance token (Lecturer)
  Future<bool> generateAttendanceToken({
    required BuildContext context,
    required int courseId,
    required String token,
    required double latitude,
    required double longitude,
  }) async {
    try {
      http.Response res = await http.post(
        Uri.parse('$uri/api/courses/$courseId/generate_attendance_token/'),
        body: jsonEncode({
          'token': token,
          'latitude': latitude,
          'longitude': longitude,
        }),
        headers: await _getHeaders(),
      );

      httpErrorHandle(
        response: res,
        context: context,
        onSuccess: () {
          showSnackBar(context, 'Attendance token generated!');
        },
      );

      return res.statusCode == 200;
    } catch (e) {
      print(e.toString());
      showSnackBar(context, e.toString());
      return false;
    }
  }

  // Take attendance with token (Student)
  Future<bool> takeAttendance({
    required BuildContext context,
    required String token,
  }) async {
    try {
      http.Response res = await http.post(
        Uri.parse('$uri/api/courses/take_attendance/'),
        body: jsonEncode({'token': token}),
        headers: await _getHeaders(),
      );

      httpErrorHandle(
        response: res,
        context: context,
        onSuccess: () {
          showSnackBar(context, 'Attendance recorded successfully!');
        },
      );

      return res.statusCode == 200;
    } catch (e) {
      print(e.toString());
      showSnackBar(context, e.toString());
      return false;
    }
  }

  // Submit location for GPS-based attendance
  Future<bool> submitLocation({
    required BuildContext context,
    required double latitude,
    required double longitude,
    required String attendanceToken,
  }) async {
    try {
      http.Response res = await http.post(
        Uri.parse('$uri/api/submit_location/'),
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
          'attendance_token': attendanceToken,
        }),
        headers: await _getHeaders(),
      );

      httpErrorHandle(
        response: res,
        context: context,
        onSuccess: () {
          showSnackBar(context, 'Location verified!');
        },
      );

      return res.statusCode == 200;
    } catch (e) {
      print(e.toString());
      showSnackBar(context, e.toString());
      return false;
    }
  }

  // End attendance session (Lecturer)
  Future<bool> endAttendance({
    required BuildContext context,
    required int courseId,
  }) async {
    try {
      http.Response res = await http.post(
        Uri.parse('$uri/api/attendance/end_attendance/'),
        body: jsonEncode({'course_id': courseId}),
        headers: await _getHeaders(),
      );

      httpErrorHandle(
        response: res,
        context: context,
        onSuccess: () {
          showSnackBar(context, 'Attendance session ended!');
        },
      );

      return res.statusCode == 200;
    } catch (e) {
      print(e.toString());
      showSnackBar(context, e.toString());
      return false;
    }
  }

  // Get student attendance history
  Future<List<dynamic>> getStudentAttendanceHistory(BuildContext context) async {
    try {
      http.Response res = await http.get(
        Uri.parse('$uri/api/student/attendance/history/'),
        headers: await _getHeaders(),
      );

      httpErrorHandle(
        response: res,
        context: context,
        onSuccess: () {},
      );

      return jsonDecode(res.body);
    } catch (e) {
      print(e.toString());
      showSnackBar(context, e.toString());
      return [];
    }
  }

  // Get lecturer attendance history
  Future<List<dynamic>> getLecturerAttendanceHistory(BuildContext context) async {
    try {
      http.Response res = await http.get(
        Uri.parse('$uri/api/lecturer/attendance/history/'),
        headers: await _getHeaders(),
      );

      httpErrorHandle(
        response: res,
        context: context,
        onSuccess: () {},
      );

      return jsonDecode(res.body);
    } catch (e) {
      print(e.toString());
      showSnackBar(context, e.toString());
      return [];
    }
  }

  // Get all students
  Future<List<dynamic>> getStudents(BuildContext context) async {
    try {
      http.Response res = await http.get(
        Uri.parse('$uri/api/students/'),
        headers: await _getHeaders(),
      );

      httpErrorHandle(
        response: res,
        context: context,
        onSuccess: () {},
      );

      return jsonDecode(res.body);
    } catch (e) {
      print(e.toString());
      showSnackBar(context, e.toString());
      return [];
    }
  }

  // Get all lecturers
  Future<List<dynamic>> getLecturers(BuildContext context) async {
    try {
      http.Response res = await http.get(
        Uri.parse('$uri/api/lecturers/'),
        headers: await _getHeaders(),
      );

      httpErrorHandle(
        response: res,
        context: context,
        onSuccess: () {},
      );

      return jsonDecode(res.body);
    } catch (e) {
      print(e.toString());
      showSnackBar(context, e.toString());
      return [];
    }
  }
}
