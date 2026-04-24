import 'process_test_runner.dart';

class FlutterTestRunner extends ProcessTestRunner {
  const FlutterTestRunner({
    super.arguments,
    super.workingDirectory,
  });

  @override
  String get executable => 'flutter';

  @override
  List<String> get baseArgs => ['test', '--machine'];
}
