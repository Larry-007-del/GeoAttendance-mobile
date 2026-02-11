import 'package:edi/constants/global_variables.dart';
import 'package:edi/features/auth/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

class LoginScreen extends StatefulWidget {
  static const String routeName = '/login-screen';
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _idController = TextEditingController(); // student_id or staff_id
  final TextEditingController _passController = TextEditingController();
  final AuthService authService = AuthService();

  // Login role: 'student' or 'staff'
  String _selectedRole = 'student';

  double screenHeight = 0;
  double screenWidth = 0;

  void loginUser() {
    authService.loginUser(
      context: context,
      username: _usernameController.text,
      password: _passController.text,
      studentId: _selectedRole == 'student' ? _idController.text : null,
      staffId: _selectedRole == 'staff' ? _idController.text : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    bool? isKeyboardVisible =
        KeyboardVisibilityProvider.isKeyboardVisible(context);
    print(isKeyboardVisible);
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          isKeyboardVisible
              ? const SizedBox()
              : Container(
                  height: screenHeight / 3,
                  width: screenWidth,
                  decoration: const BoxDecoration(
                    color: GlobalVariables.violetcolor,
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(70),
                      bottomLeft: Radius.circular(70),
                    ),
                  ),
                  child: const Center(
                      child: Image(
                    image: AssetImage('lib/assets/images/11.png'),
                    color: Colors.white,
                  )),
                ),
          Container(
            alignment: Alignment.center,
            margin: EdgeInsets.only(
              top: screenHeight / 15,
              bottom: screenHeight / 20,
            ),
            child: Text(
              "Attendance Login",
              style: TextStyle(
                fontSize: screenWidth / 18,
                fontFamily: "NexaBold",
              ),
            ),
          ),
          // Role selector
          Container(
            margin: EdgeInsets.symmetric(horizontal: screenWidth / 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text("Student"),
                    value: 'student',
                    groupValue: _selectedRole,
                    activeColor: GlobalVariables.violetcolor,
                    onChanged: (value) {
                      setState(() {
                        _selectedRole = value!;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text("Staff/Lecturer"),
                    value: 'staff',
                    groupValue: _selectedRole,
                    activeColor: GlobalVariables.violetcolor,
                    onChanged: (value) {
                      setState(() {
                        _selectedRole = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Container(
            alignment: Alignment.centerLeft,
            margin: EdgeInsets.symmetric(
              horizontal: screenWidth / 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                fieldTitle("Username"),
                customField("Enter your username", _usernameController, false),
                fieldTitle(_selectedRole == 'student' ? "Student ID" : "Staff ID"),
                customField(
                    _selectedRole == 'student' ? "Enter your student ID" : "Enter your staff ID",
                    _idController,
                    false),
                fieldTitle("Password"),
                customField("Enter your password", _passController, true),
                GestureDetector(
                  onTap: () async {
                    FocusScope.of(context).unfocus();
                    String username = _usernameController.text.trim();
                    String id = _idController.text.trim();
                    String password = _passController.text.trim();

                    if (username.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Username is still empty!"),
                      ));
                    } else if (id.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            "${_selectedRole == 'student' ? 'Student ID' : 'Staff ID'} is still empty!"),
                      ));
                    } else if (password.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Password is still empty!"),
                      ));
                    } else {
                      print('Logging in as $_selectedRole');
                      loginUser();
                    }
                  },
                  child: Container(
                    height: 60,
                    width: screenWidth,
                    margin: EdgeInsets.only(top: screenHeight / 40),
                    decoration: const BoxDecoration(
                      color: GlobalVariables.violetcolor,
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                    ),
                    child: Center(
                      child: Text(
                        "LOGIN",
                        style: TextStyle(
                          fontFamily: "NexaBold",
                          fontSize: screenWidth / 26,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget fieldTitle(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: screenWidth / 26,
          fontFamily: "NexaBold",
        ),
      ),
    );
  }

  Widget customField(
      String hint, TextEditingController controller, bool obscure) {
    return Container(
      width: screenWidth,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: screenWidth / 6,
            child: Icon(
              Icons.person,
              color: GlobalVariables.violetcolor,
              size: screenWidth / 15,
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: screenWidth / 12),
              child: TextFormField(
                controller: controller,
                enableSuggestions: false,
                autocorrect: false,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    vertical: screenHeight / 35,
                  ),
                  border: InputBorder.none,
                  hintText: hint,
                ),
                maxLines: 1,
                obscureText: obscure,
              ),
            ),
          )
        ],
      ),
    );
  }
}
