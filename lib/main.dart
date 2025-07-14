import 'package:flutter/material.dart';
import 'supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/user_model.dart';

import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/attendance_history_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();


  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Geotagging Attendance App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: SplashScreen.routeName,
      routes: {
        SplashScreen.routeName: (_) => const SplashScreen(),
        LoginScreen.routeName: (_) => const LoginScreen(),

        // For HomeScreen, read UserModel from arguments:
        HomeScreen.routeName: (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          if (args is UserModel) {
            return HomeScreen(user: args);
          } else {
            // If no args passed, redirect to LoginScreen or show error
            return const LoginScreen();
          }
        },

        AttendanceHistoryScreen.routeName: (_) => const AttendanceHistoryScreen(),
      },
    );
  }
}
