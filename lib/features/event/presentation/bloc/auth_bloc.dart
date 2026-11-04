import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:focushabit/features/auth/feature_auth_files.dart';
import '/core/cores_files.dart';

part 'auth_bloc_event.dart';
part 'auth_bloc_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
//
  final GetAuthenticatedUserCase _getAuthenticatedUserCase;
//--- AUTH W/EMAIL PASSWORD
  final CreateUserEmailPasswordCase _createUserEmailPasswordCase;
  final SignInOnlyWithEmailPasswordCase _signInOnlyWithEmailPasswordCase;

//---- AUTH SOCIAL
  final AuthenticateWithFacebookCase _signInWithFacebookCase;
  final AuthenticateWithGoogleCase _authenticateWithGoogleCase;

//---- TOKEN
  StreamSubscription<String?>? _tokenSubscription;
  final SyncAuthTokenUseCase _syncAuthTokenUseCase;

//---- SETUP
  final HandleLogoutCase _handleSignOutCase;
  final SendEmailCodeResetPasswordCase _sendEmailCodeResetPassCase;
  //
  final PlatformInfo _platformInfo;
  //
  final SetupNewUserUseCase _setupNewUserUseCase;

//!
  ///---> is called on [FormSignInBloc and FormSignUpBloc] after [validate if all fields ] are validated
  ///--> the state is listen on [Router Notifier] for handle the route to navigate user
  ///-- if user is authenticate save [Accept Terms condition]
  ///
  AuthBloc({
    required GetAuthenticatedUserCase getAuthenticatedUserCase,
    required CreateUserEmailPasswordCase createUserEmailPasswordCase,
    required SignInOnlyWithEmailPasswordCase signInOnlyWithEmailPasswordCase,
    required AuthenticateWithFacebookCase authenticateWithFacebookCase,
    required AuthenticateWithGoogleCase authenticateWithGoogleCase,
    required SendEmailCodeResetPasswordCase sendEmailCodeResetPassCase,
    //
    required SetupNewUserUseCase setupNewUserUseCase,
    required HandleLogoutCase handleSignOutCase,
    required PlatformInfo platformInfo,
    required SyncAuthTokenUseCase syncAuthTokenUseCase,
  })  : _platformInfo = platformInfo,
        _setupNewUserUseCase = setupNewUserUseCase,
        _getAuthenticatedUserCase = getAuthenticatedUserCase,
        _handleSignOutCase = handleSignOutCase,
        _authenticateWithGoogleCase = authenticateWithGoogleCase,
        _signInWithFacebookCase = authenticateWithFacebookCase,
        _signInOnlyWithEmailPasswordCase = signInOnlyWithEmailPasswordCase,
        _sendEmailCodeResetPassCase = sendEmailCodeResetPassCase,
        _createUserEmailPasswordCase = createUserEmailPasswordCase,
        _syncAuthTokenUseCase = syncAuthTokenUseCase,
        super(const AuthInitialState()) {
    //
    _tokenSubscription = _syncAuthTokenUseCase.call().listen(
          (_) {},
          onError: ((_) {}),
          //---Keep listening for when the connection returns
          cancelOnError: false,
        );

    //! event handle bloc
    on<GetAuthenticatedUserEvent>((event, emit) async {
      //
      final response =
          await _getAuthenticatedUserCase.getAuthenticatedUserCase();

      response.when((user) {
        final userRole = _addSharedAuthRoleEmit(user);

        emit(userRole);
        return;
        //
      }, (failure) {
        if (failure is AuthOfflineFailure) {
          emit(const AuthOfflineState());
          return;
        } else {
          emit(const GetAuthenticatedUserFailedState());
          return;
        }
      });

      //
    });
    //
    on<LoginWithEmailPasswordEvent>((event, emit) async {
      //
      emit(const AuthRequestState());

      final response = await _signInOnlyWithEmailPasswordCase
          .signInOnlyWithEmailPasswordCase(
              email: event.email, password: event.password);

      response.when((user) async {
        _setupNewUser(user.uid);

        final userRole = _addSharedAuthRoleEmit(user);

        emit(userRole);
        return;
        //
      }, (failure) {
        if (failure is AuthOfflineFailure) {
          emit(const AuthOfflineState());
          return;
        } else {
          emit(const SignInFailedState());
          return;
        }
      });

      //
    });

    on<CreateUserWithEmailAndPasswordEvent>((event, emit) async {
//
      emit(const AuthRequestState());
      //
      final response =
          await _createUserEmailPasswordCase.createUserWithEmailAndPasswordCase(
              name: event.name, email: event.email, password: event.password);

      response.when((user) {
        _setupNewUser(user.uid);

        final userRole = _addSharedAuthRoleEmit(user);

        emit(userRole);
      }, (failure) {
        if (failure is AuthOfflineFailure) {
          emit(const AuthOfflineState());
        } else {
          emit(const SignUpFailedState());
        }
        return;
      });

//
    });
    //
    on<AuthenticateWithGoogleEvent>((event, emit) async {
      //
      emit(const AuthRequestState());

      final response =
          await _authenticateWithGoogleCase.authenticateWithGoogle();
      response.when((user) {
        _setupNewUser(user.uid);

        final userRole = _addSharedAuthRoleEmit(user);

        emit(userRole);
      }, (failure) {
        if (failure is AuthOfflineFailure) {
          emit(const AuthOfflineState());
        } else {
          emit(const SignUpFailedState());
        }
        return;
      });

//
    });
    //! facebook
    on<AuthenticateWithFacebookEvent>((event, emit) async {
      //
      emit(const AuthRequestState());
      //
      final response = await _signInWithFacebookCase.authenticateWithFacebook();
      //
      response.when((user) {
        _setupNewUser(user.uid);

        final userRole = _addSharedAuthRoleEmit(user);

        emit(userRole);
      }, (failure) {
        if (failure is AuthOfflineFailure) {
          emit(const AuthOfflineState());
        } else {
          emit(const SignInFailedState());
        }
        return;
      });
    });
    //

    //! SignOutEvent
    on<SignOutEvent>((event, emit) async {
      //
      if (state.user == null) return;

      emit(CheckingSignOut(user: state.user));

      final response = await _handleSignOutCase.handleLogout(user: state.user!);

      response.when((success) {
        if (success) {
          emit(SignOutState(user: state.user));
        } else {
          emit(SignOutFailedState(user: state.user!));
          return;
        }
      }, (failure) {
        emit(SignOutFailedState(user: state.user!));
        return;
      });

      //
    });

//!--- SendResetPasswordEvent
    on<SendResetPasswordEvent>((event, emit) async {
      //
      emit(const AuthRequestState());

      await Future.delayed(Duration(milliseconds: 1000));

      final response = await _sendEmailCodeResetPassCase
          .sendEmailCodeResetPassword(email: event.email);
      //
      response.when((success) {
        if (success) {
          emit(const SendResetPasswordState());
        }
      }, (failure) {
        if (failure is AuthOfflineFailure) {
          emit(const AuthOfflineState());
        } else {
          emit(const ResetPasswordFailedState());
        }
      });
    });
  }

//!---> _addSharedAuthRoleEmit
  AuthState _addSharedAuthRoleEmit(UserEntity user) {
    //
    //! NEW USER
    if ((user.companyId ?? '').isEmpty &&
        (_platformInfo.isWeb || _platformInfo.isAndroid)) {
      return AuthOnboardingState(user: user);
    }
//!--- employer
    if (user.role == UserRole.admin && _platformInfo.isWeb) {
      return AuthAdminWebSuccessState(user: user);
    }
    if (user.role == UserRole.admin && _platformInfo.isAndroid) {
      return AuthAdminMobileSuccessState(user: user);
    }
//! employee
    if (user.role == UserRole.employee && _platformInfo.isAndroid) {
      return AuthEmployeeMobileState(user: user);
    }
    if (user.role == UserRole.employee && _platformInfo.isWeb) {
      return AuthEmployeeWebRestrictedState(user: user);
    }

    return const UserNotFoundState();
  }

//! _setupNewUser
  Future<Either<bool, DatasourceStatus>> _setupNewUser(String? uid) async {
    if (_platformInfo.isAndroid) {
      return await _setupNewUserUseCase.insertDefaultEventTypes(userId: uid);
    }

    return Either.success(false);
  }
  //

//! Subscription
  @override
  Future<void> close() {
    _tokenSubscription?.cancel();

    return super.close();
  }
}
