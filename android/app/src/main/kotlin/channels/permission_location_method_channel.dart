package com.alfonsinabeltre.focushabit.permission_app.location

import android.Manifest
import android.content.Context
import android.util.Log
import androidx.core.app.ActivityCompat
import com.alfonsinabeltre.focushabit.MainActivity
import com.alfonsinabeltre.focushabit.permission_app.CustomCheckPermission
import com.alfonsinabeltre.focushabit.shared.OpenSettingsDevice
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler

class PermissionLocationMethodChannel(
    binnary : BinaryMessenger,
    channelName : String,
    private val context: Context,
    private val activity: MainActivity,) {

    private val methodChannel = MethodChannel(binnary, channelName)
    private val tag = "LocationMethodChannel"

init {
    methodChannel.setMethodCallHandler(LocationCallHandler())
}
companion object{
     val permissionLocation = Manifest.permission.ACCESS_FINE_LOCATION
     var pendingResultLocation : MethodChannel.Result? = null;
     val requestCodeLocation = 100

}
    private inner class LocationCallHandler : MethodCallHandler {

        override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
           when(call.method){

               "checkPermissionLocation" -> {
                   val permissionIsGranted : String =
                       CustomCheckPermission.customCheckPermissionApp(context, permissionLocation, activity)
                   Log.d(tag,"✅checkPermissionLocation permissionIsGranted✅ $permissionIsGranted")

                   result.success(permissionIsGranted)
               }

               "requestLocationPermission"-> {
                   pendingResultLocation = result
                   Log.d(tag,"✅requestLocationPermission pendingResultLocation✅ $pendingResultLocation")

                   CustomCheckPermission.markPermissionAsRequested(context, permissionLocation)

                   ActivityCompat.requestPermissions(
                       activity,
                       arrayOf(permissionLocation),
                       requestCodeLocation
                   )
               }

               "openSettings"-> {
                   OpenSettingsDevice(context).openSettingsForApp()
               }
           }
        }


    }

}
