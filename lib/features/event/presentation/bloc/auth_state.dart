part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  final UserEntity? user;

  const AuthState({required this.user});

  @override
  List<Object?> get props => [
        user,
      ];

  @override
  String toString() {
    return 'USER: $user';
  }
}

class AuthInitialState extends AuthState {
  const AuthInitialState()
      : super(
          user: null,
        );
}

//! ----------------- ROLE Admin -------------------------
class AuthAdminWebSuccessState extends AuthState {
  const AuthAdminWebSuccessState({required super.user});
}

class AuthAdminMobileSuccessState extends AuthState {
  const AuthAdminMobileSuccessState({required super.user});
}

//! --------------------------- ROLE Employee ------------------------
class AuthEmployeeMobileState extends AuthState {
  const AuthEmployeeMobileState({required super.user});
}

class AuthEmployeeWebRestrictedState extends AuthState {
  const AuthEmployeeWebRestrictedState({required super.user});
}

class AuthOnboardingState extends AuthState {
  const AuthOnboardingState({required super.user});
}

// !---------------------------------------------- AUTH STATE ----------------------------------------
//-----------------------------------------------------------------------------------------------------
class SendResetPasswordState extends AuthState {
  const SendResetPasswordState() : super(user: null);
}

//! sign out
class SignOutState extends AuthState {
  const SignOutState({required super.user});
}

class CheckingSignOut extends SignOutState {
  const CheckingSignOut({required super.user});
}

//! ----- REQUEST
class AuthRequestState extends AuthState {
  const AuthRequestState() : super(user: null);
}

class ResetPasswordState extends AuthRequestState {}

//! ************************* FAILURE ***************************/

class ResetPasswordFailedState extends AuthState {
  const ResetPasswordFailedState() : super(user: null);
}

class UserNotFoundState extends AuthState {
  const UserNotFoundState() : super(user: null);
}

class SignInFailedState extends AuthState {
  const SignInFailedState() : super(user: null);
}

class SignUpFailedState extends AuthState {
  const SignUpFailedState() : super(user: null);
}

class GetAuthenticatedUserFailedState extends AuthState {
  const GetAuthenticatedUserFailedState() : super(user: null);
}

class SignOutFailedState extends AuthState {
  
  const SignOutFailedState({required super.user});
}

class AuthOfflineState extends AuthState {
  const AuthOfflineState() : super(user: null);
}
