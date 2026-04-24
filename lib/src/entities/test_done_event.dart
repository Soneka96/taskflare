import 'test_event.dart';

class TestDoneEvent extends TestEvent {
  TestDoneEvent({
    required this.testId,
    required this.result,
    required this.skipped,
    required this.hidden,
  });

  factory TestDoneEvent.fromJson(Map<String, dynamic> json) {
    return TestDoneEvent(
      testId: json['testID'] as int,
      result: json['result'] as String?,
      skipped: json['skipped'] == true,
      hidden: json['hidden'] == true,
    );
  }

  final int testId;
  final String? result;
  final bool skipped;
  final bool hidden;
}
