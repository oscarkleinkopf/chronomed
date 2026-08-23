import { EncryptionService } from '../../src/modules/security/services/encryption.service';
import { AuditService } from '../../src/modules/security/services/audit.service';

describe('Security Services (Cifrado & Auditoría Ley 20.584)', () => {
  const enc = new EncryptionService('0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef', 'fedcba9876543210fedcba9876543210fedcba9876543210fedcba9876543210');
  const audit = new AuditService('abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789');

  it('debe cifrar y descifrar con integridad AES-GCM', () => {
    const rut = '12.345.678-9';
    const encrypted = enc.encrypt(rut);
    expect(enc.decrypt(encrypted)).toBe(rut);
  });

  it('debe encadenar hashes en los logs de auditoría', () => {
    const entry1 = audit.createAuditEntry({
      actorId: 'user-1', actorRole: 'CAREGIVER', patientId: 'pat-1', action: 'READ', resourceType: 'MEDICATION', resourceId: 'med-1',
    });
    const entry2 = audit.createAuditEntry({
      actorId: 'user-1', actorRole: 'CAREGIVER', patientId: 'pat-1', action: 'UPDATE', resourceType: 'INTAKE_LOG', resourceId: 'log-1',
    });
    expect(entry2.previousHash).toBe(entry1.integrityChecksum);
  });
});
