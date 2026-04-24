import 'test_event.dart';

class TestStartEvent extends TestEvent {
  TestStartEvent({
    required this.id,
    required this.name,
    required this.groupIds,
    this.url,
    this.line,
  });

  factory TestStartEvent.fromJson(Map<String, dynamic> json) {
    final test = json['test'] as Map<String, dynamic>;
    final rawGroupIds = test['groupIDs'] as List<dynamic>?;
    return TestStartEvent(
      id: test['id'] as int,
      name: test['name'] as String,
      groupIds: rawGroupIds?.cast<int>() ?? const [],
      url: test['url'] as String?,
      line: test['line'] as int?,
    );
  }

  final int id;
  final String name;
  final List<int> groupIds;
  final String? url;
  final int? line;
}
