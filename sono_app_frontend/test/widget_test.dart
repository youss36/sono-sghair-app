import 'package:flutter_test/flutter_test.dart';
import 'package:sono_app_frontend/main.dart';

void main() {
  testWidgets('affiche l’écran de connexion', (WidgetTester tester) async {
    await tester.pumpWidget(const SonoApp());

    expect(find.text('SONO SGHAIER'), findsOneWidget);
    expect(find.text('Adresse email'), findsOneWidget);
    expect(find.text('Mot de passe'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
  });
}
