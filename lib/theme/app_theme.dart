import 'package:flutter/material.dart'; 
 
class AppTheme { 
  static ThemeData lightTheme = ThemeData( 
    useMaterial3: true, 
 
    colorScheme: ColorScheme.fromSeed( 
      seedColor: Colors.blue, 
      brightness: Brightness.light, 
    ), 
 
    textTheme: const TextTheme( 
      headlineLarge: TextStyle( 
        fontSize: 32, 
        fontWeight: FontWeight.bold, 
      ), 
 
      titleLarge: TextStyle( 
        fontSize: 22, 
        fontWeight: FontWeight.w600, 
      ), 
 
      bodyLarge: TextStyle( 
        fontSize: 16, 
      ), 
    ), 
  ); 
} 
