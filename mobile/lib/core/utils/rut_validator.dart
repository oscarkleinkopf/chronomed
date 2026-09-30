/// Utilidad de validación de RUT chileno con módulo 11 y formateo automático.
class RutValidator {
  /// Valida un RUT chileno incluyendo el dígito verificador.
  /// Acepta formatos: '12345678-K', '12.345.678-K', '12345678K', '12345678k'
  static bool isValid(String rut) {
    final cleaned = _clean(rut);
    if (cleaned.length < 2) return false;

    final body = cleaned.substring(0, cleaned.length - 1);
    final expectedDv = cleaned[cleaned.length - 1].toUpperCase();

    final digits = int.tryParse(body);
    if (digits == null || digits < 1000000 || digits > 99999999) return false;

    final computedDv = _computeDv(body);
    return computedDv == expectedDv;
  }

  /// Formatea un RUT en el estilo chileno estándar: XX.XXX.XXX-Y
  static String format(String rut) {
    final cleaned = _clean(rut);
    if (cleaned.length < 2) return rut;

    final body = cleaned.substring(0, cleaned.length - 1);
    final dv = cleaned[cleaned.length - 1].toUpperCase();

    // Insertar puntos de miles
    final reversed = body.split('').reversed.toList();
    final parts = <String>[];
    for (int i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) parts.add('.');
      parts.add(reversed[i]);
    }
    final formatted = parts.reversed.join('');

    return '$formatted-$dv';
  }

  /// Calcula el dígito verificador de un RUT.
  static String _computeDv(String body) {
    int sum = 0;
    int multiplier = 2;

    for (int i = body.length - 1; i >= 0; i--) {
      sum += int.parse(body[i]) * multiplier;
      multiplier = (multiplier == 7) ? 2 : multiplier + 1;
    }

    final remainder = 11 - (sum % 11);
    if (remainder == 11) return '0';
    if (remainder == 10) return 'K';
    return remainder.toString();
  }

  /// Limpia un RUT removiendo puntos, guiones y espacios.
  static String _clean(String rut) {
    return rut.replaceAll('.', '').replaceAll('-', '').replaceAll(' ', '').trim();
  }

  /// Mensaje de error para validación de formulario, o null si es válido.
  static String? validate(String? value) {
    if (value == null || value.trim().isEmpty) return 'Ingresa el RUT';
    if (!isValid(value)) return 'RUT inválido (ej: 14.567.890-K)';
    return null;
  }
}
