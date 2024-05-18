import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sp_test/Service/isStrongPswd.dart';
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
      // Check password strength first
      if (!isStrongPassword(event.password)) {
        emit(const RegisterFailure(
            error:
                'Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character.'));
        return;
      }

      // If the password is strong, proceed with user registration
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );

      if (userCredential.user != null) {
        // Send email verification
        await userCredential.user!.sendEmailVerification();
        emit(RegisterSuccess());
      } else {
        emit(const RegisterFailure(error: 'Registration failed'));
      }
    } catch (error) {
      emit(RegisterFailure(error: error.toString()));
    }
  }
}
