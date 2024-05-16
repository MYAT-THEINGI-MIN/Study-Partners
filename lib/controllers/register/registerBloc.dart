import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'registerEvent.dart';
import 'registerState.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final FirebaseAuth _auth;

  RegisterBloc({required FirebaseAuth auth})
      : _auth = auth,
        super(RegisterInitial()) {
    // Register the event handler
    on<RegisterButtonPressed>(_onRegisterButtonPressed);
  }

  // Event handler for RegisterButtonPressed event
  void _onRegisterButtonPressed(
      RegisterButtonPressed event, Emitter<RegisterState> emit) async {
    emit(RegisterLoading());

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );

      if (userCredential.user != null) {
        // Check password strength
        if (_isStrongPassword(event.password)) {
          // Send email verification
          await userCredential.user!.sendEmailVerification();
          emit(RegisterSuccess());
        } else {
          emit(const RegisterFailure(
              error:
                  'Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character.'));
        }
      } else {
        emit(const RegisterFailure(error: 'Registration failed'));
      }
    } catch (error) {
      emit(RegisterFailure(error: error.toString()));
    }
  }

  // Function to check if the password is strong
  bool _isStrongPassword(String password) {
    // Regular expressions for password strength
    RegExp upperCase = RegExp(r'[A-Z]');
    RegExp lowerCase = RegExp(r'[a-z]');
    RegExp digit = RegExp(r'[0-9]');
    RegExp specialChars = RegExp(r'(?=.*[@#$%^&+=])');

    // Check if password meets all requirements
    return upperCase.hasMatch(password) &&
        lowerCase.hasMatch(password) &&
        digit.hasMatch(password) &&
        specialChars.hasMatch(password);
  }
}
