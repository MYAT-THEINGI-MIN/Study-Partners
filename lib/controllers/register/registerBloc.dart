import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sp_test/Service/isStrongPswd.dart';
import 'package:sp_test/controllers/register/registerEvent.dart';
import 'package:sp_test/controllers/register/registerState.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  RegisterBloc({required FirebaseAuth auth})
      : _auth = auth,
        super(RegisterInitial()) {
    on<RegisterButtonPressed>(_onRegisterButtonPressed);
  }

  Future<String?> _uploadProfileImage(File? imageFile) async {
    if (imageFile == null) return null;
    try {
      final storageRef =
          _storage.ref().child('profile_images/${_auth.currentUser!.uid}.jpg');
      await storageRef.putFile(imageFile);
      return await storageRef.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  void _onRegisterButtonPressed(
      RegisterButtonPressed event, Emitter<RegisterState> emit) async {
    emit(RegisterLoading());

    try {
      if (!isStrongPassword(event.password)) {
        emit(const RegisterFailure(
            error:
                'Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character.'));
        return;
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );

      if (userCredential.user != null) {
        final profileImageUrl = await _uploadProfileImage(event.profileImage);

        // Store user data in Firestore
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'username': event.username,
          'email': event.email,
          'subjects': event.subjects,
          'profileImageUrl': profileImageUrl,
        });

        // Send the default Firebase email verification
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
