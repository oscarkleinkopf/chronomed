import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/prescription_scan_result.dart';

class PrescriptionParserService {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  static const List<String> _knownDrugs = [
    'Paracetamol', 'Ibuprofeno', 'Losartán', 'Enalapril', 'Metformina',
    'Atorvastatina', 'Levotiroxina', 'Eutirox', 'Aspirina', 'Omeprazol',
    'Amoxicilina', 'Clotrimazol', 'Prednisona', 'Sertralina', 'Amlodipino'
  ];

  Future<PrescriptionScanResult> processImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
    return parseRawText(recognizedText.text);
  }

  PrescriptionScanResult parseRawText(String text) {
    final cleanText = text.replaceAll('\n', ' ');

    String? drugName;
    for (final drug in _knownDrugs) {
      if (RegExp(drug, caseSensitive: false).hasMatch(cleanText)) {
        drugName = drug;
        break;
      }
    }

    String? dosage;
    final dosageMatch = RegExp(r'(\d+(?:[\.,]\d+)?\s*(?:mg|g|mcg|ug|ml|ui))', caseSensitive: false).firstMatch(cleanText);
    if (dosageMatch != null) dosage = dosageMatch.group(1);

    int? frequencyHours;
    final freqMatch = RegExp(r'(?:cada|c\/)\s*(\d{1,2})\s*(?:horas|hrs|h)', caseSensitive: false).firstMatch(cleanText);
    if (freqMatch != null) frequencyHours = int.tryParse(freqMatch.group(1) ?? '');

    String mealRelation = 'NORMAL';
    if (RegExp(r'(?:ayunas|antes del desayuno)', caseSensitive: false).hasMatch(cleanText)) {
      mealRelation = 'FASTING';
    } else if (RegExp(r'(?:con las comidas|con alimentos)', caseSensitive: false).hasMatch(cleanText)) {
      mealRelation = 'WITH_MEAL';
    }

    return PrescriptionScanResult(
      rawText: text,
      detectedDrugName: drugName,
      detectedDosage: dosage,
      detectedFrequencyHours: frequencyHours ?? 8,
      detectedMealRelation: mealRelation,
      confidenceScore: (drugName != null ? 0.5 : 0.0) + (dosage != null ? 0.5 : 0.0),
    );
  }

  void dispose() => _textRecognizer.close();
}
