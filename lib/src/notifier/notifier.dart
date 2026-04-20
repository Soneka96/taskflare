import 'package:taskflare/taskflare.dart';

abstract class Notifier {
  Future<void> notify(RunSummary summary);
}
