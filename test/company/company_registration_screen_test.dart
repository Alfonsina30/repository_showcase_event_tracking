import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focushabit/core/cores_files.dart';
import 'package:focushabit/features/auth/presentation/presentation_files.dart';
import 'package:focushabit/features/company/admin/admin_files.dart';
import 'package:focushabit/l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../shared/shared_mocks.dart';
import '../../../../shared/test_case.dart';

void main() {
  //
  late MockCompanyRegistrationUseCase mockCompanyRegistrationUseCase;
  late MockCompanyRegistrationCubit mockCompanyRegistrationCubit;
  late MockAuthBloc mockAuthBloc;
  late AppLocalizations l10n;

  setUp(() {
    mockCompanyRegistrationUseCase = MockCompanyRegistrationUseCase();

    GetIt.I.reset();
    GetIt.I.registerLazySingleton<MockCompanyRegistrationUseCase>(
        () => mockCompanyRegistrationUseCase);
    //
    mockAuthBloc = MockAuthBloc();
    mockCompanyRegistrationCubit = MockCompanyRegistrationCubit();
  });

  //--
  setUpAll(() async {
    registerFallbackValue(GetAuthenticatedUserEvent());
    registerFallbackValue(SignOutEvent());

    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  tearDownAll(() {
    mockCompanyRegistrationCubit.close();
    mockAuthBloc.close();
  });

  Widget createTestWidget(
      {required MockCompanyRegistrationUseCase usecase,
      required MockAuthBloc authBloc,
      required MockCompanyRegistrationCubit cubit}) {
    final mockRouter = GoRouter(
        initialLocation: '/${CompanyRegistrationScreen.routeName}',
        routes: [
          GoRoute(
            path: '/${CompanyRegistrationScreen.routeName}',
            builder: (context, state) => MultiBlocProvider(
              providers: [
                BlocProvider<CompanyRegistrationCubit>.value(value: cubit),
                BlocProvider<AuthBloc>.value(value: authBloc)
              ],
              child: CompanyRegistrationScreen(companyRegistrationCubit: cubit),
            ),
          )
        ]);

    return MaterialApp.router(
      routerConfig: mockRouter,
      locale: Locale('en'),
      supportedLocales: LocaleAppDatasourceImpl.supporteLocales,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate
      ],
    );
  }

  group('Company Registration Screen Tests', () {
    //
    const tCompanyName = "skkfjf526";
    final cubitIntialState = CompanyRegistrationState.initialState();

//! ------- CompanyStatus.success
    testWidgets(
        'Trigger event GetAuthenticatedUserEvent on AuthBloc when company is registered successfully ',
        (wtester) async {
      //-- GIVEN
      when(
        () => mockCompanyRegistrationUseCase.companyRegistration(
            companyName: any(named: "companyName")),
      ).thenAnswer(
          (_) async => Either.success(CompanyEntity(companyId: tCompanyName)));

      //--- WHEN
      whenListen(
        mockCompanyRegistrationCubit,
        initialState: cubitIntialState,
        Stream.fromIterable([
          cubitIntialState.copyWith(
              isLoading: true,
              companyName: InputCompanyId.dirty(companyName: tCompanyName)),
          //
          cubitIntialState.copyWith(
              isLoading: false,
              companyStatus: CompanyStatus.success,
              companyName: InputCompanyId.pure())
        ]),
      );

      await wtester.pumpWidget(createTestWidget(
          authBloc: mockAuthBloc,
          cubit: mockCompanyRegistrationCubit,
          usecase: mockCompanyRegistrationUseCase));

      await wtester.pumpAndSettle();

      expect(find.byType(CompanyRegistrationScreen), findsOneWidget);

      //--- THEN
      verify(() =>
              mockAuthBloc.add(any(that: isA<GetAuthenticatedUserEvent>())))
          .called(1);
    });
    //

//! ---------------- CompanyStatus.expiredToken
    testWidgets(
        'displays a Dialog when company creation fails and status is ${CompanyStatus.expiredToken.name} ',
        (wTester) async {
      //
      when(() => mockCompanyRegistrationUseCase.companyRegistration(
              companyName: any(named: "companyName")))
          .thenAnswer((_) async => Either.failure(CompanyStatus.expiredToken));

      //--- WHEN
      whenListen(
        mockCompanyRegistrationCubit,
        initialState: cubitIntialState,
        Stream.fromIterable([
          cubitIntialState.copyWith(
              isLoading: true,
              companyName: InputCompanyId.dirty(companyName: tCompanyName)),
          //

          cubitIntialState.copyWith(
            isLoading: false,
            companyStatus: CompanyStatus.expiredToken,
          )
        ]),
      );

      await wTester.pumpWidget(createTestWidget(
          authBloc: mockAuthBloc,
          cubit: mockCompanyRegistrationCubit,
          usecase: mockCompanyRegistrationUseCase));

      await wTester.pumpAndSettle();

      expect(find.byType(CompanyRegistrationScreen), findsOneWidget);

      final dialog = find.byType(Dialog);
      expect(dialog, findsOneWidget);

      expect(
          find.descendant(
              of: dialog, matching: find.text(l10n.notifierTokenExpired)),
          findsOneWidget);

      final button = find.byType(FilledButton);
      expect(button, findsOneWidget);
      await wTester.tap(button);

      verify(() => mockAuthBloc.add(any(that: isA<SignOutEvent>()))).called(1);
    });
    //

//!

    final testsSnackBar = [
      WidgetTestCase<CompanyStatus>(
          description:
              'displays a SnackBar when company creation fails and status is ${CompanyStatus.offlineServerRequest.name}',
          value: CompanyStatus.offlineServerRequest,
          text: (AppLocalizations loc) => loc.textDialogOffline),
      WidgetTestCase<CompanyStatus>(
          description:
              'displays a SnackBar when company creation fails and status is ${CompanyStatus.invalidArgument.name}',
          value: CompanyStatus.invalidArgument,
          text: (AppLocalizations loc) => l10n.featureCompanyRegistration),
      WidgetTestCase<CompanyStatus>(
          description:
              'displays a SnackBar when company creation fails and status is ${CompanyStatus.serverException.name}',
          value: CompanyStatus.serverException,
          text: (AppLocalizations loc) => l10n.textDialogException)
    ];
    //

    final iState = CompanyRegistrationState.initialState().copyWith(
        isLoading: true,
        companyName: InputCompanyId.dirty(companyName: tCompanyName));

    for (var element in testsSnackBar) {
      testWidgets(element.description, (wTester) async {
        //
        when(() => mockCompanyRegistrationUseCase.companyRegistration(
                companyName: any(named: "companyName")))
            .thenAnswer((_) async => Either.failure(element.value));

        when(() => mockCompanyRegistrationCubit.state)
            .thenReturn(iState); //-- is important for send the state to cubit

        whenListen(
            mockCompanyRegistrationCubit,
            initialState: cubitIntialState,
            Stream.fromIterable([
              iState,
              //
              cubitIntialState.copyWith(
                  isLoading: false, companyStatus: element.value)
            ]));

        await wTester.pumpWidget(createTestWidget(
            authBloc: mockAuthBloc,
            cubit: mockCompanyRegistrationCubit,
            usecase: mockCompanyRegistrationUseCase));

        await wTester.pumpAndSettle();

        expect(find.byType(CompanyRegistrationScreen), findsOneWidget);
        //
        final snackFinder = find.byType(SnackBar);
        expect(snackFinder, findsOneWidget);
        expect(
            find.descendant(
              of: snackFinder,
              matching: find.text(element.text(l10n)),
            ),
            findsOneWidget);
      });
    }
    //

    testWidgets(
      'invockes companyIdChanged on Cubit when input text changes',
      (wTester) async {
        // GIVEN
        when(() => mockCompanyRegistrationCubit.state)
            .thenReturn(CompanyRegistrationState.initialState());

        await wTester.pumpWidget(createTestWidget(
          authBloc: mockAuthBloc,
          cubit: mockCompanyRegistrationCubit,
          usecase: mockCompanyRegistrationUseCase,
        ));

        //--->  ACT
        final textField = find.byType(CustomTextFormField);
        expect(textField, findsOneWidget);

        const tInput = 'My Company Name';
        await wTester.enterText(textField, tInput);

        //--> ASSERT
        verify(() => mockCompanyRegistrationCubit.companyIdChanged(tInput))
            .called(1);
      },
    );
    //

    testWidgets(
      'displays validation error message when companyName is empty/invalid',
      (wTester) async {
        //  el campo de nombre tiene un error (dirty y vacío)
        final invalidState = CompanyRegistrationState.initialState().copyWith(
          companyName: InputCompanyId.dirty(companyName: ''),
        );

        when(() => mockCompanyRegistrationCubit.state).thenReturn(invalidState);

        // WHEN
        await wTester.pumpWidget(createTestWidget(
          authBloc: mockAuthBloc,
          cubit: mockCompanyRegistrationCubit,
          usecase: mockCompanyRegistrationUseCase,
        ));

        await wTester.pumpAndSettle();

        //--- ASSERT: Verificar que se muestra el mensaje de error traducido
        expect(find.text('The field is required'), findsOneWidget);
      },
    );
  });
}
