import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/medicine_box_scan_result.dart';

class MedicineBoxScannerService {
  TextRecognizer? _textRecognizer;
  TextRecognizer get _recognizer =>
      _textRecognizer ??= TextRecognizer(script: TextRecognitionScript.latin);

  static const List<String> _knownDrugs = [
    'Paracetamol', 'Ibuprofeno', 'Losartán', 'Enalapril', 'Metformina',
    'Atorvastatina', 'Levotiroxina', 'Eutirox', 'Aspirina', 'Omeprazol',
    'Amoxicilina', 'Clotrimazol', 'Prednisona', 'Sertralina', 'Amlodipino',
    'Glibenclamida', 'Salbutamol', 'Carvedilol', 'Hidroclorotiazida', 'Fluoxetina'
  ];

  /// Processes an image of a medicine box or blister pack using on-device ML Kit
  Future<MedicineBoxScanResult> processImage(String imagePath, {DateTime? referenceDate}) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final RecognizedText recognizedText = await _recognizer.processImage(inputImage);
    return parseRawText(recognizedText.text, referenceDate: referenceDate);
  }

  static String _removeDiacritics(String str) {
    return str
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('Á', 'A')
        .replaceAll('É', 'E')
        .replaceAll('Í', 'I')
        .replaceAll('Ó', 'O')
        .replaceAll('Ú', 'U');
  }

  /// Parses raw OCR text to extract drug name, dosage, units, lot number, and expiration date
  MedicineBoxScanResult parseRawText(String text, {DateTime? referenceDate}) {
    final cleanText = text.replaceAll('\n', ' ');
    final today = referenceDate ?? DateTime.now();

    // 1. Detect Drug Name (supports accented and unaccented uppercase like LOSARTAN)
    String? drugName;
    final normalizedCleanText = _removeDiacritics(cleanText);
    for (final drug in _knownDrugs) {
      final normalizedDrug = _removeDiacritics(drug);
      if (RegExp('\\b$normalizedDrug', caseSensitive: false).hasMatch(normalizedCleanText)) {
        drugName = drug;
        break;
      }
    }

    // 2. Detect Dosage / Concentration (e.g. 50 mg, 100 mcg, 20 mg, 850 mg)
    String? dosage;
    final dosageMatch = RegExp(r'(\d+(?:[\.,]\d+)?\s*(?:mg|g|mcg|ug|ml|ui))\b', caseSensitive: false).firstMatch(cleanText);
    if (dosageMatch != null) {
      dosage = dosageMatch.group(1);
    }

    // 3. Detect Box Units (e.g. 30 comprimidos, 28 cápsulas, 60 tabletas, 30 comp)
    int? units;
    final unitsMatch = RegExp(
      r'(\d{1,3})\s*(?:comprimidos|comp\b|c[aá]psulas|caps\b|tabletas|tab\b|sobres|grageas|unidades|unid\b|un\b)',
      caseSensitive: false,
    ).firstMatch(cleanText);
    if (unitsMatch != null) {
      units = int.tryParse(unitsMatch.group(1) ?? '');
    }

    // 4. Detect Lot Number (e.g. LOTE: 24A09, LOT: E8821, LOTE 19K01)
    String? lotNumber;
    final lotMatch = RegExp(
      r'(?:LOTE|LOT|SERIE|BATCH)[:\s\.\#]*([A-Z0-9\-]{3,15})\b',
      caseSensitive: false,
    ).firstMatch(cleanText);
    if (lotMatch != null) {
      lotNumber = lotMatch.group(1)?.toUpperCase();
    }

    // 5. Detect Expiration Date (e.g. VENCE: 12/2027, EXP: 10/2026, VTO: 01/2023)
    String? expDateStr;
    DateTime? expirationDateTime;
    int? daysRemaining;
    BoxExpirationStatus status = BoxExpirationStatus.unknown;

    // Matches: [VENCE|EXP|VTO] [DD/]?MM/YYYY or MM/YY
    final expMatch = RegExp(
      r'(?:VENCE|VENC|EXP|VTO|CAD|F\.?\s*VTO|VENCIMIENTO)[:\s\.]*(?:(\d{1,2})[/\-\.])?(\d{1,2})[/\-\.](20\d{2}|\d{2})\b',
      caseSensitive: false,
    ).firstMatch(cleanText);

    if (expMatch != null) {
      final dayStr = expMatch.group(1);
      final monthStr = expMatch.group(2);
      final yearStr = expMatch.group(3);

      if (monthStr != null && yearStr != null) {
        int month = int.tryParse(monthStr) ?? 1;
        int year = int.tryParse(yearStr) ?? 2026;
        if (year < 100) year += 2000;

        int day = dayStr != null ? (int.tryParse(dayStr) ?? 28) : 28;
        if (dayStr == null) {
          // If no day given, set to end of month
          final nextMonth = month == 12 ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
          final lastDay = nextMonth.subtract(const Duration(days: 1)).day;
          day = lastDay;
        }

        month = month.clamp(1, 12);
        day = day.clamp(1, 31);

        expirationDateTime = DateTime(year, month, day, 23, 59, 59);
        expDateStr = '${month.toString().padLeft(2, '0')}/$year';

        daysRemaining = expirationDateTime.difference(today).inDays;

        if (daysRemaining < 0) {
          status = BoxExpirationStatus.expired;
        } else if (daysRemaining < 60) {
          status = BoxExpirationStatus.expiringSoon;
        } else {
          status = BoxExpirationStatus.valid;
        }
      }
    }

    // 6. Detect Chilean ISP Sanitary Registration (e.g. Reg. I.S.P. N° F-18452/19, Reg. ISP F-12345, F-2015/18)
    String? ispRegister;
    final ispMatch = RegExp(
      r'(?:REG\.?\s*I\.?S\.?P\.?\s*(?:N[°ºo\.]*)?|REGISTRO\s*ISP[:\s]*)\s*([A-Z]{1,2}-?\d{3,6}(?:[/\-]\d{2,4})?)',
      caseSensitive: false,
    ).firstMatch(cleanText);

    if (ispMatch != null) {
      ispRegister = ispMatch.group(1)?.toUpperCase();
    } else {
      final directCodeMatch = RegExp(
        r'\b([FREN]-\d{3,6}[/\-]\d{2,4})\b',
        caseSensitive: false,
      ).firstMatch(cleanText);
      if (directCodeMatch != null) {
        ispRegister = directCodeMatch.group(1)?.toUpperCase();
      }
    }

    // 7. Detect Bioequivalence Certification Mark (Chilean ISP Bioequivalente)
    final isBioequivalent = RegExp(
      r'\b(?:BIOEQUIVALENTE|BIOEQUIVALENCIA|BIOEQUIVALENTES|DEMOSTRADA\s+BIOEQUIVALENCIA)\b',
      caseSensitive: false,
    ).hasMatch(normalizedCleanText);

    double confidence = 0.0;
    if (drugName != null) confidence += 0.20;
    if (dosage != null) confidence += 0.20;
    if (units != null) confidence += 0.15;
    if (lotNumber != null) confidence += 0.15;
    if (expirationDateTime != null) confidence += 0.15;
    if (ispRegister != null) confidence += 0.10;
    if (isBioequivalent) confidence += 0.05;

    return MedicineBoxScanResult(
      rawText: text,
      detectedDrugName: drugName,
      detectedDosage: dosage,
      detectedUnits: units,
      detectedLotNumber: lotNumber,
      detectedExpirationDate: expDateStr,
      detectedIspRegister: ispRegister,
      isBioequivalent: isBioequivalent,
      expirationDateTime: expirationDateTime,
      daysRemaining: daysRemaining,
      expirationStatus: status,
      confidenceScore: confidence,
    );
  }

  void dispose() {
    _textRecognizer?.close();
  }
}
