import 'package:flutter_test/flutter_test.dart';
import 'package:petcare/main.dart';

void main() {
  testWidgets('PetCare inicia correctamente', (WidgetTester tester) async {
    // Cargar la aplicación PetCare.
    await tester.pumpWidget(const PetCareApp());

    // Verificar que la pantalla inicial se muestre correctamente.
    expect(find.text('PetCare'), findsOneWidget);
    expect(find.text('Cuida la salud de tu mascota'), findsOneWidget);

    // Verificar que existan los botones principales.
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Registrarse'), findsOneWidget);
  });
}