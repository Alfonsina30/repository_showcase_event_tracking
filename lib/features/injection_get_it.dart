import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
//
import 'package:focushabit/core/cores_files.dart';
import 'package:focushabit/features/auth/feature_auth_files.dart';
import 'package:focushabit/features/location/location_files.dart';
import 'package:focushabit/features/event/event_feature_files.dart';
import '../features/event_types/event_types_feature_files.dart';
import '../features/company/company_feature_files.dart';

final sl = GetIt.instance;

Future<void> init(SharedPreferences sharedPrefence) async {
  //
  final Environment enviroment = Environment.instance;
//
//!---- WEB + ANDROID
//---->> Service

  final platformInfo = PlatformInfoImpl();
  sl.registerSingleton<PlatformInfo>(platformInfo);
  sl.registerLazySingleton<FacebookAuth>(() => FacebookAuth.instance);

  //
  sl.registerLazySingleton<FlutterSecureStorage>(() => FlutterSecureStorage(
        webOptions: WebOptions(
          dbName: enviroment.eventSecretDbStorage,
          publicKey: enviroment.publicKeySecureStorage,
        ),
      ));

  final secureAuth = SecureStorageServiceImpl(
      secureStorage: sl<FlutterSecureStorage>(),
      key: enviroment.authTokenStore);

  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);

  sl.registerLazySingleton<SharedPreferences>(() => sharedPrefence);

  sl.registerLazySingleton<SharedPreferenceServiceImpl>(
    () =>
        SharedPreferenceServiceImpl(sharedPreferences: sl<SharedPreferences>()),
  );

  //!---******************************************  Connectivity
  sl.registerLazySingleton<ConnectivityDatasource>(() =>
      ConnectivityDatasourceImpl(
          servicePlatformName: AppChannelName.servicePlatformName,
          eventChannelConnection: AppChannelName.eventChannelConnection,
          platformInfo: sl<PlatformInfo>()));

  sl.registerLazySingleton<ConnectivityRepository>(() =>
      ConnectivityRepositoryImpl(
          connectivityDatasource: sl<ConnectivityDatasource>()));

  //! -------------------  Terms condition
  sl.registerLazySingleton<TermConditionDatasource>(
      () => TermConditionDatasourceImpl(
            flutterSecureStorage: SecureStorageServiceImpl(
                secureStorage: sl<FlutterSecureStorage>(),
                key: enviroment.secureTermCondition),
          ));

  //!---****************************************** Auth
  //--DATASOURCES
  sl.registerLazySingleton<AuthRemoteDatasource>(() => AuthRemoteDatasourceImpl(
      firebaseAuth: sl<FirebaseAuth>(),
      googleSignIn: sl<GoogleSignIn>(),
      facebookAuth: sl<FacebookAuth>()));

  //-- REPOSITORY
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryimpl(
        authLocalDatasource: sl<AuthLocalDatasource>(),
        authRemoteDatasource: sl<AuthRemoteDatasource>(),
        //
        termConditionStorage: sl<TermConditionDatasource>(),
        platformInfo: sl<PlatformInfo>(),
        connectivityRepository: sl<ConnectivityRepository>(),
      ));
  //------ USE CASE
  sl.registerLazySingleton<SyncAuthTokenUseCase>(
      () => SyncAuthTokenUseCase(authRepository: sl<AuthRepository>()));
  sl.registerLazySingleton<CreateUserEmailPasswordCase>(
      () => CreateUserEmailPasswordCase(authRepository: sl<AuthRepository>()));
  sl.registerLazySingleton<AuthenticateWithGoogleCase>(
      () => AuthenticateWithGoogleCase(authRepository: sl<AuthRepository>()));
  sl.registerLazySingleton<AuthenticateWithFacebookCase>(
      () => AuthenticateWithFacebookCase(authRepository: sl<AuthRepository>()));
  sl.registerLazySingleton<SignInOnlyWithEmailPasswordCase>(() =>
      SignInOnlyWithEmailPasswordCase(authRepository: sl<AuthRepository>()));
  sl.registerLazySingleton<SendEmailCodeResetPasswordCase>(() =>
      SendEmailCodeResetPasswordCase(authRepository: sl<AuthRepository>()));
  sl.registerLazySingleton<GetAuthenticatedUserCase>(
      () => GetAuthenticatedUserCase(authRepository: sl<AuthRepository>()));
  sl.registerLazySingleton<HandleLogoutCase>(
      () => HandleLogoutCase(authRepository: sl<AuthRepository>()));

//!--- locale language
  sl.registerLazySingleton<LocaleAppDatasource>(
    () => LocaleAppDatasourceImpl(sharedPreferences: sl<SharedPreferences>()),
  );

  sl.registerLazySingleton<LocaleAppDatasourceRepository>(() =>
      LocaleAppDatasourceRepositoryImpl(
          localeAppDatasource: sl<LocaleAppDatasource>()));

  sl.registerLazySingleton<WriteLocalePreferenceUseCase>(() =>
      WriteLocalePreferenceUseCase(
          localeDatasourceRepository: sl<LocaleAppDatasourceRepository>()));

  sl.registerLazySingleton<ReadLocalePreferenceUseCase>(() =>
      ReadLocalePreferenceUseCase(
          localeDatasourceRepository: sl<LocaleAppDatasourceRepository>()));

//!-- CONNECTIVITY
  sl.registerLazySingleton<OnConnectionStatusChangeCase>(() =>
      OnConnectionStatusChangeCase(
          connectivityRepository: sl<ConnectivityRepository>()));

  sl.registerLazySingleton<HasInternetCase>(() =>
      HasInternetCase(connectivityRepository: sl<ConnectivityRepository>()));

  //!-- categories
  sl.registerLazySingleton<EventTypesDatasourceRepository>(() =>
      EventTypesDatasourceRepositoryImpl(
          eventTypesDatasource: sl<EventTypesDatasource>()));

  sl.registerLazySingleton<SetupNewUserUseCase>(() => SetupNewUserUseCase(
      eventTypesDatasourceRepository: sl<EventTypesDatasourceRepository>()));

//!--LocationSearch
  sl.registerLazySingleton<LocationSearchService>(
      () => LocationSearchServiceImpl(client: http.Client()));

  sl.registerLazySingleton<LocationSearchRepository>(() =>
      LocationSearchRepositoryImpl(
          locationSearchService: sl<LocationSearchService>()));

  sl.registerLazySingleton<LocationSearchUseCase>(() => LocationSearchUseCase(
      locationSearchRepository: sl<LocationSearchRepository>(),
      connectivityRepository: sl<ConnectivityRepository>()));

//!--- COMPANY
  sl.registerLazySingleton<CompanyRegistrationDatasource>(
      () => CompanyRegistrationDatasourceImpl());
  //
  sl.registerLazySingleton<CompanyRegistrationRepository>(() =>
      CompanyRegistrationRepositoryImpl(
          companyRegistrationDatasource: sl<CompanyRegistrationDatasource>()));
  //
  sl.registerLazySingleton<CompanyRegistrationCase>(() =>
      CompanyRegistrationCase(
          companyRegistrationRepository: sl<CompanyRegistrationRepository>(),
          authRepository: sl<AuthRepository>(),
          connectivityRepository: sl<ConnectivityRepository>()));

  sl.registerLazySingleton<EmployeeRegistrationDatasource>(
      () => EmployeeRegistrationDatasourceImpl());

  sl.registerLazySingleton<EmployeeRegistrationDatasourceRepository>(() =>
      EmployeeRegistrationDatasourceRepositoryImpl(
          registerEmployeeDatasource: sl<EmployeeRegistrationDatasource>()));

  sl.registerLazySingleton<EmployeeRegistrationUseCase>(() =>
      EmployeeRegistrationUseCase(
          registerEmployeeDatasourceRepository:
              sl<EmployeeRegistrationDatasourceRepository>(),
          connectivityRepository: sl<ConnectivityRepository>(),
          authRepository: sl<AuthRepository>()));

  //
  //! ***************************** ************************************************************************************ */
//! --------------------------------------------------------- WEB -----------------------------------
  if (sl<PlatformInfo>().isWeb) {
    sl.registerLazySingleton<GoogleSignIn>(
        () => GoogleSignIn(clientId: enviroment.googleClientId));

    sl.registerLazySingleton<AuthLocalDatasource>(
        () => AuthLocalDatasourceWebImpl(secureStorageService: secureAuth));

    sl.registerLazySingleton<EventTypesDatasource>(
        () => EventTypesWebDatasource());
  }
//!------------------------------------------------------------ ANDROID  -------------------------------
  else {
    sl.registerLazySingleton<GoogleSignIn>(() => GoogleSignIn(
            clientId: enviroment.googleClientId,
            serverClientId: enviroment.webClientFirebaseGoogle,
            scopes: [
              'email',
              'profile',
              'openid',
            ]));

//! formatter service
   /*
   sl.registerLazySingleton(() => NativeLocationFormatterServiceRepository(
        methodChannel: AppChannelName.servicePlatformName,
        connectivityRepository: sl<ConnectivityRepository>()));
*/

 //! formatter
sl.registerLazySingleton<NativeLocationFormatterService>(() =>
    NativeLocationFormatterServiceImpl(
        methodChannel: AppChannelName.servicePlatformName));

sl.registerLazySingleton<NativeLocationFormatterServiceRepository>(() =>
    NativeLocationFormatterServiceRepositoryImpl(
        nativeLocationFormatterService: sl<NativeLocationFormatterService>(),
        connectivityRepository: sl<ConnectivityRepository>()));

//! Datasource
    sl.registerLazySingleton<AuthLocalDatasource>(() =>
        AuthLocalMobileDatasourceImpl(
            methodChannel: AppChannelName.channelUser,
            secureStorageService: secureAuth));

//!- ALL PERMISSIONS APP ---- SERVICE

    sl.registerLazySingleton<PermissionsServiceRepository>(() =>
        PermissionsServiceRepositoryImpl(
            appPermissions: PermissionsServiceImpl(
                locationPermissionChannel:
                    AppChannelName.locationPermissionChannel,
                appPermissionChannel:
                    AppChannelName.notificationPermissionChannel,
                gpsChannel: AppChannelName.channelGps)));

//--  Permission App
    sl.registerLazySingleton<CheckPermissionLocationCase>(
        () => CheckPermissionLocationCase(appPermissionsRepository: sl()));
    sl.registerLazySingleton<CheckPermissionNotificationCase>(
        () => CheckPermissionNotificationCase(appPermissionsRepository: sl()));
    sl.registerLazySingleton<RequestPermissionNotificationCase>(() =>
        RequestPermissionNotificationCase(appPermissionsRepository: sl()));

    sl.registerLazySingleton<RequestLocationPermissionCase>(
        () => RequestLocationPermissionCase(appPermissionsRepository: sl()));

    sl.registerLazySingleton<OpenDeviceSettingsCase>(
        () => OpenDeviceSettingsCase(appPermissionsRepository: sl()));

//-GPS LOCATION
    sl.registerLazySingleton<IsGpsActiveCase>(() => IsGpsActiveCase(
        appPermissionsRepository: sl<PermissionsServiceRepository>()));

    //!-- LOCATION
    sl.registerLazySingleton<LocationDatasource>(() => LocationDatasourceImpl(
        methodChannel: AppChannelName.channelLocation,
        eventChannel: AppChannelName.eventChannelLocation));

    sl.registerLazySingleton<GpsLocationService>(
        () => GpsLocationServiceImpl(methodChannel: AppChannelName.channelGps));

    sl.registerLazySingleton<LocationRepository>(() => LocationRepositoryImpl(
        gpsLocationService: sl<GpsLocationService>(),
        locationDatasource: sl<LocationDatasource>()));

    sl.registerLazySingleton<RequestGpsActivationCase>(
        () => RequestGpsActivationCase(
              appPermissionsServicePlatform: sl<PermissionsServiceRepository>(),
            ));

  /*
  sl.registerLazySingleton<SetupCurrentLocationUseCase>(() =>
        SetupCurrentLocationUseCase(
            appPermissionsServicePlatformRepository:
                sl<PermissionsServiceRepository>(),
            locationRepository: sl<LocationRepository>()));

    */
    sl.registerLazySingleton<SetupCurrentLocationUseCase>(() =>
    SetupCurrentLocationUseCase(
        appPermissionsServicePlatformRepository:
            sl<PermissionsServiceRepository>(),
        locationRepository: sl<LocationRepository>(),
        nativeLocationFormatterRepository:
            sl<NativeLocationFormatterServiceRepository>()));

    sl.registerLazySingleton<DeleteLocationHistoryCase>(() =>
        DeleteLocationHistoryCase(
            locationDatasourceRepository: sl<LocationRepository>()));
    sl.registerLazySingleton<GetLocationHistoryByUserIdCase>(() =>
        GetLocationHistoryByUserIdCase(
            locationDatasourceRepository: sl<LocationRepository>()));
    sl.registerLazySingleton<StreamLocationHistoryChangedCase>(() =>
        StreamLocationHistoryChangedCase(
            locationDatasourceRepository: sl<LocationRepository>()));
    sl.registerLazySingleton<AddLocationToHistoryCase>(() =>
        AddLocationToHistoryCase(
            locationDatasourceRepository: sl<LocationRepository>()));
    //

//!---- CATEGORIES FOR MOBILE
    sl.registerLazySingleton<EventTypesDatasource>(() =>
        EventTypesMobileDatasouceImpl(
            methodChannel: AppChannelName.channelEventsTypes));

    sl.registerLazySingleton<GetEventsTypesByUserCase>(
        () => GetEventsTypesByUserCase(eventsTypesDatasourceRepository: sl()));
    sl.registerLazySingleton<DeleteEventTypeCase>(
        () => DeleteEventTypeCase(eventTypeDatasourceRepository: sl()));
    sl.registerLazySingleton<UpdateEventTypeCase>(
        () => UpdateEventTypeCase(eventsTypesDatasourceRepository: sl()));
    sl.registerLazySingleton<InsertEventTypeCase>(
        () => InsertEventTypeCase(eventsTypesDatasourceRepository: sl()));

//!-------------------------------- EVENT
    sl.registerLazySingleton<EventDatasource>(() => EventDatasourceImpl(
        methodChannel: AppChannelName.channelEvent,
        eventChannel: AppChannelName.eventChannelEventChanged));

    sl.registerLazySingleton<EventHistoryDatasource>(() =>
        EventHistoryDatasourceImpl(
            methodChannel: AppChannelName.channelEventHistory,
            eventChannel: AppChannelName.eventChannelEventHistory));

    //-REPOSITORY
    sl.registerLazySingleton<EventDatasourceRepository>(() =>
        EventDatasourceRepositoryImpl(eventDatasource: sl<EventDatasource>()));

    //--- WORKER REPOSITORY
    sl.registerLazySingleton<EventWorkerRepository>(() =>
        EventWorkManagerRepositoryImpl(
            eventWorker:
                EventWorker(methodChannel: AppChannelName.workerChannerl)));

    sl.registerLazySingleton<EventHistoryDatasourceRepository>(() =>
        EventHistoryDatasourceRepositoryImpl(
            eventHistoryDatasource: sl<EventHistoryDatasource>()));

//--- History use case
    sl.registerLazySingleton<InsertEventHistoryCase>(() =>
        InsertEventHistoryCase(
            eventHistoryDatasourceRepository:
                sl<EventHistoryDatasourceRepository>()));
    sl.registerLazySingleton<GetEventHistoryUseCase>(() =>
        GetEventHistoryUseCase(
            eventHistoryDatasourceRepository:
                sl<EventHistoryDatasourceRepository>()));
    sl.registerLazySingleton<DeleteEventHistoryUseCase>(() =>
        DeleteEventHistoryUseCase(
            eventHistoryDatasourceRepository:
                sl<EventHistoryDatasourceRepository>()));

    sl.registerLazySingleton<GetEventHistoryChangedUseCase>(() =>
        GetEventHistoryChangedUseCase(
            eventHistoryRepository: sl<EventHistoryDatasourceRepository>()));

//-- Datasource use case
    sl.registerLazySingleton(() => UnCompletedEventCase(
        eventRepository: sl<EventDatasourceRepository>(),
        eventHistoryRepository: sl<EventHistoryDatasourceRepository>()));

    sl.registerLazySingleton<MarkEventCompletedUseCase>(() =>
        MarkEventCompletedUseCase(
            appPermissionsServicePlatformRepository:
                sl<PermissionsServiceRepository>(),
            locationRepository: sl<LocationRepository>(),
            taskHistoryRepository: sl<EventHistoryDatasourceRepository>(),
            taskRepository: sl<EventDatasourceRepository>()));
    sl.registerLazySingleton<QueryEventCase>(
        () => QueryEventCase(eventDatasourceRepository: sl()));
    sl.registerLazySingleton<InsertEventCase>(() => InsertEventCase(
        addLocationToHistoryCase: AddLocationToHistoryCase(
            locationDatasourceRepository: sl<LocationRepository>()),
        appPermissionsPlatformRepository: sl<PermissionsServiceRepository>(),
        eventDatasourceRepository: sl()));
    sl.registerLazySingleton<UpdateTaskCase>(() => UpdateTaskCase(
        addLocationToHistoryCase: sl<AddLocationToHistoryCase>(),
        appPermissionsPlatformRepository: sl<PermissionsServiceRepository>(),
        eventDatasourceRepository: sl()));
    sl.registerLazySingleton<DeleteEventCase>(() => DeleteEventCase(
        eventHistoryDatasourceRepository:
            sl<EventHistoryDatasourceRepository>(),
        eventDatasourceRepository: sl()));
    sl.registerLazySingleton<GetEventChangedUseCase>(() =>
        GetEventChangedUseCase(
            eventDatasourceRepository: sl<EventDatasourceRepository>()));

//---  WORKER
    sl.registerLazySingleton<EventWorkerStatusStreamUseCase>(() =>
        EventWorkerStatusStreamUseCase(
            eventWorkerRepository: sl<EventWorkerRepository>()));

    sl.registerLazySingleton<ScheduleEventWorkerUseCase>(() =>
        ScheduleEventWorkerUseCase(
            eventWorkerRepository: sl<EventWorkerRepository>()));
  }
}
