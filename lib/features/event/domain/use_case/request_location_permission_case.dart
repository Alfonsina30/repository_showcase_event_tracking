import 'package:focushabit/core/cores_files.dart';

class RequestGpsServiceActivationCase {
  final PermissionsServiceRepository _appPermissionsRepository;

  const RequestGpsServiceActivationCase(
      {required PermissionsServiceRepository appPermissionsRepository})
      : _appPermissionsRepository = appPermissionsRepository;

  Future<Either<PermissionsServiceEntity, PermissionServiceStatus>>
      requestGpsService() async {
    return await _appPermissionsRepository.requestGpsServiceActivation();
  }
}
