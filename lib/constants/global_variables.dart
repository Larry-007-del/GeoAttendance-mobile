import 'package:flutter/material.dart';

// Django REST API Base URL
// Change this to your local server for development: 'http://10.0.2.2:8000'
// Production: 'https://attendance-system-backend-z1wl.onrender.com'
String uri = 'https://attendance-system-backend-z1wl.onrender.com';

class GlobalVariables {
  static const appBarGradient = LinearGradient(
    colors: [
      Color.fromARGB(255, 29, 201, 192),
      Color.fromARGB(255, 125, 221, 216),
    ],
    stops: [0.5, 1.0],
  );

  static const secondaryColor = Color.fromRGBO(255, 153, 0, 1);
  static const backgroundColor = Colors.white;
  static const Color greyBackgroundColor = Color(0xffebecee);
  static var selectedNavBarColor = Colors.cyan[800]!;
  static const unselectedNavBarColor = Colors.black87;
  static const Color violetcolor = Color.fromARGB(255, 114, 37, 208);
}
