import 'package:go_router/go_router.dart';
import 'package:focushabit/features/company/company_feature_files.dart';
import '../../features/event/event_feature_files.dart';
import '/features/auth/feature_auth_files.dart';
import '/core/cores_files.dart';
import '/app/app_files.dart';

class AppRouter {
  ///---> when user open app [RouterNotifier] listen the changes on states of [AuthBloc]
  /// for handle what route redirect to user
  final RouterNotifier routerNotifier;

  static final platform = sl<PlatformInfo>();
  AppRouter({required this.routerNotifier});

  GoRouter router() => GoRouter(
      initialLocation: '/',
      refreshListenable: routerNotifier,
      routes: [
//!-------------------------------------- GLOBAL ROUTES -------------------------------------
        GoRoute(
          path: '/',
          builder: (context, state) => const SplashScreen(),
        ),

        //--- SIGN IN
        GoRoute(
            path: '/${SignInScreen.routeName}',
            name: SignInScreen.routeName,
            builder: (context, state) => SignInScreen()),
        //----- SIGN UP
        GoRoute(
            path: '/${SignUpScreen.routeName}',
            name: SignUpScreen.routeName,
            builder: (context, state) => SignUpScreen()),

        //---- reset password account
        GoRoute(
          path: '/${SendRequestResetPaswScreen.routeName}',
          name: SendRequestResetPaswScreen.routeName,
          builder: (context, state) => SendRequestResetPaswScreen(),
        ),

        //--- Settings
        GoRoute(
            path: '/${SettingsScreen.routeName}',
            name: SettingsScreen.routeName,
            builder: (context, state) => SettingsScreen()),

//! ------------------------------------------ ADMIN ---------------------------------
        GoRoute(
            path: '/${CompanyRegistrationScreen.routeName}',
            name: CompanyRegistrationScreen.routeName,
            builder: (context, state) => CompanyRegistrationScreen()),

        GoRoute(
            path: '/${AdminDashboardScreen.routeName}',
            name: AdminDashboardScreen.routeName,
            builder: (context, state) => AdminDashboardScreen()),

        GoRoute(
          path: "/${EmployeeRegistrationScreen.routeName}",
          name: EmployeeRegistrationScreen.routeName,
          builder: (context, state) => EmployeeRegistrationScreen(),
        ),
//! ------------------------------------- EMPLOYEE ---------------------------
        GoRoute(
            path: '/${EmployeMobileScreen.routeName}/:page',
            name: EmployeMobileScreen.routeName,
            builder: (context, state) {
              final index =
                  int.tryParse(state.pathParameters['page'] ?? '0') ?? 0;
              return EmployeMobileScreen(currentIndex: index);
            }),

        GoRoute(
            path: '/${WelcomeScreen.routeName}',
            name: WelcomeScreen.routeName,
            builder: (context, state) => const WelcomeScreen()),

        GoRoute(
            path: '/${EmployeeWebScreen.routeName}',
            name: EmployeeWebScreen.routeName,
            builder: (context, state) => const EmployeeWebScreen()),

        GoRoute(
            path: "/${CreateEventScreen.routeName}",
            name: CreateEventScreen.routeName,
            builder: (context, state) => CreateEventScreen()),
      ],
//
      redirect: (context, state) {
        final comesFrom = state.matchedLocation;
        final authState = routerNotifier.authState;

        print(
            'ROUTER APP comesFrom **************************************** $comesFrom');

        if (authState is AuthInitialState) {
          return '/';
        }

        //! UNAUTHENTICATED OR FAILURE
        if (authState is SignInFailedState ||
            authState is SignUpFailedState ||
            authState is ResetPasswordFailedState ||
            authState is GetAuthenticatedUserFailedState) {
          if (comesFrom.contains('/signIn') ||
              comesFrom.contains('/signUp') ||
              comesFrom.contains('/SendRequestResetPasw')) {
            return null;
          }
          // If it's not on those platforms, we'll redirect you depending on the platform.
          return platform.isWeb ? '/signIn' : '/welcome';
        }

        if (authState is AuthRequestState) {
          if (comesFrom.contains('/${SignUpScreen.routeName}')) {
            return '/${SignUpScreen.routeName}';
          }
        }

        if (authState is SignOutState) {
          return '/${SignInScreen.routeName}';
        }
//
        //**** */ HANDLER ROLES
        switch (authState) {
          case AuthOnboardingState():
            if (comesFrom.contains("/${CompanyRegistrationScreen.routeName}")) {
              return null;
            }
            return '/${CompanyRegistrationScreen.routeName}';

          //! -- ADMIN
          case AuthAdminWebSuccessState() || AuthAdminMobileSuccessState():
            if (comesFrom.contains("/${AdminDashboardScreen.routeName}") ||
                comesFrom.contains("/${SettingsScreen.routeName}") ||
                comesFrom
                    .contains("/${EmployeeRegistrationScreen.routeName}")) {
              return null;
            }
            return '/${AdminDashboardScreen.routeName}';

          //!-- EMPLOYEE
          case AuthEmployeeMobileState():
            //
            if (comesFrom.contains("/${EmployeMobileScreen.routeName}") ||
                comesFrom.contains("/${SettingsScreen.routeName}") ||
                comesFrom.contains("/${CreateEventScreen.routeName}")) {
              return null;
            }
            return '/${EmployeMobileScreen.routeName}/0';

          case AuthEmployeeWebRestrictedState():
            return '/${EmployeeWebScreen.routeName}';

          default:
            return null;
        }
      });
}
