import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focushabit/core/cores_files.dart' show Either;
import 'package:focushabit/features/company/admin/admin_files.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../shared/shared_mocks.dart';
import '../../../../shared/test_case.dart';

void main() {
  late MockCompanyRegistrationUseCase mockCompanyRegistrationUseCase;

  setUp(() {
    mockCompanyRegistrationUseCase = MockCompanyRegistrationUseCase();
  });

  group('Company Registration Cubit Tests', () {
    const tCompany = "test_co";
    final currentState = CompanyRegistrationState.initialState()
        .copyWith(companyName: InputCompanyId.dirty(companyName: tCompany));

//! SUCCESS
    blocTest(
      'emits[loading, ${CompanyStatus.success.name}] when a new company is registered successfully',
      build: () => CompanyRegistrationCubit(
          companyRegistrationCase: mockCompanyRegistrationUseCase),
      //GIVEN
      setUp: () {
        when(() =>
            mockCompanyRegistrationUseCase.companyRegistration(
                companyName: any(named: "companyName"))).thenAnswer(
            (_) async => Either.success(CompanyEntity(companyId: "col5864")));
      },
      //WHEN
      act: (bloc) => bloc.companyRegistration(),
      seed: () => currentState,
      // THEN
      expect: () => [
        currentState.copyWith(isLoading: true),
        //
        CompanyRegistrationState.initialState()
            .copyWith(companyStatus: CompanyStatus.success)
      ],
      verify: (_) {
        verify(() => mockCompanyRegistrationUseCase.companyRegistration(
            companyName: any(named: "companyName"))).called(1);
      },
    );
    //

    //! ---------------------------------------------------------- FAILURE  ----------------------------------------------------------------
    //! ---------------------------------------------------------- FAILURE  ----------------------------------------------------------------
    final testsFailures = [
      UnitTestCase(
          description:
              'emits[loading, ${CompanyStatus.invalidArgument.name}] when company name is empty',
          value: CompanyStatus.invalidArgument),
      UnitTestCase(
          description:
              'emits[loading, ${CompanyStatus.expiredToken.name}] when token is invalid or expired',
          value: CompanyStatus.expiredToken),
      UnitTestCase(
          description:
              'emits[loading, ${CompanyStatus.serverException.name}] when server encounters an internal exception',
          value: CompanyStatus.serverException),
      UnitTestCase(
          description:
              'emits[loading, ${CompanyStatus.offlineServerRequest.name}] when device is offline',
          value: CompanyStatus.offlineServerRequest),
    ];

    for (var element in testsFailures) {
      blocTest(
        element.description,
        build: () => CompanyRegistrationCubit(
            companyRegistrationCase: mockCompanyRegistrationUseCase),
        //GIVEN
        setUp: () {
          when(() => mockCompanyRegistrationUseCase.companyRegistration(
                  companyName: any(named: "companyName")))
              .thenAnswer((_) async => Either.failure(element.value));
        },
        //WHEN
        act: (bloc) => bloc.companyRegistration(),
        seed: () => currentState,
        // THEN
        expect: () => [
          currentState.copyWith(isLoading: true),
          //
          currentState.copyWith(companyStatus: element.value, isLoading: false)
        ],
        verify: (_) {
          verify(() => mockCompanyRegistrationUseCase.companyRegistration(
              companyName: any(named: "companyName"))).called(1);
        },
      );
    }
  });
}
