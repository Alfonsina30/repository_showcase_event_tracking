import 'package:flutter/services.dart';
import 'package:focushabit/features/event/event_feature_files.dart';

class EventDatasourceImpl implements EventDatasource {
  //
  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;

  const EventDatasourceImpl(
      {required MethodChannel methodChannel,
      required EventChannel eventChannel})
      : _eventChannel = eventChannel,
        _methodChannel = methodChannel;

  @override
  Future<List<Event>> getEventsByUserId({required String? userId}) async {
    final events = await _methodChannel.invokeMethod(
        "getAllTaskByUserId", {"userId": userId}) as List<Object?>?;
    //
    if (events == null) return [];

    final event = events.map((map) {
      return EventModel.fromMap(map).modelToEntity();
    }).toList();

    return event;
  }

  @override
  Future<int> insertEvent({required Event event}) async {
    final toJson = EventModel.fromEntityToModel(event).toMap();

    final rowId = await _methodChannel.invokeMethod("insertTask", toJson);

    return rowId;
  }

  @override
  Future<bool> updateEvent({required Event event}) async {
    final toJson = EventModel.fromEntityToModel(event).toMap();

    final isUpdate =
        await _methodChannel.invokeMethod("updateTask", toJson) as bool;

    return isUpdate;
  }

  @override
  Future<int?> deleteEvent({required Event event}) async {
    final toJson = EventModel.fromEntityToModel(event).toMap();

    return await _methodChannel.invokeMethod("deleteTask", toJson) as int?;
  }

  @override
  Future<int?> markEventComplete({required Event event}) async {
    final toJson = EventModel.fromEntityToModel(event).toMap();

    return await _methodChannel.invokeMethod("markTaskDoneOrNot", toJson)
        as int?;
  }

  @override
  Stream<List<Event>> getEventsChanged({required String? userId}) {
    return _eventChannel.receiveBroadcastStream(userId).map<List<Event>>(
      (event) {
        final events = event as List;

        return events
            .map(
              (event) => EventModel.fromMap(event).modelToEntity(),
            )
            .toList();
      },
    );
  }
}
