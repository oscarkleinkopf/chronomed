export interface EncryptedPayload {
  cipherText: string;
  iv: string;
  authTag: string;
  version: string;
}

export type UserRole = 'PATIENT' | 'CAREGIVER' | 'SYSTEM' | 'HEALTH_STAFF' | 'ADMIN';

export type AuditAction = 
  | 'READ' 
  | 'CREATE' 
  | 'UPDATE' 
  | 'DELETE' 
  | 'EXPORT_PDF' 
  | 'CONSENT_GRANTED' 
  | 'CONSENT_REVOKED'
  | 'OVERDOSE_PREVENTED'
  | 'PAIRING_ATTEMPT';

export type AuditResourceType = 
  | 'PATIENT_PROFILE' 
  | 'MEDICATION' 
  | 'INTAKE_LOG' 
  | 'CONSENT' 
  | 'PRESCRIPTION_OCR' 
  | 'CARE_RELATIONSHIP';

export interface AuditLogEntry {
  id: string;
  timestamp: string;
  actorId: string;
  actorRole: UserRole;
  patientId: string;
  action: AuditAction;
  resourceType: AuditResourceType;
  resourceId: string;
  metadata?: Record<string, unknown>;
  previousHash: string;
  integrityChecksum: string;
}

export interface PairingTokenPayload {
  caregiverId: string;
  patientId: string;
  nonce: string;
  expiresAt: number;
  issuedAt: number;
}
