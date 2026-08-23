# ChronoMed ⏰💊

> **Sincronización Inteligente de Medicación y Adherencia Clínica con Interfaz Dual**

ChronoMed es una plataforma de salud diseñada para resolver la falta de adherencia en tratamientos médicos crónicos y agudos. Cuenta con una arquitectura dual dividida en:
- **Modo Estándar (Cuidador/General):** Gestión integral de recetas, OCR on-device, motor de interacciones farmacológicas, control predictivo de farmacia y reportes médicos.
- **Modo Senior (Simple / Cero Fricción):** Pantalla única de acción, soporte auditivo (TTS), tarjetas de alto contraste (WCAG AAA), iconografía temporal (☀️ 🍲 ☕ 🌙) y **Bloqueo Anti-Sobredosis**.

---

## 🛡️ Seguridad y Cumplimiento Legal (Chile)
- **Ley N° 20.584:** Trazabilidad inmutable con *Hash Chaining* en registros de auditoría (`AuditLog`).
- **Ley N° 19.628:** Cifrado AES-256-GCM para datos clínicos sensibles y *Blind Indexing* para búsquedas seguras por RUT.
- **Fail-Safe Offline:** Alarmas críticas que funcionan 100% sin conexión a internet.
