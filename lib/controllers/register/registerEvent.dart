import 'package:equatable/equatable.dart';
import 'dart:io';

abstract class RegisterEvent extends Equatable {
  const RegisterEvent();

  @override
  List<Object?> get props => [];
}

class RegisterButtonPressed extends RegisterEvent {
  final String email;
  final String password;
  final String username;
  final String subjects;
  final File? profileImage;

  const RegisterButtonPressed({
    required this.email,
    required this.password,
    required this.username,
    required this.subjects,
    this.profileImage,
  });

  @override
  List<Object?> get props =>
      [email, password, username, subjects, profileImage];
}
