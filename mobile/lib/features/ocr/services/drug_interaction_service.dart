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

    // AINE (Ibuprofeno/Diclofenaco/Ketoprofeno/Aspirina) + Anticoagulante (Acenocumarol/Warfarina/DOACs)
    if ((_isNsaid(candidate) && _hasAnticoagulant(activeList)) ||
        (_isAnticoagulant(candidate) && _hasNsaid(activeList))) {
      return const DrugInteractionResult(
        severity: InteractionSeverity.criticalContraindication,
        title: '🚨 CONTRAINDICACIÓN CRÍTICA (RIESGO VITAL)',
        description: 'Interacción de alto riesgo: AINE (Antiinflamatorio) + Anticoagulante.',
        clinicalRisk: 'Inhibición de COX-1 y agregación plaquetaria por el AINE sumado al bloqueo de factores de coagulación. Hemorragia digestiva masiva o sangrado intracraneal.',
        recommendation: 'Alerta Roja Bloqueante: No administrar conjuntamente. Recomienda suspender el AINE de inmediato y consultar al médico por alternativa segura (ej. Paracetamol).',
        isBlocking: true,
      );
    }

    // Estatinas (Atorvastatina/Simvastatina) + Macrólidos (Claritromicina/Eritromicina)
    if ((_isStatin(candidate) && _hasMacrolide(activeList)) ||
        (_isMacrolide(candidate) && _hasStatin(activeList))) {
      return const DrugInteractionResult(
        severity: InteractionSeverity.criticalContraindication,
        title: '🚨 CONTRAINDICACIÓN CRÍTICA (RIESGO VITAL)',
        description: 'Interacción severa: Estatina + Macrólido (Claritromicina/Eritromicina).',
        clinicalRisk: 'El antibiótico macrólido es un potente inhibidor del CYP3A4 hepático, cuadruplicando los niveles séricos de la estatina. Alto riesgo de Rabdomiólisis aguda y fallo renal agudo.',
        recommendation: 'Alerta Roja Bloqueante: Suspender transitoriamente la estatina mientras dure el ciclo antibiótico bajo supervisión médica.',
        isBlocking: true,
      );
    }

    // Benzodiacepinas (Clonazepam/Alprazolam) + Opioides (Tramadol/Morfina)
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

    // Doble bloqueo del SRAA: IECA (Enalapril) + ARA-II (Losartán)
    if ((_isAceInhibitor(candidate) && _hasArb(activeList)) ||
        (_isArb(candidate) && _hasAceInhibitor(activeList))) {
      return const DrugInteractionResult(
        severity: InteractionSeverity.criticalContraindication,
        title: '🚨 CONTRAINDICACIÓN CRÍTICA (DOBLE BLOQUEO SRAA)',
        description: 'Doble bloqueo del SRAA: IECA (Enalapril) + ARA-II (Losartán).',
        clinicalRisk: 'Fallo renal agudo (LRA), hiperpotasemia severa e hipotensión arterial sintomática sin beneficio clínico cardiovascular (Guías MINSAL/AHA).',
        recommendation: 'Alerta Roja Bloqueante: Combinación formalmente desaconsejada. Suspender uno de los dos agentes y mantener monoterapia bajo control médico.',
        isBlocking: true,
      );
    }

    // Digoxina + Amiodarona / Verapamilo
    if ((_isDigoxin(candidate) && _hasDigoxinInteractors(activeList)) ||
        (_isDigoxinInteractor(candidate) && _hasDigoxin(activeList))) {
      return const DrugInteractionResult(
        severity: InteractionSeverity.criticalContraindication,
        title: '🚨 CONTRAINDICACIÓN CRÍTICA (INTOXICACIÓN DIGITÁLICA)',
        description: 'Digoxina + Inhibidor de P-glicoproteína (Amiodarona / Verapamilo).',
        clinicalRisk: 'Inhibición de la excreción biliar y renal de Digoxina, duplicando la digoxinemia sérica. Riesgo letal de arritmias ventriculares y bloqueo AV completo.',
        recommendation: 'Alerta Roja Bloqueante: Reducir dosis de Digoxina en 50%, monitorizar niveles plasmáticos (rango 0.5-0.9 ng/mL) y vigilar signos de intoxicación.',
        isBlocking: true,
      );
    }

    // AINEs + Corticoides Sistémicos (Prednisona / Dexametasona)
    if ((_isNsaid(candidate) && _hasCorticosteroid(activeList)) ||
        (_isCorticosteroid(candidate) && _hasNsaid(activeList))) {
      return const DrugInteractionResult(
        severity: InteractionSeverity.criticalContraindication,
        title: '🚨 CONTRAINDICACIÓN CRÍTICA (HEMORRAGIA DIGESTIVA)',
        description: 'AINE (Ibuprofeno/Diclofenaco/Ketoprofeno) + Corticoide Sistémico (Prednisona).',
        clinicalRisk: 'Multiplicación sinérgica por más de 10 veces del riesgo de úlcera péptica activa, perforación gástrica y hemorragia digestiva masiva en adultos mayores.',
        recommendation: 'Alerta Roja Bloqueante: Evitar co-administración. Si el uso es imprescindible, añadir gastroprotección intensiva con IBP y evaluar sustitución analgésica.',
        isBlocking: true,
      );
    }

    // 2. ADVERTENCIAS MAYORES (Alerta Ámbar)

    // SRAA (Losartán / Enalapril) + Espironolactona
    if ((_isAntihypertensiveRaas(candidate) && _hasSpironolactone(activeList)) ||
        (_isSpironolactone(candidate) && _hasAntihypertensiveRaas(activeList))) {
      return const DrugInteractionResult(
        severity: InteractionSeverity.majorWarning,
        title: '⚠️ ADVERTENCIA CLÍNICA MAYOR',
        description: 'Sinergia ahorradora de potasio: SRAA (Losartán/Enalapril) + Espironolactona.',
        clinicalRisk: 'Riesgo inminente de Hiperpotasemia severa (K+ > 6.0 mEq/L) que puede inducir arritmias cardíacas ventriculares.',
        recommendation: 'Requiere control urgente de electrolitos plasmáticos (potasemia) y validación del médico tratante antes del inicio.',
        isBlocking: false,
      );
    }

    // Losartán / Enalapril + AINEs (Ibuprofeno/Ketoprofeno/Diclofenaco)
    if ((_isAntihypertensiveRaas(candidate) && _hasNsaid(activeList)) ||
        (_isNsaid(candidate) && _hasAntihypertensiveRaas(activeList))) {
      return const DrugInteractionResult(
        severity: InteractionSeverity.majorWarning,
        title: '⚠️ ADVERTENCIA CLÍNICA MAYOR',
        description: 'Antihipertensivo (ARA-II / IECA) + AINE.',
        clinicalRisk: 'Inhibición de prostaglandinas vasodilatadoras renales por el AINE, reduciendo el filtrado glomerular y atenuando el control de la presión arterial.',
        recommendation: 'Monitorear presión arterial y función renal. Evitar cursos prolongados de AINEs en hipertensos.',
        isBlocking: false,
      );
    }

    // Clopidogrel + Omeprazol / Esomeprazol
    if ((_isClopidogrel(candidate) && _hasOmeprazole(activeList)) ||
        (_isOmeprazole(candidate) && _hasClopidogrel(activeList))) {
      return const DrugInteractionResult(
        severity: InteractionSeverity.majorWarning,
        title: '⚠️ ADVERTENCIA CLÍNICA MAYOR (PÉRDIDA EFECTO ANTIAGREGANTE)',
        description: 'Clopidogrel + Inhibidor de CYP2C19 (Omeprazol / Esomeprazol).',
        clinicalRisk: 'Omeprazol inhibe la bioactivación de Clopidogrel a su forma activa. Incrementa el riesgo de trombosis del stent y recurrencia de infarto agudo al miocardio.',
        recommendation: 'Sustituir Omeprazol por Pantoprazol (menor afinidad por CYP2C19) para gastroprotección sin neutralizar el efecto antiplaquetario.',
        isBlocking: false,
      );
    }

    // Benzodiacepina + Antihistamínico Sedante (Clorfenamina / Hidroxicina)
    if ((_isBenzodiazepine(candidate) && _hasSedatingAntihistamine(activeList)) ||
        (_isSedatingAntihistamine(candidate) && _hasBenzodiazepine(activeList))) {
      return const DrugInteractionResult(
        severity: InteractionSeverity.majorWarning,
        title: '⚠️ ADVERTENCIA CLÍNICA MAYOR (SEDACIÓN Y CAÍDAS)',
        description: 'Benzodiacepina + Antihistamínico Sedante de 1ª generación (Clorfenamina).',
        clinicalRisk: 'Depresión aditiva del SNC y efectos anticolinérgicos. Alto riesgo de caídas con fractura osteoporótica, confusión mental y delirium en adultos mayores (Criterios de Beers).',
        recommendation: 'Evitar asociación sedante. En rinitis o alergias, preferir antihistamínicos de 2ª generación no sedantes (ej. Loratadina o Desloratadina).',
        isBlocking: false,
      );
    }

    // Alopurinol + Azatioprina
    if ((_isAllopurinol(candidate) && _hasAzathioprine(activeList)) ||
        (_isAzathioprine(candidate) && _hasAllopurinol(activeList))) {
      return const DrugInteractionResult(
        severity: InteractionSeverity.majorWarning,
        title: '⚠️ ADVERTENCIA CLÍNICA MAYOR (MIELOTOXICIDAD SEVERA)',
        description: 'Alopurinol + Azatioprina.',
        clinicalRisk: 'Inhibición de la xantina oxidasa por el alopurinol, bloqueando la degradación de azatioprina y desencadenando pancitopenia o neutropenia febril.',
        recommendation: 'Reducir la dosis de azatioprina al 25% de la habitual si la co-administración es mandatoria y vigilar hemograma seriado.',
        isBlocking: false,
      );
    }

    // 3. RESTRICCIONES ALIMENTARIAS Y CRONOFARMACOLÓGICAS

    // Levotiroxina (Eutirox)
    if (_isLevothyroxine(candidate)) {
      return const DrugInteractionResult(
        severity: InteractionSeverity.foodRestriction,
        title: '🥛 RESTRICCIÓN DIETARIA (LÁCTEOS Y CALCIO)',
        description: 'Interacción físico-química: Levotiroxina con Calcio, Hierro y Alimentos.',
        clinicalRisk: 'Los iones de calcio y hierro forman quelatos insolubles con la levotiroxina, reduciendo drásticamente su absorción digestiva.',
        recommendation: 'Ingerir en estricto ayuno 30 a 60 minutos antes del desayuno. No mezclar con leche, yogur o café. Separar de sulfato ferroso al menos 4 horas.',
        isBlocking: false,
      );
    }

    // Atorvastatina (Pomelo / Noche)
    if (_isStatin(candidate)) {
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
    if (_isAnticoagulant(candidate)) {
      return const DrugInteractionResult(
        severity: InteractionSeverity.foodRestriction,
        title: '🥗 RESTRICCIÓN DIETARIA (VITAMINA K)',
        description: 'Anticoagulante Oral + Vegetales verdes con alta Vitamina K.',
        clinicalRisk: 'Las fluctuaciones en el consumo de vitamina K alteran el INR terapéutico, comprometiendo la anticoagulación.',
        recommendation: 'Mantener un consumo estable y regular de verduras de hoja verde (espinacas, acelga, brócoli) sin cambios bruscos.',
        isBlocking: false,
      );
    }

    // Furosemida (Diurético de Asa)
    if (_isFurosemide(candidate)) {
      return const DrugInteractionResult(
        severity: InteractionSeverity.foodRestriction,
        title: '⚡ PRECAUCIÓN HIDROELECTROLÍTICA (CONTROL DE POTASIO)',
        description: 'Furosemida + Pérdida renal de Potasio y Deshidratación.',
        clinicalRisk: 'La furosemida produce excreción marcada de potasio y sodio. Riesgo de hipopotasemia severa (calambres, debilidad, arritmias cardíacas) y deshidratación.',
        recommendation: 'Asegurar ingesta de alimentos ricos en potasio (plátanos, naranjas, legumbres) y control periódico de electrolitos en CESFAM.',
        isBlocking: false,
      );
    }

    return const DrugInteractionResult();
  }

  bool _isNsaid(String s) =>
      s.contains('ibuprof') ||
      s.contains('ketoprof') ||
      s.contains('diclofen') ||
      s.contains('naproxen') ||
      s.contains('meloxic') ||
      s.contains('celecox') ||
      s.contains('ketorolac') ||
      s.contains('aspirin') ||
      s.contains('ácido acetilsalicílico') ||
      s.contains('aas');
  bool _hasNsaid(List<String> l) => l.any(_isNsaid);

  bool _isAnticoagulant(String s) =>
      s.contains('acenoc') ||
      s.contains('neosint') ||
      s.contains('warfar') ||
      s.contains('rivarox') ||
      s.contains('apixab') ||
      s.contains('dabigatr') ||
      s.contains('xarelto') ||
      s.contains('eliquis');
  bool _hasAnticoagulant(List<String> l) => l.any(_isAnticoagulant);

  // Backward compatibility alias for existing tests
  bool _isIbuprofen(String s) => _isNsaid(s);
  bool _hasIbuprofen(List<String> l) => _hasNsaid(l);
  bool _isAcenocoumarol(String s) => _isAnticoagulant(s);
  bool _hasAcenocoumarol(List<String> l) => _hasAnticoagulant(l);

  bool _isStatin(String s) =>
      s.contains('atorvast') ||
      s.contains('simvast') ||
      s.contains('rosuvast') ||
      s.contains('lovast');
  bool _hasStatin(List<String> l) => l.any(_isStatin);
  bool _isAtorvastatin(String s) => _isStatin(s);
  bool _hasAtorvastatin(List<String> l) => _hasStatin(l);

  bool _isMacrolide(String s) =>
      s.contains('claritr') || s.contains('eritrom') || s.contains('azitrom');
  bool _hasMacrolide(List<String> l) => l.any(_isMacrolide);
  bool _isClarithromycin(String s) => _isMacrolide(s);
  bool _hasClarithromycin(List<String> l) => _hasMacrolide(l);

  bool _isBenzodiazepine(String s) =>
      s.contains('clonazep') ||
      s.contains('alprazol') ||
      s.contains('diazepam') ||
      s.contains('lorazep') ||
      s.contains('midazol') ||
      s.contains('rivotril');
  bool _hasBenzodiazepine(List<String> l) => l.any(_isBenzodiazepine);

  bool _isOpioid(String s) =>
      s.contains('tramadol') ||
      s.contains('morfina') ||
      s.contains('codein') ||
      s.contains('fentanil') ||
      s.contains('metadona') ||
      s.contains('buprenorf') ||
      s.contains('zaldiar');
  bool _hasOpioid(List<String> l) => l.any(_isOpioid);

  bool _isArb(String s) =>
      s.contains('losart') ||
      s.contains('valsart') ||
      s.contains('candesart') ||
      s.contains('telmisart') ||
      s.contains('irbesart');
  bool _hasArb(List<String> l) => l.any(_isArb);
  bool _isLosartan(String s) => _isArb(s);
  bool _hasLosartan(List<String> l) => _hasArb(l);

  bool _isAceInhibitor(String s) =>
      s.contains('enalapr') ||
      s.contains('captopr') ||
      s.contains('ramipr') ||
      s.contains('lisinopr');
  bool _hasAceInhibitor(List<String> l) => l.any(_isAceInhibitor);

  bool _isAntihypertensiveRaas(String s) => _isArb(s) || _isAceInhibitor(s);
  bool _hasAntihypertensiveRaas(List<String> l) => l.any(_isAntihypertensiveRaas);

  bool _isSpironolactone(String s) => s.contains('espiron');
  bool _hasSpironolactone(List<String> l) => l.any(_isSpironolactone);

  bool _isDigoxin(String s) => s.contains('digoxin') || s.contains('lanicor');
  bool _hasDigoxin(List<String> l) => l.any(_isDigoxin);

  bool _isDigoxinInteractor(String s) =>
      s.contains('amiodar') || s.contains('verapamil');
  bool _hasDigoxinInteractors(List<String> l) => l.any(_isDigoxinInteractor);

  bool _isCorticosteroid(String s) =>
      s.contains('prednison') ||
      s.contains('prednisolon') ||
      s.contains('betametason') ||
      s.contains('dexametason') ||
      s.contains('hidrocortison');
  bool _hasCorticosteroid(List<String> l) => l.any(_isCorticosteroid);

  bool _isClopidogrel(String s) =>
      s.contains('clopidogrel') || s.contains('plavix');
  bool _hasClopidogrel(List<String> l) => l.any(_isClopidogrel);

  bool _isOmeprazole(String s) =>
      s.contains('omeprazol') ||
      s.contains('esomeprazol') ||
      s.contains('losecon');
  bool _hasOmeprazole(List<String> l) => l.any(_isOmeprazole);

  bool _isSedatingAntihistamine(String s) =>
      s.contains('clorfenamin') || s.contains('hidroxicin');
  bool _hasSedatingAntihistamine(List<String> l) => l.any(_isSedatingAntihistamine);

  bool _isAllopurinol(String s) =>
      s.contains('alopurinol') || s.contains('zyloric');
  bool _hasAllopurinol(List<String> l) => l.any(_isAllopurinol);

  bool _isAzathioprine(String s) =>
      s.contains('azatioprin') || s.contains('imuran');
  bool _hasAzathioprine(List<String> l) => l.any(_isAzathioprine);

  bool _isLevothyroxine(String s) =>
      s.contains('levotirox') || s.contains('eutirox');

  bool _isMetformin(String s) =>
      s.contains('metform') || s.contains('glafornil');

  bool _isFurosemide(String s) =>
      s.contains('furosemid') || s.contains('lasix');
}
