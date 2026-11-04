import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:focushabit/core/cores_files.dart';
import 'package:focushabit/features/company/admin/admin_files.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import '../../../../shared/shared_mocks.dart';

void main() {
  late CompanyRegistrationDatasource companyRegistrationDatasource;
  late MockHttpCliente mockHttpCliente;
  const baseUrl = "http://10.0.2.2:5001/focus-habit-app/us-central1";
  final uri = Uri.parse("$baseUrl/createCompanyAdmin");

  const mockUid = "ajskd6363";
  const mockCompanyName = "testColab";

  setUp(() {
    mockHttpCliente = MockHttpCliente();

    companyRegistrationDatasource = CompanyRegistrationDatasourceImpl(
        client: mockHttpCliente, baseUrl: baseUrl);
  });

  setUpAll(() {
    registerFallbackValue(Uri());
  });

  group('Company Registration Datasource', () {
    test('returns company ID when company registration is successful',
        () async {
      when(
        () => mockHttpCliente.post(uri,
            headers: any(named: "headers"), body: any(named: "body")),
      ).thenAnswer((_) async => http.Response(
          jsonEncode({
            'data': {'success': true, 'message': mockUid}
          }),
          200));

      final result = await companyRegistrationDatasource.companyRegistration(
          companyName: mockCompanyName, token: mockUid);

      expect(result, mockUid);

      verify(
        () => mockHttpCliente.post(uri,
            headers: any(named: "headers"), body: any(named: "body")),
      ).called(1);
    });
//! ------------------------------------------------- EXCEPTIONS -----------------------------------------------------------

    //! 401
    test(
        'throws ServerException with statusCode 401 when the server receives an invalid or expired token',
        () async {
      when(
        () => mockHttpCliente.post(uri,
            headers: any(named: "headers"), body: any(named: "body")),
      ).thenAnswer((_) async => http.Response(
          jsonEncode({
            "error": {
              "message": "Must be logged in.",
              "status": "UNAUTHENTICATED"
            }
          }),
          401));

      expect(
          () => companyRegistrationDatasource.companyRegistration(
              companyName: mockCompanyName, token: ''),
          throwsA(isA<ServerException>()
              .having((feature) => feature.statusCode, 'statusCode', 401)));

      verify(() => mockHttpCliente.post(uri,
          headers: any(named: "headers"), body: any(named: "body"))).called(1);
    });
    //
//! 400
    test(
        'throws ServerException with statusCode 400 when server receives an empty company name',
        () {
      when(
        () => mockHttpCliente.post(uri,
            headers: any(named: "headers"), body: any(named: "body")),
      ).thenAnswer((_) async => http.Response(
          jsonEncode({
            "error": {
              "message": "Company name is required.",
              "status": "INVALID_ARGUMENT"
            },
          }),
          400));

      expect(
          () => companyRegistrationDatasource.companyRegistration(
              companyName: '', token: mockUid),
          throwsA(isA<ServerException>()
              .having((feature) => feature.statusCode, 'statusCode', 400)));
      verify(() => mockHttpCliente.post(uri,
          headers: any(named: "headers"), body: any(named: "body"))).called(1);
    });

    //! 500
    test(
        'throws ServerException with statusCode 500 when server has an internal error',
        () {
      when(
        () => mockHttpCliente.post(uri,
            headers: any(named: "headers"), body: any(named: "body")),
      ).thenAnswer((_) async => http.Response(
          jsonEncode({
            "error": {
              "message": "Internal server error saving data.",
              "status": "INTERNAL"
            },
          }),
          500));

      expect(
          () => companyRegistrationDatasource.companyRegistration(
              companyName: '', token: ''),
          throwsA(isA<ServerException>()
              .having((feature) => feature.statusCode, 'statusCode', 500)));
      verify(() => mockHttpCliente.post(uri,
          headers: any(named: "headers"), body: any(named: "body"))).called(1);
    });
  });
}
