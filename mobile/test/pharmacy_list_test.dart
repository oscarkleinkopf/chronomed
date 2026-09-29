import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronomed/core/storage/local_storage_service.dart';
import 'package:chronomed/features/medicine_cabinet/widgets/pharmacy_list_dialog.dart';
import 'package:chronomed/features/medicine_cabinet/models/medicine_cabinet_item.dart';
import 'package:chronomed/features/ocr/models/medicine_box_scan_result.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChronoMed Pharmacy List Dialog Test Suite', () {
    late LocalStorageService storage;

    setUp(() async {
      storage = LocalStorageService.instance;
      await storage.init(inMemory: true);
      await storage.resetAllData();
    });

    testWidgets('Displays low stock items in pharmacy list dialog', (WidgetTester tester) async {
      // Configurar un ítem con stock bajo (3 unidades)
      await storage.saveCabinetItem(
        MedicineCabinetItem(
          id: 'item-low-stock',
          name: 'Losartán Potásico',
          dosage: '50 mg',
          stockUnits: 3,
          ispRegister: 'F-14920/19',
          isBioequivalent: true,
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PharmacyListDialog(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Lista para Farmacia'), findsOneWidget);
      expect(find.textContaining('Losartán Potásico'), findsOneWidget);
      expect(find.textContaining('Quedan solo 3 un.'), findsOneWidget);
      expect(find.text('ENVIAR WHATSAPP'), findsOneWidget);
    });

    testWidgets('Shows empty state when all medicines have sufficient stock', (WidgetTester tester) async {
      // Elimina o actualiza todos los ítems para que tengan stock > 5 y no estén vencidos
      for (final item in storage.getCabinetItems()) {
        await storage.updateCabinetStock(item.id, 30);
      }

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PharmacyListDialog(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('¡Botiquín al día!'), findsOneWidget);
      expect(find.text('CERRAR'), findsOneWidget);
    });
  });
}
