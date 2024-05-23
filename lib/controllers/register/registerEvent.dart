import 'package:equatable/equatable.dart';

abstract class RegisterEvent extends Equatable {
  const RegisterEvent();

  @override
  List<Object> get props => [];
}

class RegisterButtonPressed extends RegisterEvent {
  final String email;
  final String password;
  final String username; // Add this line

  const RegisterButtonPressed({
    required this.email,
    required this.password,
    required this.username, // Add this line
  });

  @override
  List<Object> get props => [email, password, username];
}
