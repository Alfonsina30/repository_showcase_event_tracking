abstract class PermissionsService {
  
//  NOTIFICATION
  Future<String> checkPermissionNotification();
  Future<bool> requestPermissionNotification();

  //  LOCATION (Software Permission)
  Future<String> checkPermissionLocation();
  Future<String> requestLocationPermission();

//--- HARDWARE SERVICE (GPS) 
  Future<bool> isGpsServiceActive(); // all active GPS satellite and network services
  Future<bool>
      requestGpsServiceActivation(); // Muestra el diálogo nativo "Activar GPS"

  //Sistem
  Future<void> openSettings();
}
