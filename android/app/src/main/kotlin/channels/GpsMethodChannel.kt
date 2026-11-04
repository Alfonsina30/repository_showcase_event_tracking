package com.alfonsinabeltre.focushabit.services

import android.Manifest
import android.content.Context
import android.content.IntentSender
import android.content.pm.PackageManager
import android.location.LocationManager
import android.util.Log
import androidx.core.app.ActivityCompat
import com.alfonsinabeltre.focushabit.MainActivity
import com.google.android.gms.common.api.ResolvableApiException
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.LocationSettingsRequest
import com.google.android.gms.location.LocationSettingsResponse
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.Priority

import com.google.android.gms.location.SettingsClient
import com.google.android.gms.tasks.Task
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler

class GpsMethodChannel(
    private val gpsChannelName : String,
    private val binnary : BinaryMessenger,
    private val context : Context,
    private val activity : MainActivity
    ) {

    private val channel = MethodChannel(binnary, gpsChannelName)
    private var locationFused : FusedLocationProviderClient? = null
    private val priority = Priority.PRIORITY_HIGH_ACCURACY
    private val tag = "GpsMethodChannel"

    companion object{
        const val GPS_REQUEST_CODE = 1574
        var resultGps : MethodChannel.Result? = null
    }


init {

    channel.setMethodCallHandler(GpsCallHandler())
}

    private inner class GpsCallHandler : MethodCallHandler{

        override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
            Log.d(tag, "$tag onMethodCall ${call.method} ")

            when(call.method){

                "checkGpsStatus"-> {
                    try {
                        val gpsStatus = isGpsActive(context)
                        result.success(gpsStatus)

                    }catch(e:Exception){
                        result.success(false)
                    }
                }

                "requestGpsServiceActivation"-> {
                    resultGps = result
                    requestGpsActivation(result, activity)
                }

                "getCurrentLocation"-> {
                    getCurrentGpsLocation(context, result)
                }

                else-> {
                    result.notImplemented()
                }

            }
        }

    }

    private fun isGpsActive(context : Context) : Boolean {
      val locationManager =  context.getSystemService(Context.LOCATION_SERVICE) as LocationManager

        val isGpsEnabled = locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER) //-- gps satelital
        val isNetWorkEnabled = locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER) //-- system of red of localization

       Log.d(tag, "CHECK IS GPS ACTIVE $✅isGpsEnabled $isGpsEnabled isNetWorkEnabled $isNetWorkEnabled ")

      return isGpsEnabled || isNetWorkEnabled
    }

// added to build.gradle this dependency:   implementation 'com.google.android.gms:play-services-location:21.0.1'
    private fun requestGpsActivation(result : MethodChannel.Result, activity : MainActivity) {

        //-- Priority.PRIORITY_HIGH_ACCURACY: clients that are showing the user's location in realtime
        //-- create request gps location
        val locationRequest = LocationRequest.Builder(priority, 1000L)
            .build()

    // -- The FusedLocationProviderClient is excellent for reading coordinates,
    // but it not has the ability to force the system to display the "Activate GPS" dialog.
    // For that, we use SettingsClient.
        val builder = LocationSettingsRequest.Builder().addLocationRequest(locationRequest)

    // verify the hardware
        val client: SettingsClient = LocationServices.getSettingsClient(activity)
        val task: Task<LocationSettingsResponse> = client.checkLocationSettings(builder.build())

        task.addOnSuccessListener {
            result.success(true) // GPS is on
        }

        task.addOnFailureListener { exception ->
            if (exception is ResolvableApiException) {
                try {
                    // show Android system dialog
                    exception.startResolutionForResult(activity, GPS_REQUEST_CODE)

                    // the result is handle on onActivityResult of MainActivity
                } catch (sendEx: IntentSender.SendIntentException) {
                    result.error("GPS_ERROR", "No se pudo mostrar el diálogo", null)
                }
            } else {
                result.success(false)
            }
        }
    }

    private fun getCurrentGpsLocation(context: Context, result : MethodChannel.Result){

        val fineLocation =ActivityCompat.checkSelfPermission(context,  Manifest.permission.ACCESS_FINE_LOCATION)  // precisa
        val coarseLocation = ActivityCompat.checkSelfPermission(context, Manifest.permission.ACCESS_COARSE_LOCATION)  // aproximada

        Log.d(tag, "getCurrentLocation fineLocation: $fineLocation coarseLocation: $coarseLocation")

        if (fineLocation != PackageManager.PERMISSION_GRANTED &&
            coarseLocation != PackageManager.PERMISSION_GRANTED) {

            Log.d(tag, "getCurrentLocation fineLocation coarseLocation-- return")

          //  return 
            result.error("LOCATION_ERROR", "LOCATION_ERROR", null)
        }

        Log.d(tag, "locationFused?.getCurrentLocation")
        //The FusedLocationProviderClient AndroidService is used to OBTAIN the coordinates (Latitude/Longitude) once the GPS is already turned on.
        val client = locationFused ?:  LocationServices.getFusedLocationProviderClient(activity)

        Log.d(tag, "getCurrentLocation client $client")

        client.getCurrentLocation(priority, null).addOnSuccessListener {

            location -> if (location != null) {
            Log.d(tag, "getCurrentLocation location is: $location")

            val locationMap : Map<String, *>  = mapOf(
                "latitude" to location.latitude,
                "longitude" to location.longitude,
                "accuracy" to location.accuracy,
                "display_name" to "")

            result.success(locationMap)
/*
           Utils.locationToMap(context, location){
               locationMap ->

                Log.d(tag, "getCurrentLocation locationMap $locationMap")

                result.success(locationMap)

            }
*/
            } else {
                //-- sometimes a Gps takes a few seconds to fix the position
                getLastGpsLocation(client, result)
            }

        }.addOnFailureListener{
                e ->
            result.error("LOCATION_ERROR", e.message, null)
        }
    }

    private fun getLastGpsLocation(client: FusedLocationProviderClient, result: MethodChannel.Result){

        val fineLocation = ActivityCompat.checkSelfPermission(context,  Manifest.permission.ACCESS_FINE_LOCATION)  // precisa
        val coarseLocation = ActivityCompat.checkSelfPermission(context, Manifest.permission.ACCESS_COARSE_LOCATION)  // aproximada

        Log.d(tag, "getLastGpsLocation fineLocation: $fineLocation coarseLocation: $coarseLocation")

        if (fineLocation != PackageManager.PERMISSION_GRANTED &&
            coarseLocation != PackageManager.PERMISSION_GRANTED) {

            Log.d(tag, "getLastGpsLocation fineLocation coarseLocation-- return")

            return
        }

        client.lastLocation.addOnSuccessListener {
            location -> if (location != null) {
                Log.d(tag, "getLastGpsLocation location is: $location")

            val locationMap : Map<String, *>  = mapOf(
                "latitude" to location.latitude,
                "longitude" to location.longitude,
                "accuracy" to location.accuracy,
                "display_name" to "")

            result.success(locationMap)
/*
                 Utils.locationToMap(context, location){
                    locationMap->  Log.d(tag, "getLastGpsLocation locationMap $locationMap")

                     result.success(locationMap)
                }
*/

                 } else {
                     //-- sometimes a Gps takes a few seconds to fix the position
                        Log.d(tag, "getLastGpsLocation Location received as null")

                         result.error("LOCATION_NULL", "Location received as null", null)
        }

        }.addOnFailureListener{
                e ->
            result.error("LOCATION_ERROR", e.message, null)
        }
    }
}
