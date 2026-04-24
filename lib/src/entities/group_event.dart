import 'test_event.dart';

class GroupEvent extends TestEvent {
  GroupEvent({required this.id, required this.name});

  factory GroupEvent.fromJson(Map<String, dynamic> json) {
    final group = json['group'] as Map<String, dynamic>;
    return GroupEvent(
      id: group['id'] as int,
      name: (group['name'] as String?) ?? '',
    );
  }

  final int id;
  final String name;
}
