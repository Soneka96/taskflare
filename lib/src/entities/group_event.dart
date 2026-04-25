import 'test_event.dart';

/// A `group` event emitted by the test runner when it discovers a test group.
class GroupEvent extends TestEvent {
  /// Creates a [GroupEvent].
  GroupEvent({required this.id, required this.name});

  /// Parses a [GroupEvent] from the raw JSON event map.
  factory GroupEvent.fromJson(Map<String, dynamic> json) {
    final group = json['group'] as Map<String, dynamic>;
    return GroupEvent(
      id: group['id'] as int,
      name: (group['name'] as String?) ?? '',
    );
  }

  /// Unique identifier for this group, used to associate tests with their group.
  final int id;

  /// Display name of the group. Empty string for the implicit root group.
  final String name;
}
