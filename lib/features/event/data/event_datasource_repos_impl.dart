import 'package:flutter/services.dart';
import 'package:focushabit/core/cores_files.dart';
import 'package:focushabit/features/event/event_feature_files.dart';

class EventDatasourceRepositoryImpl extends EventDatasourceRepository {
  //
  final EventDatasource _eventDatasource;

  const EventDatasourceRepositoryImpl({
    required EventDatasource eventDatasource,
  }) : _eventDatasource = eventDatasource;

  @override
  Future<Either<List<Event>, DatasourceStatus>> getAllEventByUserId(
      {required String? userId}) async {
    try {
      final events = await _eventDatasource.getEventsByUserId(userId: userId);
      return Either.success(events);
    } catch (_) {
      return Either.failure(DatasourceStatus.notLoaded);
    }
  }

  @override
  Future<Either<int, DatasourceStatus>> insertEvent(
      {required Event event}) async {
    try {
      final events = await _eventDatasource.insertEvent(event: event);
      return Either.success(events);
    } on PlatformException catch (_) {
      return Either.failure(DatasourceStatus.notCreated);
    }
  }

  @override
  Future<Either<bool, DatasourceStatus>> updateEvent(
      {required Event event}) async {
    try {
      final isUpdate = await _eventDatasource.updateEvent(event: event);
      return Either.success(isUpdate);
    } catch (_) {
      return Either.failure(DatasourceStatus.notUpdate);
    }
  }

  @override
  Future<Either<int?, DatasourceStatus>> deleteEvent({
    required Event event,
  }) async {
    try {
      final isDeleted = await _eventDatasource.deleteEvent(event: event);
      return Either.success(isDeleted);
    } catch (_) {
      return Either.failure(DatasourceStatus.notDeleted);
    }
  }

  @override
  Future<Either<int?, DatasourceStatus>> markEventCompleteUncompleted(
      {required Event event}) async {
    try {
      final isUpdate = await _eventDatasource.markEventComplete(event: event);

      return Either.success(isUpdate);
    } catch (e) {
      return Either.failure(DatasourceStatus.exceptionNative);
    }
  }

  @override
  Stream<Either<List<Event>, DatasourceStatus>> getEventChanged(
      {required String? userId}) {
    return _eventDatasource
        .getEventsChanged(userId: userId)
        .map<Either<List<Event>, DatasourceStatus>>(
            (events) => Either.success(events))
        .handleError((error) {
      if (error is PlatformException) {
        return Either.failure(DatasourceStatus.exceptionNative);
      }
      return Either.failure(DatasourceStatus.exceptionNative);
    });
  }
}
