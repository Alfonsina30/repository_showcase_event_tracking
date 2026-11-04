import 'package:focushabit/features/event/event_feature_files.dart';

abstract interface class EventDatasource {
  const EventDatasource();

  Future<List<Event>> getEventsByUserId({required String? userId});
  //
  Stream<List<Event>> getEventsChanged({required String? userId});

  Future<int> insertEvent({required Event event});
  Future<bool> updateEvent({required Event event});
  Future<int?> markEventComplete({required Event event});
  Future<int?> deleteEvent({required Event event});
}
