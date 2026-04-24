import 'process_test_runner.dart';

/// A [ProcessTestRunner] that runs `dart test --reporter=json`.
class DartTestRunner extends ProcessTestRunner {
  const DartTestRunner({
    super.arguments,
    super.workingDirectory,
  });

  @override
  String get executable => 'dart';

  @override
  List<String> get baseArgs => ['test', '--reporter=json'];
}
