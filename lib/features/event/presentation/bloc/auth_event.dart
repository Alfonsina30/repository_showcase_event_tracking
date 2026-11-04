part of 'auth_bloc.dart';

abstract class AuthEvent {}

//!
class GetAuthenticatedUserEvent extends AuthEvent {}

class LoginWithEmailPasswordEvent extends AuthEvent {
  final String email;
  final String password;

  LoginWithEmailPasswordEvent({required this.email, required this.password});
}

class CreateUserWithEmailAndPasswordEvent extends AuthEvent {
//
  final String name;
  final String email;
  final String password;

  CreateUserWithEmailAndPasswordEvent(
      {required this.name, required this.email, required this.password});
}

// class SignWithGoogleEvent extends AuthEvent {}

class AuthenticateWithGoogleEvent extends AuthEvent {}

class AuthenticateWithFacebookEvent extends AuthEvent {}

// class CreateUserWithFacebookEvent extends AuthEvent {}

class SendResetPasswordEvent extends AuthEvent {
  final String email;

  SendResetPasswordEvent({required this.email});
}

class SignOutEvent extends AuthEvent {}
