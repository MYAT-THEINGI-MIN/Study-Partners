import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sp_test/Service/authService.dart'; // Import authService.dart
import 'package:sp_test/screens/homePg.dart';
import 'package:sp_test/screens/loginPg.dart';
import 'package:sp_test/screens/registerPg.dart';

abstract class RouteNames {
  static const String home = "/";
  static const String login = "/login";
  static const String register = "/register";
}

List<String> protectedRoutes = [RouteNames.home, RouteNames.register];

Route<dynamic>? router(RouteSettings settings) {
  final String incomingRoute = settings.name ?? "/";

  // Handle protected routes
  if (protectedRoutes.contains(incomingRoute)) {
    return MaterialPageRoute(
      builder: (context) {
        return BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthAuthenticated) {
              // User is authenticated, allow access to the protected route
              return _getRouteWidget(settings.name);
            } else {
              // User is not authenticated, redirect to login page
              return LoginPg();
            }
          },
        );
      },
    );
  }

  // Handle other routes
  switch (incomingRoute) {
    case RouteNames.home:
      return MaterialPageRoute(builder: (_) => homePg());

    case RouteNames.login:
      return MaterialPageRoute(builder: (_) => LoginPg());

    case RouteNames.register:
      return MaterialPageRoute(builder: (_) => RegisterPg());

    default:
      return MaterialPageRoute(
        builder: (_) => Scaffold(
          body: Center(
            child: Text("Not Found!"),
          ),
        ),
      );
  }
}

Widget _getRouteWidget(String? routeName) {
  switch (routeName) {
    case RouteNames.home:
      return homePg();
    case RouteNames.register:
      return RegisterPg();
    // Add other cases for additional routes if needed
    default:
      // Return a default widget or handle appropriately
      return Scaffold(
        body: Center(
          child: Text("Not Found!"),
        ),
      );
  }
}
