import 'dart:convert';
import 'package:edi/constants/error_handling.dart';
import 'package:edi/constants/global_variables.dart';
import 'package:edi/constants/utils.dart';
import 'package:edi/features/home/loginscreen.dart';
import 'package:edi/models/user.dart';
import 'package:edi/providers/user_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Login user with Django API using JWT
  // For students: include student_id
  // For staff: include staff_id
  void loginUser({
    required BuildContext context,
    required String username,
    required String password,
    String? studentId,
    String? staffId,
  }) async {
    try {
      Map<String, dynamic> body = {
        'username': username,
        'password': password,
      };
      
      // Add role-specific ID (for backward compatibility)
      if (studentId != null) {
        body['student_id'] = studentId;
      }
      if (staffId != null) {
        body['staff_id'] = staffId;
      }

      http.Response res = await http.post(
        Uri.parse('$uri/api/auth/token/'),
        body: jsonEncode(body),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      httpErrorHandle(
          response: res,
          context: context,
          onSuccess: () async {
            // Parse response
            var data = jsonDecode(res.body);
            
            // Store JWT tokens
            SharedPreferences prefs = await SharedPreferences.getInstance();
            Provider.of<UserProvider>(context, listen: false).setUser(res.body);
            await prefs.setString('jwt_token', data['access']);
            await prefs.setString('refresh_token', data['refresh']);
            await prefs.setString('user_role', data['role'] ?? 'user');
            await prefs.setInt('user_id', data['user_id']);
            await prefs.setString('username', data['username']);
            
            // Navigate based on role
            if (mounted) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                LoginScreen.routeName,
                (route) => false,
              );
            }
          });
    } catch (e) {
      print(e.toString());
      showSnackBar(context, e.toString());
    }
  }

  // Logout user
  void logout({required BuildContext context}) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', '');
      await prefs.setString('refresh_token', '');
      await prefs.setString('user_role', '');
      await prefs.setInt('user_id', 0);
      await prefs.setString('username', '');
      
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
            context, LoginScreen.routeName, (route) => false);
      }
    } catch (e) {
      print(e);
    }
  }

  // Get user data from Django API
  void getUserData({required BuildContext context}) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');

      if (token == null) {
        prefs.setString('jwt_token', '');
        return;
      }

      // Validate token by fetching user profile
      http.Response userRes = await http.get(
        Uri.parse('$uri/api/me/profile/'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (userRes.statusCode == 200) {
        var userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.setUser(userRes.body);
      } else {
        // Token invalid, clear it
        await prefs.setString('jwt_token', '');
      }
    } catch (e) {
      print(e.toString());
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');
    return token != null && token.isNotEmpty;
  }

  // Get stored JWT access token
  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  // Get stored refresh token
  Future<String?> getRefreshToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('refresh_token');
  }

  // Get stored role
  Future<String?> getRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role');
  }

  // Get stored user ID
  Future<int> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id') ?? 0;
  }
}
