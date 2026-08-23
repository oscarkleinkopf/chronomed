# 🛡️ Reglas de Desarrollo y Arquitectura — ChronoMed

1. **Cumplimiento Ley 20.584 y 19.628 (Chile):**
   - Toda consulta y cambio de datos médicos genera un log inmutable con Hash Chaining.
   - Cifrado AES-256-GCM en reposo y Blind Indexing para búsquedas por RUT.
   - Cero PII en logs de consola.
2. **Aislamiento del Modo Senior (Flutter):**
   - El Modo Senior nunca debe importar menús ni componentes con alta densidad informativa.
   - Botones de acción táctil >= 80dp de altura y contraste WCAG AAA.
   - Bloqueo Anti-Sobredosis obligatorio tras confirmar toma.
3. **Motor Clínico Determinista:**
   - Horarios calculados en UTC y proyectados localmente.
   - Recálculo ante desfase si el tiempo restante es < 75% del intervalo para prevenir toxicidad.
4. **Alarmas Fail-Safe:**
   - Notificaciones locales exactas (AlarmManager/ExactAlarms) con sonido diferencial y activación en pantalla bloqueada.
