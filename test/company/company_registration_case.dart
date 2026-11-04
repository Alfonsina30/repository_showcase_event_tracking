import 'package:flutter_test/flutter_test.dart';
import 'package:focushabit/core/entity/either.dart';
import 'package:focushabit/features/company/admin/admin_files.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../shared/shared_mocks.dart';
import '../../../../shared/test_case.dart';

void main() {
  late CompanyRegistrationCase companyRegistrationCase;
  late MockCompanyRegistrationRepository mockCompanyRegistrationRepository;
  late MockConnectivityRepository mockConnectivityRepository;

  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockCompanyRegistrationRepository = MockCompanyRegistrationRepository();
    mockConnectivityRepository = MockConnectivityRepository();

    mockAuthRepository = MockAuthRepository();

    companyRegistrationCase = CompanyRegistrationCase(
        companyRegistrationRepository: mockCompanyRegistrationRepository,
        connectivityRepository: mockConnectivityRepository,
        authRepository: mockAuthRepository);
  });

  group('Company registration use case', () {
    const testToken = "ajskd263";
    const testCompanyName = "test_co";

//! Either.success(CompanyEntity)
    test(
        'returns CompanyEntity when connectivity is online, company name argument is not empty or null and admin token is not empty ',
        () async {
      when(() => mockConnectivityRepository.hasInternet())
          .thenAnswer((_) async => true);
      when(() => mockAuthRepository.getIdToken())
          .thenAnswer((_) async => Either.success(testToken));
      when(() => mockCompanyRegistrationRepository.companyRegistration(
              companyName: any(named: "companyName"),
              tokenAdmin: any(named: "tokenAdmin")))
          .thenAnswer(
              (_) async => Either.success(CompanyEntity(companyId: "col5864")));

      final Either<CompanyEntity, CompanyStatus> result =
          await companyRegistrationCase.companyRegistration(
              companyName: testCompanyName);
      //
      expect(
          result,
          isA<Either<CompanyEntity, CompanyStatus>>().having(
              (feature) => feature.success, 'success', isA<CompanyEntity>()));

      verify(() => mockConnectivityRepository.hasInternet()).called(1);
      verify(() => mockAuthRepository.getIdToken()).called(1);
      verify(() => mockCompanyRegistrationRepository.companyRegistration(
          companyName: any(named: "companyName"),
          tokenAdmin: any(named: "tokenAdmin"))).called(1);
    });

    //! Either.failure(CompanyStatus.offline)
    test(
        'returns CompanyStatus.offline when connectivity companyStatus is offline',
        () async {
      //
      when(() => mockConnectivityRepository.hasInternet())
          .thenAnswer((_) async => false);

      final Either<CompanyEntity, CompanyStatus> result =
          await companyRegistrationCase.companyRegistration(
              companyName: testCompanyName);

      expect(
          result,
          isA<Either<CompanyEntity, CompanyStatus>>().having(
              (feature) => feature.failure,
              'failure',
              CompanyStatus.offlineServerRequest));

      verifyNever(() => mockAuthRepository.getIdToken());
      verifyNever(() => mockCompanyRegistrationRepository.companyRegistration(
          companyName: any(named: "companyName"),
          tokenAdmin: any(named: "tokenAdmin")));
    });
    //

    //! Either.failure(CompanyStatus.invalidArgument)
    test(
        'returns CompanyStatus.invalidArgument when use case receives an empty company name',
        () async {
      //
      when(() => mockConnectivityRepository.hasInternet())
          .thenAnswer((_) async => true);

      final Either<CompanyEntity, CompanyStatus> result =
          await companyRegistrationCase.companyRegistration(companyName: '');

      expect(
          result,
          isA<Either<CompanyEntity, CompanyStatus>>().having(
              (feature) => feature.failure,
              'failure',
              CompanyStatus.invalidArgument));

      verify(() => mockConnectivityRepository.hasInternet()).called(1);
      verifyNever(() => mockAuthRepository.getIdToken());
      verifyNever(() => mockCompanyRegistrationRepository.companyRegistration(
          companyName: any(named: "companyName"),
          tokenAdmin: any(named: "tokenAdmin")));
    });
    //

//! Either.failure(CompanyStatus.expiredToken)
    test(
        'returns CompanyStatus.expiredToken when secure storage or Firebase returns nulls',
        () async {
      //--> GIVEN
      when(() => mockConnectivityRepository.hasInternet())
          .thenAnswer((_) async => true);

      when(() => mockAuthRepository.getIdToken())
          .thenAnswer((_) async => Either.success(null));

      //-- WHEN
      final Either<CompanyEntity, CompanyStatus> result =
          await companyRegistrationCase.companyRegistration(
              companyName: testCompanyName);

      //--> THEN
      expect(
          result,
          isA<Either<CompanyEntity, CompanyStatus>>().having(
              (feature) => feature.failure,
              'failure',
              CompanyStatus.expiredToken));

      verify(() => mockConnectivityRepository.hasInternet()).called(1);
      verify(() => mockAuthRepository.getIdToken()).called(1);

      verifyNever(() => mockCompanyRegistrationRepository.companyRegistration(
          companyName: any(named: "companyName"),
          tokenAdmin: any(named: "tokenAdmin")));
    });

    //! ------------------------------------------------------ Error caught in catch block -------------------------------------

    final testsFailures = [
      UnitTestCase<CompanyStatus>(
          description:
              'returns ${CompanyStatus.invalidArgument} when the server receives an empty company name',
          value: CompanyStatus.invalidArgument),
      UnitTestCase<CompanyStatus>(
          description:
              'returns ${CompanyStatus.expiredToken} when the server receives an invalid or expired token',
          value: CompanyStatus.expiredToken),
      UnitTestCase(
          description:
              'returns ${CompanyStatus.serverException} when the server encounters an internal exception',
          value: CompanyStatus.serverException)
    ];

    for (var item in testsFailures) {
      test(item.description, () async {
        //--> GIVEN
        when(() => mockConnectivityRepository.hasInternet())
            .thenAnswer((_) async => true);
        when(() => mockAuthRepository.getIdToken())
            .thenAnswer((_) async => Either.success(testToken));
        when(
          () => mockCompanyRegistrationRepository.companyRegistration(
              companyName: any(named: "companyName"),
              tokenAdmin: any(named: "tokenAdmin")),
        ).thenAnswer((_) async => Either.failure(item.value));

        //--> WHEN
        final result = await companyRegistrationCase.companyRegistration(
            companyName: testCompanyName);

        //--> THEN
        expect(
            result,
            isA<Either<CompanyEntity, CompanyStatus>>().having(
                (feature) => feature.failure, 'companyStatus', item.value));

        verify(() => mockConnectivityRepository.hasInternet()).called(1);
        verify(() => mockAuthRepository.getIdToken()).called(1);
        verify(() => mockCompanyRegistrationRepository.companyRegistration(
            companyName: any(named: "companyName"),
            tokenAdmin: any(named: "tokenAdmin"))).called(1);
      });
    }
    //
  });
}
