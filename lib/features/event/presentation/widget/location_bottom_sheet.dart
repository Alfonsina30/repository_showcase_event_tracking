import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:focushabit/core/cores_files.dart';
import 'package:focushabit/features/location/location_files.dart';
import 'package:focushabit/features/event/event_feature_files.dart';
import 'package:focushabit/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

class LocationSelectorViewSheet extends StatefulWidget {
  const LocationSelectorViewSheet({super.key});

  @override
  State<LocationSelectorViewSheet> createState() =>
      _LocationSelectorViewSheetState();
}

class _LocationSelectorViewSheetState extends State<LocationSelectorViewSheet> {
  //
  late final TextEditingController _searchController; 
  late final MapController mapController;

@override
void initState(){
 super.initState();
 _searchController = TextEditingController(); 
  mapController = MapController();
}

@override
  void dispose(){
    super.dispose();
    _searchController.dispose();
    mapController.dispose();
  }

  LatLng? _latLngSelected;

  @override
  Widget build(BuildContext context) {
    //
    final loc = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final buttonStyle = ButtonStyle(
        iconColor:
            WidgetStatePropertyAll(Theme.of(context).colorScheme.onSurface));

    //
    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        resizeToAvoidBottomInset: true,
        body: MultiBlocListener(
            listeners: [
              //! LocationSearch
              BlocListener<LocationSelectorCubit, LocationSelectorState>(
                listener: (context, state) {
                  final loc = AppLocalizations.of(context)!;
                  final status = state.locationSearchStatus;

                  //! Location selected
                  if (status == LocationStatus.selected) {
                    //
                    final displayName =
                        state.selectedLocation?.displayName ?? '';
                    //
                    final fullAdress = displayName.isNotEmpty
                        ? displayName
                        : (state.selectedLocation
                                ?.toReadableLatLongString(loc) ??
                            '');

                    CustomSnackBar.showMessageScaffold(
                      context: context,
                      message: "${loc.textDialogSelectedLocation} $fullAdress",
                      duration: 3000,
                      behavior: SnackBarBehavior.floating,
                    );

                    setState((){
                      _searchController.text = displayName; 
                    });

                    context.read<LocationSelectorCubit>().cleanSearchResult();
                    return;
                  }
                },
              ),

              ...SharedBlocListenerGpsAndLocation.blocGpsAndLocationListener(
              context: context,
              //! --- actionGpsGranted
              actionGpsLocationIsGranted: () {
                //
                context.read<CurrentLocationBloc>().setupCurrentLocation();
                return;
              },
            ),

              //! CurrentLocationBloc
              BlocListener<CurrentLocationBloc, CurrentLocationState>(
                /*
                 listenWhen: (previous, current) =>
                      previous.isLoading && !current.isLoading,
                */
                  listener: (context, state) {
                    //
                    final currentLocation = state.currentLocation;

                    _moveToAndSelectLocation(
                        latLng: LatLng(currentLocation.latitude ?? 0.0,
                            currentLocation.longitude ?? 0.0),
                        displayName: currentLocation.displayName);
                    return;
                  }),
              //
            ],
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              children: [
                const SizedBox(
                  height: 10,
                ),

                //!  buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    //! exit
                    IconButton(
                      onPressed: () {
                        context.pop();
                      },
                      icon: Icon(Icons.arrow_back),
                      style: buttonStyle,
                    ),

                    //! Select
                    IconButton(
                      icon: const Icon(Icons.check),
                      onPressed: () {
                        final locationSelected = context
                            .read<LocationSelectorCubit>()
                            .state
                            .selectedLocation;

                        if (locationSelected == null) return;

                        context
                            .read<FormCreateUpdateEventBloc>()
                            .onLocationTaskChange(
                                LocationInput.dirty(locationSelected));

                        context
                            .read<LocationSelectorCubit>()
                            .cleanSearchResult();

                        context.pop();
                      },
                      style: buttonStyle,
                    ),
                  ],
                ),

                const SizedBox(
                  height: 40,
                ),

                Text(
                  loc.textChooseLocation,
                  style: textTheme.titleMedium,
                ),

                const SizedBox(
                  height: 20,
                ),

                //!MAP
                SizedBox(
                  height: 250,
                  child: _flutterMap(loc),
                ),

                const SizedBox(
                  height: 20,
                ),

                //! --- FIELD SEARCH
                _texFieldSearchLocation(
                    context: context, textTheme: textTheme, loc: loc),

                const SizedBox(height: 10),

                //!--------- MESSAGE IS OFFLINE
                BlocSelector<LocationSelectorCubit, LocationSelectorState,
                    bool>(
                  selector: (state) =>
                      state.locationSearchStatus == LocationStatus.offline,
                  builder: (context, hasInternet) {
                    if (hasInternet) {
                      return _messageOffline(loc: loc, textTheme: textTheme);
                    }
                    return SizedBox.shrink();
                  },
                ),

                //! ---------- LOCATION RESULTS ------------------
                Builder(builder: (context) {
                  final searchResults = context
                      .watch<LocationSelectorCubit>()
                      .state
                      .locationsResults;

                  final recentsLocationsDatasource =
                      context.watch<LocationDatasourceBloc>().state.locations;
                  //
                  return SizedBox(
                    height: 200,
                    child: (searchResults.isNotEmpty)
                        ? Column(
                            children: [
                              _locationsResult(
                                  locations: searchResults,
                                  loc: loc,
                                  textTheme: textTheme),
                            ],
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: Text(loc.textRecent,
                                    style: textTheme.titleMedium),
                              ),
                              _locationsResult(
                                  locations: recentsLocationsDatasource,
                                  showTrailing: true,
                                  loc: loc,
                                  textTheme: textTheme),
                            ],
                          ),
                  );
                }),
              ],
            )),
      );
    });
  }

  void _moveToAndSelectLocation({required LatLng latLng, String? displayName}) {
    //
    setState(() {
      mapController.move(latLng, 16);
      _latLngSelected = latLng; //-- is use for show the IconLocation on the Map
    });

    final locSelected = LocationEntity(
        longitude: latLng.longitude,
        latitude: latLng.latitude,
        displayName: displayName);

    context.read<LocationSelectorCubit>().selectLocation(locSelected);
    return;
//
  }

  Widget _flutterMap(AppLocalizations loc) {
    return Stack(
      children: [
        //
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter:
                LatLng(51.509364, -0.128928), // Center the map over London, UK
            initialZoom: 13.0,
            onTap: (tapPosition, latLng) =>
                _moveToAndSelectLocation(latLng: latLng),
          ),
          children: [
            BlocSelector<ConnectivityBloc, ConnectivityState, bool>(
              selector: (state) => state.hasInternet,
              builder: (context, hasInternet) {
                if (hasInternet) {
                  return TileLayer(
                      urlTemplate: Environment.mapTileUrl,
                      userAgentPackageName: Environment.mapUserAgent);
                }
                return Container(
                  alignment: (_latLngSelected != null)
                      ? Alignment.bottomCenter
                      : Alignment.center,
                  padding: EdgeInsets.only(bottom: 10, top:5),
                  child: Text(
                    loc.mapCannotLoad, //mapCannotLoad
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: ColorsApp.primaryColor),
                  ),
                );
              },
            ),

            //
            if (_latLngSelected != null)
              MarkerLayer(markers: [
                Marker(
                    point: _latLngSelected!,
                    child: const SizedBox(
                      height: 80,
                      width: 80,
                      child:
                          Icon(Icons.location_on, color: Colors.red, size: 40),
                    ))
              ])
          ],
        ),

        //!   if (_isLoading)
        BlocSelector<PermissionsServiceBloc, PermissionsServiceState, bool>(
          selector: (state) => state.isLoading,
          builder: (context, isLoading) {
            if (isLoading) {
              return InkWell(
                onTap: () {},
                child: Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: ColorsApp.primaryColor,
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),

        //! ---  BOTÓN GPS ---
        Positioned(
          bottom: 30,
          right: 20,
          child: FloatingActionButton(
            backgroundColor: Colors.white,
            onPressed: () async {
              //
              await SharedButtonActionLocation.actionButton(context);
            },
            child: const Icon(Icons.my_location, color: Colors.blue),
          ),
        ),
      ],
    );
  }

  //************************************************************************************ */

  Widget _locationsResult({
    required List<LocationEntity> locations,
    required AppLocalizations loc,
    required TextTheme textTheme,
    bool showTrailing = false,
  }) {
    //
    return BlocSelector<LocationSelectorCubit, LocationSelectorState,
        LocationEntity?>(
      selector: (locationSelected) => locationSelected.selectedLocation,
      builder: (context, locationSelected) {
        return Expanded(
          child: ListView.builder(
            itemCount: locations.length,
            padding: EdgeInsets.zero,
            itemBuilder: (context, i) {
              //
              final location = locations[i];
              final displayNameLocation = location.displayName ??
                  (location.toReadableLatLongString(loc) ?? '');

              final bool tapToLocation =
                  locationSelected?.latitude == location.latitude &&
                      locationSelected?.longitude == location.longitude;

              return Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: tapToLocation
                          ? ColorsApp.primaryColor
                          : Colors.transparent,
                    )),
                child: ListTile(
                    title:
                        Text(displayNameLocation, style: textTheme.bodySmall),
                    contentPadding: const EdgeInsets.only(left: 10),
                    trailing: (showTrailing)
                        ? IconButton(
                            onPressed: () {
                              //
                              CustomShowDialog(widgets: [
                                const Icon(Icons.warning_amber),
                                Text(
                                  loc.textCancelCurrentLocation(
                                      displayNameLocation),
                                  style: textTheme.displayMedium,
                                )
                              ], actions: [
                                OutlinedButton(
                                    onPressed: () {
                                      context.pop();
                                    },
                                    child: Text(loc.textButtonCancel)),
                                //
                                FilledButton(
                                    onPressed: () {
                                      context
                                          .read<LocationDatasourceBloc>()
                                          .deleteLocation(location: location);
                                    },
                                    child: Text(loc.textDelete))
                              ]).openShowDialog(context);
                            },
                            icon: Icon(
                              Icons.clear_outlined,
                              size: 18,
                              color: Theme.of(context).colorScheme.onSurface,
                            ))
                        : null,
                    onTap: () => _moveToAndSelectLocation(
                        latLng: LatLng(
                            location.latitude ?? 0, location.longitude ?? 0),
                        displayName: location.displayName)),
              );
            },
          ),
        );
      },
    );
  }

  CustomBoxDecoration _texFieldSearchLocation(
      {required AppLocalizations loc,
      required TextTheme textTheme,
      required BuildContext context}) {
    //
    return CustomBoxDecoration(
      showMargin: false,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: loc.textFieldSearchLocation,
          hintStyle: textTheme.bodySmall,
          prefixIcon: Icon(
            Icons.search,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          suffixIcon:
              BlocSelector<LocationSelectorCubit, LocationSelectorState, bool>(
            selector: (state) =>
                state.locationSearchStatus == LocationStatus.loading,
            builder: (context, state) {
              if (state) {
                return const Padding(
                    padding: EdgeInsets.all(10),
                    child: SizedBox(
                        height: 14,
                        width: 14,
                        child: CircularProgressIndicator(strokeWidth: 2)));
              }

              return IconButton(
                  onPressed: () {
                    setState(() {
                      context.read<LocationSelectorCubit>().cleanSearchResult();
                      _searchController.clear();
                    });
                  },
                  icon: const Icon(Icons.clear, size: 18));
            },
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
        onChanged: (query) {
          if (query.isEmpty) return;

          context.read<LocationSelectorCubit>().searchLocation(query);
        },
      ),
    );
  }

  Card _messageOffline({
    required AppLocalizations loc,
    required TextTheme textTheme,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Text(loc.textDialogOffline,
            style:
                textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
