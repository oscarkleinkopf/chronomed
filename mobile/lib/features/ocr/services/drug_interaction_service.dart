enum InteractionSeverity {
  none,
  foodRestriction,
  majorWarning,
  criticalContraindication,
}

class DrugInteractionResult {
  final InteractionSeverity severity;
  final String title;
  final String description;
  final String clinicalRisk;
  final String recommendation;
  final bool isBlocking;

  const DrugInteractionResult({
    this.severity = InteractionSeverity.none,
    this.title = 'Tratamiento Compatible',
    this.description = 'No se detectaron contraindicaciones con los fármacos activos.',
    this.clinicalRisk = '0 conflictos clínicos detectados.',
    this.recommendation = 'Fármaco apto para incorporación al régimen del paciente.',
    this.isBlocking = false,
  });

  bool get hasConflict => severity != InteractionSeverity.none;
}

class RegimenSafetyReport {
  final int totalDrugs;
  final List<DrugInteractionResult> criticalAlerts;
  final List<DrugInteractionResult> majorWarnings;
  final List<DrugInteractionResult> dietaryPrecautions;

  const RegimenSafetyReport({
    required this.totalDrugs,
    required this.criticalAlerts,
    required this.majorWarnings,
    required this.dietaryPrecautions,
  });

  bool get hasCritical => criticalAlerts.isNotEmpty;
  bool get hasWarnings => majorWarnings.isNotEmpty;
  bool get hasDietaryRestrictions => dietaryPrecautions.isNotEmpty;
  bool get isCompletelySafe => criticalAlerts.isEmpty && majorWarnings.isEmpty;
  int get totalIssues => criticalAlerts.length + majorWarnings.length + dietaryPrecautions.length;
}

class DrugInteractionService {
  static final DrugInteractionService instance = DrugInteractionService._internal();
  factory DrugInteractionService() => instance;
  DrugInteractionService._internal();

  /// Evalúa la seguridad global de todo el régimen de fármacos activos de un paciente.
  RegimenSafetyReport evaluateActiveRegimen(List<String> activeDrugs) {
    final critical = <DrugInteractionResult>[];
    final major = <DrugInteractionResult>[];
    final dietary = <DrugInteractionResult>[];

    final processedPairs = <String>{};

    // 1. Evaluación de pares fármaco - fármaco
    for (int i = 0; i < activeDrugs.length; i++) {
      for (int j = i + 1; j < activeDrugs.length; j++) {
        final drugA = activeDrugs[i];
        final drugB = activeDrugs[j];
        final pairKey = '${drugA.toLowerCase()}|${drugB.toLowerCase()}';
        if (processedPairs.contains(pairKey)) continue;
        processedPairs.add(pairKey);

        final result = evaluateCandidate(drugA, [drugB]);
        if (result.severity == InteractionSeverity.criticalContraindication) {
          critical.add(result);
        } else if (result.severity == InteractionSeverity.majorWarning) {
          major.add(result);
        }
      }
    }

    // 2. Evaluación individual de restricciones dietarias y cronofarmacológicas
    for (final drug in activeDrugs) {
      final res = evaluateCandidate(drug, const []);
      if (res.severity == InteractionSeverity.foodRestriction) {
        if (!dietary.any((d) => d.title == res.title)) {
          dietary.add(res);
        }
      }
    }

    return RegimenSafetyReport(
      totalDrugs: activeDrugs.length,
      criticalAlerts: critical,
      majorWarnings: major,
      dietaryPrecautions: dietary,
    );
  }

  /// Evalúa el fármaco candidato contra la lista de fármacos ya activos del paciente.
  DrugInteractionResult evaluateCandidate(String candidateDrug, List<String> activeDrugs) {
    final candidate = candidateDrug.toLowerCase().trim();
    final activeList = activeDrugs.map((d) => d.toLowerCase().trim()).toList();

    // 1. REGLAS DE CONTRAINDICACIÓN CRÍTICA (Bloqueo por riesgo vital)

    // Ibuprofeno / AINE + Acenocumarol (Neosintrom)
    if (_isIbuprofen(candidate) && _hasAcenocoumarol(activeList) ||
        _isAcenocoumarol(candidate) && _hasIbuprofen(activeList)) {
      return const DrugInteractionResult(
        severity: InteractionSeverity.criticalContraindication,
        title: '🚨 CONTRAINDICACIÓN CRÍTICA (RIESGO VITAL)',
        description: 'Interacción de alto riesgo: AINE (Ibuprofeno) + Acenocumarol (Anticoagulante).',
        clinicalRisk: 'Inhibición de COX-1 y función plaquetaria por el AINE sumado al bloqueo de factores de coagulación. Hemorragia digestiva masiva o sangrado intracraneal.',
        recommendation: 'Alerta Roja Bloqueante: No administrar conjuntamente. Recomienda suspender el AINE de inmediato y consultar al médico por alternativa segura (ej. Paracetamol).',
        isBlocking: true,
      );
    }

    // Atorvastatina + Claritromicina
    if (_isAtorvastatin(candidate) && _hasClarithromycin(activeList) ||
        _isClarithromycin(candidate) && _hasAtorvastatin(activeList)) {
      return const DrugInteractionResult(
        severity: InteractionSeverity.criticalContraindication,
        title: '🚨 CONTRAINDICACIÓN CRÍTICA (RIESGO VITAL)',
        description: 'Interacción severa: Atorvastatina + Claritromicina (Macrólido).',
        clinicalRisk: 'La Claritromicina es un potente inhibidor del CYP3A4 hepático, cuadruplicando los niveles séricos de Atorvastatina. Alto riesgo de Rabdomiólisis aguda y fallo renal agudo.',
        recommendation: 'Alerta Roja Bloqueante: Suspender transitoriamente la estatina mientras dure el ciclo antibiótico bajo supervisión médica.',
        isBlocking: true,
      );
    }

    // Benzodiacepinas (Clonazepam) + Opioides (Tramadol)
    if ((_isBenzodiazepine(candidate) && _hasOpioid(activeList)) ||
        (_isOpioid(candidate) && _hasBenzodiazepine(activeList))) {
      return const DrugInteractionResult(
        severity: InteractionSeverity.criticalContraindication,
        title: '🚨 CONTRAINDICACIÓN CRÍTICA (RIESGO VITAL)',
        description: 'Sinergia sedante central: Benzodiacepina + Opioide.',
        clinicalRisk: 'Depresión profunda del sistema nervioso central y del centro respiratorio bulbar. Riesgo inminente de parada respiratoria y coma.',
        recommendation: 'Alerta Roja Bloqueante: Evitar co-administración sin monitoreo ventilatorio estricto.',
        isBlocking: true,
      );
    }

    // 2. ADVERTENCIAS MAYORES (Alerta Ámbar)

    // Losartán + Espironolactona
    if (_isLosartan(candidate) && _hasSpironolactone(activeList) ||
        _isSpironolactone(candidate) && _hasLosartan(activeList)) {
      return const DrugInteractionResult(
        severity: InteractionSeverity.majorWarning,
        title: '⚠️ ADVERTENCIA CLÍNICA MAYOR',
        description: 'Sinergia ahorradora de potasio: Losartán (ARA-II) + Espironolactona.',
        clinicalRisk: 'Riesgo inminente de Hiperpotasemia severa (K+ > 6.0 mEq/L) que puede inducir arritmias cardíacas ventriculares.',
        recommendation: 'Requiere control urgente de electrolitos plasmáticos (potasemia) y validación del médico tratante antes del inicio.',
        isBlocking: false,
      );
    }

    // Losartán / Enalapril + AINEs (Ibuprofeno/Ketoprofeno/Diclofenaco)
    if ((_isAntihypertensiveRaas(candidate) && _hasIbuprofen(activeList)) ||
        (_isIbuprofen(candidate) && _hasAntihypertensiveRaas(activeList))) {
      return const DrugInteractionResult(
        severity: InteractionSeverity.majorWarning,
        title: '⚠️ ADVERTENCIA CLÍNICA MAYOR',
        description: 'Antihipertensivo (ARA-II / IECA) + AINE (Ibuprofeno).',
        clinicalRisk: 'Inhibición de prostaglandinas vasodilatadoras renales por el AINE, reduciendo el filtrado glomerular y atenuando el control de la presión arterial.',
        recommendation: 'Monitorear presión arterial y función renal. Evitar cursos prolongados de AINEs en hipertensos.',
        isBlocking: false,
      );
    }

    // 3. RESTRICCIONES ALIMENTARIAS Y CRONOFARMACOLÓGICAS

    // Levotiroxina (Eutirox)
    if (_isLevothyroxine(candidate)) {
      return const DrugInteractionResult(
        severity: InteractionSeverity.foodRestriction,
        title: '🥛 RESTRICCIÓN DIETARIA (LÁCTEOS Y CALCIO)',
        description: 'Interacción físico-química: Levotiroxina con Calcio y Alimentos.',
        clinicalRisk: 'Los iones de calcio forman quelatos insolubles con la levotiroxina, reduciendo drásticamente su absorción digestiva.',
        recommendation: 'Ingerir en estricto ayuno 30 a 60 minutos antes del desayuno. No mezclar con leche, yogur o café.',
        isBlocking: false,
      );
    }

    // Atorvastatina (Pomelo / Noche)
    if (_isAtorvastatin(candidate)) {
      return const DrugInteractionResult(
        severity: InteractionSeverity.foodRestriction,
        title: '🍊 RESTRICCIÓN DIETARIA Y CRONOFARMACOLOGÍA (POMELO)',
        description: 'Atorvastatina + Jugo de Pomelo / Toma Nocturna.',
        clinicalRisk: 'El jugo de pomelo inhibe el CYP3A4 intestinal, aumentando la biodisponibilidad de la estatina y el riesgo de mialgias. La síntesis de colesterol tiene pico circadiano nocturno.',
        recommendation: 'Evitar consumo de pomelo/toronja. Administrar preferentemente en la noche según el ritmo circadiano de la HMG-CoA Reductasa.',
        isBlocking: false,
      );
    }

    // Metformina
    if (_isMetformin(candidate)) {
      return const DrugInteractionResult(
        severity: InteractionSeverity.foodRestriction,
        title: '🍷 RESTRICCIÓN DE ALCOHOL',
        description: 'Metformina + Consumo de Alcohol.',
        clinicalRisk: 'El alcohol potencia el riesgo de acidosis láctica metabólica severa por inhibición de la oxidación hepática de lactato.',
        recommendation: 'Prohibir consumo concomitante de bebidas alcohólicas durante el tratamiento.',
        isBlocking: false,
      );
    }

    // Acenocumarol (Vitamina K)
    if (_isAcenocoumarol(candidate)) {
      return const DrugInteractionResult(
        severity: InteractionSeverity.foodRestriction,
        title: '🥗 RESTRICCIÓN DIETARIA (VITAMINA K)',
        description: 'Acenocumarol + Vegetales verdes con alta Vitamina K.',
        clinicalRisk: 'Las fluctuaciones en el consumo de vitamina K alteran el INR terapéutico, comprometiendo la anticoagulación.',
        recommendation: 'Mantener un consumo estable y regular de verduras de hoja verde (espinacas, acelga, brócoli) sin cambios bruscos.',
        isBlocking: false,
      );
    }

    return const DrugInteractionResult();
  }

  bool _isIbuprofen(String s) => s.contains('ibuprof') || s.contains('ketoprof') || s.contains('diclofen');
  bool _hasIbuprofen(List<String> l) => l.any(_isIbuprofen);

  bool _isAcenocoumarol(String s) => s.contains('acenoc') || s.contains('neosint') || s.contains('warfar');
  bool _hasAcenocoumarol(List<String> l) => l.any(_isAcenocoumarol);

  bool _isAtorvastatin(String s) => s.contains('atorvast') || s.contains('simvast');
  bool _hasAtorvastatin(List<String> l) => l.any(_isAtorvastatin);

  bool _isClarithromycin(String s) => s.contains('claritr') || s.contains('eritrom');
  bool _hasClarithromycin(List<String> l) => l.any(_isClarithromycin);

  bool _isLosartan(String s) => s.contains('losart') || s.contains('valsart') || s.contains('candesart');
  bool _hasLosartan(List<String> l) => l.any(_isLosartan);

  bool _isAntihypertensiveRaas(String s) => _isLosartan(s) || s.contains('enalapr');
  bool _hasAntihypertensiveRaas(List<String> l) => l.any(_isAntihypertensiveRaas);

  bool _isSpironolactone(String s) => s.contains('espiron');
  bool _hasSpironolactone(List<String> l) => l.any(_isSpironolactone);

  bool _isLevothyroxine(String s) => s.contains('levotirox') || s.contains('eutirox');

  bool _isMetformin(String s) => s.contains('metform');

  bool _isBenzodiazepine(String s) => s.contains('clonazep') || s.contains('alprazol') || s.contains('diazepam') || s.contains('lorazep');
  bool _hasBenzodiazepine(List<String> l) => l.any(_isBenzodiazepine);

  bool _isOpioid(String s) => s.contains('tramadol') || s.contains('morfina') || s.contains('codein') || s.contains('fentanil');
  bool _hasOpioid(List<String> l) => l.any(_isOpioid);
}
