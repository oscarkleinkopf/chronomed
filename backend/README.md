# ChronoMed Backend & Motores Clínicos 🏥🇨🇱

Servidor de respaldo y sincronización cloud para la plataforma **ChronoMed**, diseñado con soberanía de datos y estricto apego al marco regulatorio chileno de salud (**Ley N° 20.584** sobre Derechos y Deberes de los Pacientes y **Ley N° 19.628** sobre Protección de la Vida Privada).

---

## 🛡️ Arquitectura de Seguridad y Privacidad

- **Cifrado AES-256-GCM:** Toda la información de identificación personal (RUT, nombre completo, teléfonos de emergencia) se almacena cifrada en reposo.
- **Blind Index HMAC-SHA256:** Búsqueda rápida y segura de pacientes mediante hash ciego salado, sin exponer el RUT en texto claro ni permitir enumeración.
- **Cadena de Auditoría Criptográfica:** Trazabilidad inalterable de lecturas, modificaciones y confirmaciones de tomas mediante encadenamiento de hashes SHA-256 (estilo blockchain liviano).
- **Tokens de Vinculación QR Efímeros:** Emparejamiento seguro entre cuidador y paciente con tokens HMAC-SHA256 y caducidad estricta (10 minutos).

---

## 💊 Motores Clínicos Incluidos

1. **ScheduleEngine:** Cálculo de horarios adaptados al ciclo circadiano del paciente (desayuno, almuerzo, once, cena, antes de dormir, ayunas).
2. **DynamicRescheduleEngine:** Prevención de acumulación y toxicidad farmacológica ante tomas tardías (ajuste dinámico de la ventana de la siguiente dosis).
3. **InteractionEngine:** Detección de contraindicaciones críticas (ej. AINEs + Anticoagulantes, Estatinas + Macrólidos) y restricciones alimentarias (Levotiroxina con lácteos/calcio, Metformina con alcohol).
4. **InventoryEngine:** Proyección matemática de agotamiento de stock en el botiquín y aviso anticipado si cae en fin de semana para evitar quiebre de stock.
5. **ClinicalReportGeneratorService:** Generación de informes clínicos de adherencia firmados digitalmente para el médico tratante.

---

## 🚀 Puesta en Marcha

### Prerrequisitos
- Node.js >= 18
- Docker & Docker Compose (opcional para PostgreSQL local)

### 1. Variables de Entorno
Copiar el archivo de ejemplo:
```bash
cp .env.example .env
```

### 2. Base de Datos Local
Iniciar el contenedor PostgreSQL:
```bash
docker-compose up -d
```

### 3. Generar Cliente Prisma
```bash
npm run prisma:generate
```

### 4. Ejecutar Migraciones y Seeding
```bash
npm run prisma:migrate
npx ts-node prisma/seed.ts
```

### 5. Iniciar Servidor en Desarrollo
```bash
npm run start:dev
```
- API Base: `http://localhost:3000/api/v1`
- Swagger Docs: `http://localhost:3000/api/docs`

---

## 🧪 Pruebas Automatizadas

Ejecución de la suite completa de pruebas unitarias y de integración (Jest):
```bash
npm test
```

---

## 📡 Endpoints Principales

| Método | Endpoint | Descripción |
|---|---|---|
| `GET` | `/api/v1/patients/:id/intakes/today` | Tomas programadas para el día actual (consumido por la app móvil) |
| `POST` | `/api/v1/patients/:id/intakes/:intakeId/confirm` | Confirmación de toma con auditoría y descuento de inventario |
| `POST` | `/api/v1/sync/push` | Sincronización batch de rutina, botiquín y tomas locales |
| `GET` | `/api/v1/sync/pull/:patientId` | Descarga de estado consolidado desde la nube |
| `POST` | `/api/v1/sync/intake` | Recepción de tomas individuales (compatible con P2P local) |
| `POST` | `/api/v1/interactions/check` | Evaluación de interacciones y restricciones |
| `POST` | `/api/v1/inventory/depletion` | Cálculo predictivo de quiebre de stock |
| `GET` | `/api/v1/analytics/patients/:id/report` | Informe de adherencia Ley 20.584 |
