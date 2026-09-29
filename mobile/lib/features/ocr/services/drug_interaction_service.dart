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

class DrugInteractionService {
  static final DrugInteractionService instance = DrugInteractionService._internal();
  factory DrugInteractionService() => instance;
  DrugInteractionService._internal();

  /// Evalúa el fármaco candidato contra la lista de fármacos ya activos del paciente.
  DrugInteractionResult evaluateCandidate(String candidateDrug, List<String> activeDrugs) {
    final candidate = candidateDrug.toLowerCase().trim();
    final activeList = activeDrugs.map((d) => d.toLowerCase().trim()).toList();

    // 1. REGLAS DE CONTRAINDICACIÓN CRÍTICA (Bloqueo por riesgo vital)

    // Ibuprofeno + Acenocumarol (Neosintrom)
    if (_isIbuprofen(candidate) && _hasAcenocoumarol(activeList) ||
        _isAcenocoumarol(candidate) && _hasIbuprofen(activeList)) {
      return const DrugInteractionResult(
        severity: InteractionSeverity.criticalContraindication,
        title: '🚨 CONTRAINDICACIÓN CRÍTICA (RIESGO VITAL)',
        description: 'Interacción de alto riesgo: Ibuprofeno (AINE) + Acenocumarol (Anticoagulante).',
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

    // 3. RESTRICCIONES ALIMENTARIAS Y DIETARIAS

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

    return const DrugInteractionResult();
  }

  bool _isIbuprofen(String s) => s.contains('ibuprof');
  bool _hasIbuprofen(List<String> l) => l.any(_isIbuprofen);

  bool _isAcenocoumarol(String s) => s.contains('acenoc') || s.contains('neosint');
  bool _hasAcenocoumarol(List<String> l) => l.any(_isAcenocoumarol);

  bool _isAtorvastatin(String s) => s.contains('atorvast');
  bool _hasAtorvastatin(List<String> l) => l.any(_isAtorvastatin);

  bool _isClarithromycin(String s) => s.contains('claritr');
  bool _hasClarithromycin(List<String> l) => l.any(_isClarithromycin);

  bool _isLosartan(String s) => s.contains('losart');
  bool _hasLosartan(List<String> l) => l.any(_isLosartan);

  bool _isSpironolactone(String s) => s.contains('espiron');
  bool _hasSpironolactone(List<String> l) => l.any(_isSpironolactone);

  bool _isLevothyroxine(String s) => s.contains('levotirox') || s.contains('eutirox');

  bool _isMetformin(String s) => s.contains('metform');
}
