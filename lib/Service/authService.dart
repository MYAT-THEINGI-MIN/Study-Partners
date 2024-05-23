import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:equatable/equatable.dart';

// Define AuthEvent class
abstract class AuthEvent extends Equatable {
  AuthEvent();

  @override
  List<Object> get props => [];
}

// Define your states
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}

class AuthAuthenticated extends AuthState {}

class AuthUnauthenticated extends AuthState {}

// Define AuthBloc
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AuthBloc() : super(AuthInitial()) {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        // User is authenticated
        emit(AuthAuthenticated());
      } else {
        // User is not authenticated
        emit(AuthUnauthenticated());
      }
    });
  }
}


//add a new document for the user in users collection if the it dosen't already exist
// _firestore.collection('users').doc(UserCredential.user!.uid).set({
//   'uid':UserCredential.user!.uid,
//   'email':email,
// },SetOptions(merge:true));

// //after creating new user create a new document for the user
// _firestore.collection('users').doc(UserCredential.user!.uid).set({
//   'uid':UserCredential.user!.uid,
//   'email':email,
// });