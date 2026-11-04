import 'package:focushabit/core/cores_files.dart' show ParseTime, LocationEntity; 
import 'package:focushabit/core/utils/enum/status_event_worker.dart';

class Event {
  final int? id;
  final String? userId;
  final int? eventId;
  final String title;
  final int? eventTypeId;
  final DateTime? date;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? description;
  final LocationEntity location;
  final List<String>? repeatDays;
  final String? whenShowNotification;
  final bool? isUrgent;
  final bool? isComplete;
  final StatusWorker? eventWorkerStatus;
  final String? eventWorkerId;
  final String? eventNotificationId;

  const Event(
      {this.id,
      this.userId,
      this.eventId,
      required this.title,
      this.eventTypeId,
      this.date,
      this.startTime,
      this.endTime,
      this.description,
      required this.location,
      this.repeatDays,
      this.whenShowNotification,
      this.isUrgent,
      this.isComplete,
      this.eventWorkerStatus,
      this.eventWorkerId,
      this.eventNotificationId});

//**-- es usado solo a nivel visual
  String get formatStartTime => ParseTime.parseTime(startTime);
  String get formatEndTime => ParseTime.parseTime(endTime);
//*** */

  Event copyWith({
    int? id,
    String? userId,
    int? eventId,
    String? title,
    int? eventTypeId,
    DateTime? date,
    DateTime? startTime,
    DateTime? endTime,
    String? description,
    LocationEntity? location,
    List<String>? repeatDays,
    String? whenShowNotification,
    bool? isUrgent,
    bool? isComplete,
    StatusWorker? eventWorkerStatus,
    String? eventWorkerId,
    String? eventNotificationId,
  }) {
    return Event(
        id: id ?? this.id,
        eventId: eventId ?? this.eventId,
        userId: userId ?? this.userId,
        title: title ?? this.title,
        eventTypeId: eventTypeId ?? this.eventTypeId,
        date: date ?? this.date,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        description: description ?? this.description,
        location: location ?? this.location,
        repeatDays: repeatDays ?? this.repeatDays,
        whenShowNotification: whenShowNotification ?? this.whenShowNotification,
        isUrgent: isUrgent ?? this.isUrgent,
        isComplete: isComplete ?? this.isComplete,
        eventWorkerStatus: eventWorkerStatus ?? this.eventWorkerStatus,
        eventNotificationId: eventNotificationId ?? this.eventNotificationId,
        eventWorkerId: eventWorkerId ?? this.eventWorkerId);
  }

  @override
  String toString() {
    return '''ID: $id IDUSER: $userId  eventId: $eventId Title $title 
    category_id: $eventTypeId date: $date startTime: $startTime endTime: $endTime 
    description: $description location: $location repeatDays: $repeatDays 
    whenShowNotification: $whenShowNotification isUrgent: $isUrgent  
    isComplete: $isComplete WorkerStatus: $eventWorkerStatus,
    NotificationId: $eventNotificationId WorkerId: $eventWorkerId
    ''';
  }
}
