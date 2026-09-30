import { TokenService } from '../../src/modules/security/services/token.service';

describe('TokenService (Vinculación QR Seguro)', () => {
  const service = new TokenService('11223344556677889900aabbccddeeff11223344556677889900aabbccddeeff');

  it('debe generar y verificar exitosamente un pairing token', () => {
    const token = service.generatePairingToken('caregiver-123', 'patient-456');
    expect(token).toBeDefined();

    const payload = service.verifyPairingToken(token);
    expect(payload.caregiverId).toBe('caregiver-123');
    expect(payload.patientId).toBe('patient-456');
    expect(payload.nonce).toBeDefined();
  });

  it('debe rechazar un token manipulado', () => {
    const token = service.generatePairingToken('caregiver-123', 'patient-456');
    const manipulated = token.slice(0, -5) + 'abcde';
    expect(() => service.verifyPairingToken(manipulated)).toThrow();
  });
});
