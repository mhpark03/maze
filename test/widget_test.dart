import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_maze_app/main.dart';

void main() {
  testWidgets('Arrow maze app starts', (WidgetTester tester) async {
    await tester.pumpWidget(const ArrowMazeApp());
    await tester.pump();

    expect(find.text('레벨 1'), findsOneWidget);
  });
}
