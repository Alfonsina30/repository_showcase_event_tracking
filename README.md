Event Tracking System

Flutter + native Android (Kotlin) app for field workforce management. Offline-first task scheduling, real-time GPS, geofencing validation and role-based access.

Demo video: https://youtu.be/tXLmHM0Jb00

Key Features
Geofencing validation: an employee can mark an event as completed only if their current location is near the event location, precise location permission is granted and GPS is active.
Offline-first: task data is stored locally with Room. With Wi-Fi turned off, the app keeps working and no user action is lost, even after killing the app.
Reliable reminders: high-priority notifications scheduled with WorkManager at the date and time of each task, including recurring tasks.
Authentication and roles: Google, Facebook and Email/Password sign-in, password recovery, and role-based access (admin, employee) using Firebase Custom Claims.
Theming: light and dark mode with a centralized theme system (Charcoal #121212 and Safety Orange #F97316).
Native Android Layer (Kotlin)
The critical layer is written natively in Kotlin and connected to Flutter through Method Channels and Event Channels.

Area	Implementation
Persistence	Room Database with DAOs and type-safe queries. The Room and Flutter models already include location_id and spatial metadata.
Background work	WorkManager for persistent scheduling that survives device restarts and respects battery policies (Doze Mode).
Notifications	Custom notification channel named reminder task, so Android can identify and deliver the alerts correctly.
Location	Two native classes: PermissionLocationMethodChannel and GpsMethodChannel. Location permissions are handled by the system PermissionController, while GPS activation is handled by the Google Play Services API.
Permissions	ACCESS_FINE_LOCATION and ACCESS_COARSE_LOCATION, with handling for precise or approximate choice, and widgets for denied permission or disabled GPS.
Reverse geocoding	Native Android service that resolves missing location names. It runs when the user taps the map or uses the GPS button. When device is offline (the place name may show as coordinates)
Connectivity	Real-time internet listener using Event Channels and Method Channels.
Why FusedLocationProviderClient
Intelligence: if the user enters a building, it switches automatically from GPS to Wi-Fi or cell antennas to keep the signal.
Battery: optimized by Google to use significantly less power than the traditional LocationManager.
Accuracy: uses the phone sensors (accelerometer, etc.) to calculate the location faster.
Location can be selected in three ways: searching through OpenStreetMap (requires internet), using the current GPS location, or choosing a recent location saved in Room. The last two work offline.

Architecture
Clean Architecture with separate Presentation, Domain and Data layers.
Separation of responsibilities: use cases never talk to the native channel directly; they go through repositories.
State management: BLoC for business logic and Provider for UI state propagation.
Dependency injection: GetIt.
Navigation: GoRouter, with URL-based routes, deep linking and role-based redirects.
Auth and navigation flow
    A[User signs in] --> B[AuthBloc receives event]
    B --> C[AuthBloc emits authenticated]
    C --> D[RouterNotifier calls notifyListeners]
    D --> E[GoRouter runs redirect]
    E --> F[/signIn → /home/0/]
Backend (Firebase)
Firebase Auth: Google, Facebook and Email/Password.
Cloud Firestore: companies and user profiles, with security rules so that only an admin can create new employees.
Cloud Functions (createCompanyAdmin):
Receives the JWT and verifies it with verifyIdToken (Firebase Admin SDK).
The server decides the role, for security reasons.
Creates the company document in companies using the user uid.
Assigns Custom Claims.
Saves the profile in the users collection.
Data ownership: task data is stored locally in Room. Identity, companies and roles live in Firebase.

Related files: firestore.rules [TODO: link], functions/index.js [TODO: link], firestore.indexes.json [TODO: link].

Testing
Unit, widget and integration tests across the three layers (Presentation, Domain and Data).

flutter_test and bloc_test for reactive business logic.
Mocktail for mocking asynchronous dependencies (whenListen, Stream.value, fallback values).
UI tests including AlertDialog, GoRouter navigation and localization (AppLocalizations).
Isolated Service Locator (GetIt) in tests.
Test coverage: [TODO: add the real percentage if you have it]

Tech Stack
Flutter · Dart · Kotlin · BLoC · Provider · GoRouter · GetIt · Room · WorkManager · Google Play Services (Fused Location) · Firebase Auth · Cloud Firestore · Cloud Functions · OpenStreetMap · Mocktail

Getting Started
Web authentication
Add these scripts to web/index.html, before Flutter starts. Without them the Firebase JS backend never responds and the app freezes at onWaitInitState().

<script src="https://www.gstatic.com/firebasejs/10.8.0/firebase-app-compat.js"></script>
<script src="https://www.gstatic.com/firebasejs/10.8.0/firebase-auth-compat.js"></script>
To test Google sign-in on the web:

flutter run -d chrome --web-port=8080
Firebase setup and emulators
firebase init functions
firebase init firestore
firebase emulators:start
Connecting a physical Android phone to the emulators
adb reverse tcp:8080 tcp:8080
adb reverse tcp:5001 tcp:5001
adb reverse tcp:9099 tcp:9099
Connecting the Android emulator
Use 10.0.2.2 instead of 127.0.0.1:

if (kDebugMode) {
  FirebaseFirestore.instance.useFirestoreEmulator('10.0.2.2', 8080);
}

final url = Uri.parse(
  'http://10.0.2.2:5001/<your-project-id>/us-central1/createCompanyAdmin',
);
