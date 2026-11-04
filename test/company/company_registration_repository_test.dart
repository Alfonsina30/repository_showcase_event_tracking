import 'package:flutter_test/flutter_test.dart';
import 'package:focushabit/core/cores_files.dart';
import 'package:focushabit/features/company/company_feature_files.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../shared/shared_mocks.dart';

void main() {
  late CompanyRegistrationRepository companyRegistrationRepository;
  //--MOCKS
  late MockCompanyRegistrationDatasource mockCompanyRegistrationDatasource;

  setUp(() {
    mockCompanyRegistrationDatasource = MockCompanyRegistrationDatasource();

    companyRegistrationRepository = CompanyRegistrationRepositoryImpl(
      companyRegistrationDatasource: mockCompanyRegistrationDatasource,
    );
  });

  group('Tests Company Registration Repository', () {
    const mockToken = "ajskd266";
    const mockCompanyId = 'testColab';

    test('returns CompanyEntity when company registration is successful ',
        () async {
      when(
        () => mockCompanyRegistrationDatasource.companyRegistration(
            companyName: any(named: "companyName"), token: any(named: "token")),
      ).thenAnswer((_) async => mockCompanyId);

//--- repository
      final result = await companyRegistrationRepository.companyRegistration(
          companyName: mockCompanyId, tokenAdmin: mockToken);

      expect(
          result,
          isA<Either<CompanyEntity, CompanyStatus>>()
              .having((e) => e.success, 'entity', isA<CompanyEntity>()));

      verify(
        () => mockCompanyRegistrationDatasource.companyRegistration(
            companyName: any(named: "companyName"), token: any(named: "token")),
      ).called(1);
    });
    //

//! -------------------------------------------------------------- FAILURE ----------------------------------------------------------
//!----------------------------------------------------------------------------------------------------------------------------------
//!-- unauthenticate
    test(
        'returns ${CompanyStatus.expiredToken.name} when it catches a ServerException with statusCode 401 for an invalid or expired token',
        () async {
      when(() => mockCompanyRegistrationDatasource.companyRegistration(
              companyName: any(named: "companyName"),
              token: any(named: "token")))
          .thenThrow(
              ServerException(statusCode: 401, message: 'UNAUTHENTICATED'));

      final result = await companyRegistrationRepository.companyRegistration(
          companyName: mockCompanyId, tokenAdmin: mockToken);

      expect(
          result,
          isA<Either<CompanyEntity, CompanyStatus>>()
              .having((e) => e.isFailure, 'isFailure', true)
              .having(
                  (e) => e.failure, 'status', CompanyStatus.expiredToken));

      verify(() => mockCompanyRegistrationDatasource.companyRegistration(
          companyName: any(named: "companyName"),
          token: any(named: "token"))).called(1);
    });

    //! INVALID ARGUMENTS
    test(
        'returns ${CompanyStatus.invalidArgument.name} when a ServerException with statusCode 400 is thrown due to an empty or invalid company name',
        () async {
      when(() => mockCompanyRegistrationDatasource.companyRegistration(
              companyName: any(named: "companyName"),
              token: any(named: "token")))
          .thenThrow(ServerException(
              statusCode: 400, message: "Company name is required."));

      final result = await companyRegistrationRepository.companyRegistration(
          companyName: '', tokenAdmin: mockToken);

      expect(
          result,
          isA<Either<CompanyEntity, CompanyStatus>>().having(
              (feature) => feature.failure,
              'status',
              CompanyStatus.invalidArgument));

      verify(() => mockCompanyRegistrationDatasource.companyRegistration(
          companyName: any(named: "companyName"), token: any(named: "token")));
    });

    //! SERVER EXCEPTION
    test(
        'returns ${CompanyStatus.serverException.name} when a ServerException with statusCode 500 is thrown',
        () async {
      when(
        () => mockCompanyRegistrationDatasource.companyRegistration(
            companyName: any(named: "companyName"), token: any(named: "token")),
      ).thenThrow(ServerException(
          statusCode: 500, message: "Internal server error saving data."));

      final result = await companyRegistrationRepository.companyRegistration(
          companyName: mockCompanyId, tokenAdmin: mockToken);

      expect(
          result,
          isA<Either<CompanyEntity, CompanyStatus>>().having(
              (feature) => feature.failure,
              'status',
              CompanyStatus.serverException));

      verify(() => mockCompanyRegistrationDatasource.companyRegistration(
          companyName: any(named: "companyName"),
          token: any(named: "token"))).called(1);
    });
  });
}
