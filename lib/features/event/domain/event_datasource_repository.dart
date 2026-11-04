import 'package:focushabit/core/cores_files.dart' show Either, DatasourceStatus;
import 'package:focushabit/features/event/domain/entity/event.dart';

abstract class EventDatasourceRepository {
  const EventDatasourceRepository();

  Future<Either<List<Event>, DatasourceStatus>> getAllEventByUserId(
      {required String? userId});

  Stream<Either<List<Event>, DatasourceStatus>> getEventChanged(
      {required String? userId});

  Future<Either<int, DatasourceStatus>> insertEvent({required Event event});

  Future<Either<bool, DatasourceStatus>> updateEvent({
    required Event event,
  });

  Future<Either<int?, DatasourceStatus>> markEventCompleteUncompleted({
    required Event event,
  });

  Future<Either<int?, DatasourceStatus>> deleteEvent({required Event event});
}
