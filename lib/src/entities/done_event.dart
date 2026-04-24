import 'test_event.dart';

class DoneEvent extends TestEvent {
  DoneEvent({required this.success});

  factory DoneEvent.fromJson(Map<String, dynamic> json) {
    return DoneEvent(success: json['success'] as bool?);
  }

  final bool? success;
}
