# Benchmark Competitivo y Análisis de Mercado — ChronoMed
> **Documento de Referencia Técnica y Estratégica para Agentes y Robots Autónomos**
> **Fecha de Creación:** Septiembre 2026
> **Ámbito:** Salud Digital, Adherencia Terapéutica Geriátrica, Accesibilidad Universal (WCAG AAA) y Soberanía de Datos (Leyes N° 20.584 y 19.628 de Chile).

---

## 1. Resumen Ejecutivo y Tesis Sanitaria

El olvido de medicamentos y la doble dosificación accidental (sobredosis) en adultos mayores constituyen la principal causa prevenible de hospitalizaciones geriátricas de urgencia a nivel global. En Chile y Latinoamérica, la polifarmacia crónica (hipertensión, diabetes, hipotiroidismo, dislipidemia) se gestiona habitualmente de forma fragmentada entre familiares y cuidadores.

**ChronoMed** introduce un paradigma disruptivo en el mercado: una **arquitectura bi-modal nativa** que separa radicalmente la interfaz del paciente (*Modo Senior*: cero fricción, pantalla única, botones $\ge 48$ dp, guiado por voz TTS, visualizador fotorrealista 3D con lupa táctil y bloqueo circadiano anti-sobredosis) de la interfaz de supervisión (*Modo Cuidador*: control de stock on-device, validación farmacológica ISP, alertas de omisión con escalamiento a WhatsApp y reportes PDF certificados con firma HMAC-SHA256).

Este documento compila el análisis exhaustivo de soluciones comerciales existentes y desarrollos de código abierto en GitHub / F-Droid, sirviendo como mapa de ruta para la ejecución de agentes y subagentes autónomos.

---

## 2. Benchmark de Aplicaciones Comerciales en el Mercado (iOS / Android)

### 2.1 Medisafe (Líder Comercial de Mercado)
* **Plataforma:** iOS / Android (Nativo) | **Descargas:** +10M
* **Propuesta Central:** Gestión integral de régimen de pastillas con alertas a cuidadores (*Medfriend*) y comprobación de interacciones en EE.UU.
* **Fortalezas:**
  * Red de monitoreo familiar a través de notificaciones push en la nube.
  * Selector visual de formas geométricas y colores de pastillas.
  * Historial clínico exportable para médicos.
* **Debilidades Críticas y Vulnerabilidades:**
  * **Pared de Pago (Paywall 2026):** Ha adoptado un modelo de suscripción agresivo (*Medisafe Premium*). Funciones vitales como interacciones avanzadas y múltiples cuidadores están bloqueadas.
  * **Sobrecarga Cognitiva:** Interfaz abarrotada de pestañas, anuncios, submenús y micro-botones que generan rechazo inmediato en ancianos con temblor o demencia leve.
  * **Fuga de Datos Sanitarios:** Obliga al usuario a registrarse en servidores cloud extranjeros, contraviniendo el principio de soberanía local exigido por la Ley Chilena N° 19.628.
  * **Ausencia de Bloqueo Anti-Sobredosis:** No inhabilita el botón tras pulsar; el paciente senil puede pulsar reiteradamente.

### 2.2 MyTherapy (smartpatient)
* **Plataforma:** iOS / Android | **Descargas:** +5M
* **Propuesta Central:** Diario de salud integral gratuito (medicamentos, presión, peso, glucosa, síntomas) con informes PDF para el médico.
* **Fortalezas:**
  * Modelo gratuito sin anuncios agresivos.
  * Generación de informes impresos limpios para la consulta clínica.
  * Recordatorios repetitivos de alta insistencia.
* **Debilidades Críticas frente a ChronoMed:**
  * **Interfaz de Smartphone Convencional:** No existe modo senior simplificado; el diseño no cumple contraste WCAG AAA ni objetivos táctiles mínimos de 48 dp.
  * **Sin Visualización 3D Real:** No permite distinguir pastillas similares con ranuras de partición o grabados en relieve.
  * **Reportes Sin Certificación Criptográfica:** Los PDF son estáticos y fácilmente alterables, careciendo de sellos HMAC de integridad.

### 2.3 Apple Health / Salud (Módulo Medicamentos, iOS)
* **Plataforma:** Exclusiva de iOS / watchOS
* **Propuesta Central:** Registro de medicamentos del sistema operativo con escaneo de etiquetas de frascos y verificación de interacciones (EE.UU.).
* **Fortalezas:**
  * Integración con Apple Watch y sensores de salud del dispositivo.
  * Privacidad local cifrada con Secure Enclave / iCloud Keychain.
* **Debilidades Críticas:**
  * **Exclusividad de Ecosistema:** Inaccesible para el 85%+ de la población geriátrica en Chile, cuyo perfil socioeconómico utiliza dispositivos Android de gama media/baja.
  * **Sin Escalamiento Activo a Redes Familiares:** No envía alertas automáticas a cuidadores remotos vía WhatsApp ante omisiones.

### 2.4 Otras Soluciones Comerciales
* **EveryDose:** Incorpora chatbot asistencial de IA; sin embargo, aumenta la fricción para pacientes que no pueden teclear ni leer textos pequeños.
* **Bearable:** Enfocado en la correlación de estados de ánimo y síntomas; excesivamente analítico para personas mayores.
* **Round Health:** Interfaz circular minimalista; carece de respaldo para cuidadores o módulos farmacológicos locales.

---

## 3. Benchmark de Desarrollos Open-Source (GitHub / F-Droid)

### 3.1 MedTimer (`Futsch1/medTimer`) — Estándar Abierto en F-Droid
* **Repositorio:** [github.com/Futsch1/medTimer](https://github.com/Futsch1/medTimer) (Licencia MIT, Kotlin / Android)
* **Propuesta:** Recordatorio de medicamentos 100% offline, respetuoso de la privacidad, sin anuncios ni telemetría.
* **Puntos Fuertes Identificados:**
  * **Soberanía y Cero Nube:** Almacenamiento local SQLite con respaldo/restauración JSON.
  * **Control de Inventario:** Contador de dosis remanentes con umbral de aviso.
  * **Snooze Geolocalizado:** Detección de llegada al hogar para reactivar la alarma omitida durante desplazamientos.
* **Brechas Abiertas que ChronoMed Resuelve:**
  * No cuenta con interfaz dedicada para el adulto mayor (usa Material 3 estándar para usuarios jóvenes).
  * No tiene sincronización ni rol de cuidador.
  * No incluye verificador de interacciones ni lectura OCR de recetas médicas.
  * Solo compatible con Android nativo (no multiplataforma como Flutter).

### 3.2 Repositorios Flutter en GitHub
* **[`yvanbinda/mediremind`](https://github.com/yvanbinda/mediremind):** Base en Flutter con GetX y SQFlite. Es un CRUD básico de recordatorios, útil como referencia de persistencia local pero sin medidas de seguridad clínica ni accesibilidad.
* **[`HossamElghamry/Mediminder`](https://github.com/HossamElghamry/Mediminder):** Patrón BLoC con notificaciones locales simples.
* **[`Ali-Hassanii/medicine_reminder`](https://github.com/Ali-Hassanii/medicine_reminder):** Incluye escaneo de código de barras. *(Falla práctica en geriatría: la mayoría de los medicamentos para adultos mayores se entregan en blísteres fraccionados en consultorios CESFAM donde el código de barras original no está disponible).*

---

## 4. Matriz Comparativa Multidimensional

| Dimensión / Característica | ChronoMed 🇨🇱 | Medisafe 🇺🇸 | MyTherapy 🇩🇪 | Apple Health 🍎 | MedTimer (GitHub) 🤖 |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Arquitectura Bi-Modal (Senior / Cuidador)** | ⭐⭐⭐⭐⭐ **Nativa** | ⭐⭐ Solo push | ⭐ No | ⭐ No | ⭐ No |
| **Modo Senior Cero Fricción (Pantalla Única)** | ⭐⭐⭐⭐⭐ **1 Botón + TTS**| ⭐ No | ⭐ No | ⭐ No | ⭐ No |
| **Áreas Táctiles WCAG AAA ($\ge 48$ dp)** | ⭐⭐⭐⭐⭐ **96 dp máx** | ⭐⭐ $\le 40$ dp | ⭐⭐ $\le 40$ dp | ⭐⭐⭐ 44 dp | ⭐⭐⭐ 48 dp estándar |
| **Bloqueo Anti-Sobredosis Circadiano** | ⭐⭐⭐⭐⭐ **Activo** | ⭐ No | ⭐ No | ⭐ No | ⭐ No |
| **Visualizador 3D & Lupa Táctil** | ⭐⭐⭐⭐⭐ **Físico / Ranura**| ⭐⭐ Iconos planos | ⭐ No | ⭐⭐ Formas básicas | ⭐ No |
| **Alerta Escalamiento Cuidador (+45 min)**| ⭐⭐⭐⭐⭐ **WhatsApp Direct**| ⭐⭐⭐ Solo Cloud | ⭐ No | ⭐ No | ⭐ No |
| **Privacidad 100% Offline / Cero Telemetría**| ⭐⭐⭐⭐⭐ **Leyes 20.584/19.628**| ⭐ Fuga Cloud | ⭐ Requiere Cloud | ⭐⭐⭐ Mixto | ⭐⭐⭐⭐⭐ **Offline** |
| **Interacciones Clínicas Locales** | ⭐⭐⭐⭐⭐ **Vademécum ISP** | ⭐⭐⭐ Solo FDA | ⭐ No | ⭐⭐⭐ Solo FDA | ⭐ No |
| **Escáner OCR On-Device (Recetas/Cajas)**| ⭐⭐⭐⭐⭐ **Visión Local** | ⭐ No | ⭐ No | ⭐⭐ Solo frascos | ⭐ No |
| **Reportes Certificados Criptográficamente**| ⭐⭐⭐⭐⭐ **PDF + HMAC** | ⭐ PDF simple | ⭐ PDF simple | ⭐ Export XML | ⭐ CSV plano |
| **Modelo de Costo** | 🟢 **100% Libre / Soberano**| 🔴 Suscripción | 🟢 Gratuito | 🟢 Requiere iPhone | 🟢 Código Abierto |

---

## 5. El "Foso Estratégico" de ChronoMed (Diferenciadores Clave)

1. **Simplicidad Innegociable para el Adulto Mayor:** Ninguna otra aplicación reduce la complejidad a un único botón interactivo con voz sintética, contraste WCAG AAA e inhabilitación inmediata tras la ingesta para prevenir intoxicaciones.
2. **Identificador Físico de Pastillas con Lupa Táctil:** El paciente de la tercera edad no lee miligramos ni nombres químicos complejos (e.g. *Atorvastatina cálcica trihidrato*); reconoce *"la pastilla redonda azul con el número 50 y la ranura al medio"*. ChronoMed es la primera solución que dibuja fielmente el fármaco en pantalla y permite ampliarlo al instante.
3. **Adaptación Cultural y Sanitaria Chilena:** Integración de los 4 momentos circadianos de alimentación chilena (Desayuno, Almuerzo, Once, Noche), compatible con esquemas de consultorios CESFAM, programas GES/AUGE y bioequivalencia del ISP.
4. **Soberanía y Respeto a los Derechos del Paciente:** Cero cuentas, cero login, cero servidores intermediarios. Los datos residen exclusivamente en el almacenamiento local del dispositivo mediante JSON atómico.

---

## 6. Oportunidades y Roadmap para Agentes Autónomos (Robots)

Los agentes autónomos que continúen la evolución de ChronoMed deben priorizar las siguientes iniciativas:

### 🤖 Misión 1: Sincronización P2P Local (Wi-Fi LAN / Bluetooth BLE)
* **Objetivo:** Permitir que el teléfono del Senior transmita la confirmación de la toma al teléfono del Cuidador cuando ambos dispositivos están en la misma red Wi-Fi o dentro del alcance Bluetooth, sin pasar jamás por un servidor en internet.
* **Stack sugerido:** `bonsoir` (mDNS/ZeroConf) o `flutter_nearby_connections` (Nearby Share API).

### 🤖 Misión 2: Personalización de Alarma con la Voz del Familiar
* **Objetivo:** Permitir al cuidador grabar audios de 5 segundos (*"Papá, tómate la pastilla azul"*) que sustituyan al motor TTS del sistema.
* **Justificación Clínica:** La evidencia en geriatría demuestra una reducción del 60% en el rechazo a medicamentos en pacientes con demencia cuando la instrucción proviene de la voz familiar.

### 🤖 Misión 3: Snooze Inteligente por Reconexión de Red (Inspirado en MedTimer)
* **Objetivo:** Si una dosis no fue tomada en horario porque el paciente estaba fuera de casa, reactivar suavemente el recordatorio tan pronto el dispositivo se reconecta a la red Wi-Fi residencial.

### 🤖 Misión 4: Reconocimiento OCR Ampliado para Cajas Farmacéuticas del ISP
* **Objetivo:** Entrenar y afinar el parser on-device para leer el código de registro ISP (e.g. `F-12345/22`), fecha de vencimiento `VENC MM/AAAA` y lote directamente desde el empaque de medicamentos comunes en farmacias chilenas (Ahumada, Cruz Verde, Salcobrand, Farmacias Populares).

---

## 7. Protocolo de Auditoría y Verificación para Robots

Cada agente que implemente una mejora del roadmap debe satisfacer:
1. **Compilación y Tests:** Toda adición debe mantener al 100% la aprobación del pipeline de GitHub Actions (`.github/workflows/build_apk.yml`).
2. **Accesibilidad Obligatoria:** Ningún botón puede tener dimensiones menores a $48 \times 48$ dp. Todo elemento dinámico debe contar con `Semantics(liveRegion: true)` si anuncia cambios al usuario ciego o de baja visión.
3. **Sincronización de Manuales:** Mantener correspondencia exacta y hash SHA-256 idéntico entre `MANUAL_USUARIO.md` y `docs/MANUAL_USUARIO.md`.
