import * as crypto from 'crypto';
import { AuditAction, AuditLogEntry, AuditResourceType, UserRole } from '../types/security.types';

export class AuditService {
  private readonly auditSecret: Buffer;
  private lastHash: string = 'GENESIS_BLOCK_HASH_CHRONOMED_2026';

  constructor(auditSecretHex?: string) {
    const secret = auditSecretHex || process.env.AUDIT_HMAC_SECRET || 'abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789';
    this.auditSecret = Buffer.from(secret, 'hex');
  }

  public setLastKnownHash(hash: string): void {
    if (hash && hash.length > 0) {
      this.lastHash = hash;
    }
  }

  public createAuditEntry(params: {
    actorId: string;
    actorRole: UserRole;
    patientId: string;
    action: AuditAction;
    resourceType: AuditResourceType;
    resourceId: string;
    metadata?: Record<string, unknown>;
  }): AuditLogEntry {
    const id = crypto.randomUUID();
    const timestamp = new Date().toISOString();
    const previousHash = this.lastHash;
    const sanitizedMetadata = this.sanitizeMetadata(params.metadata);

    const payloadToSign = [
      id,
      timestamp,
      params.actorId,
      params.actorRole,
      params.patientId,
      params.action,
      params.resourceType,
      params.resourceId,
      JSON.stringify(sanitizedMetadata || {}),
      previousHash,
    ].join('|');

    const integrityChecksum = crypto
      .createHmac('sha256', this.auditSecret)
      .update(payloadToSign)
      .digest('hex');

    const entry: AuditLogEntry = {
      id,
      timestamp,
      actorId: params.actorId,
      actorRole: params.actorRole,
      patientId: params.patientId,
      action: params.action,
      resourceType: params.resourceType,
      resourceId: params.resourceId,
      metadata: sanitizedMetadata,
      previousHash,
      integrityChecksum,
    };

    this.lastHash = integrityChecksum;
    return entry;
  }

  private sanitizeMetadata(meta?: Record<string, unknown>): Record<string, unknown> | undefined {
    if (!meta) return undefined;
    const forbiddenKeys = ['rut', 'password', 'pin', 'fullname', 'email', 'phone'];
    const sanitized: Record<string, unknown> = {};

    for (const [key, value] of Object.entries(meta)) {
      if (!forbiddenKeys.includes(key.toLowerCase())) {
        sanitized[key] = value;
      } else {
        sanitized[key] = '[REDACTED_FOR_PRIVACY]';
      }
    }
    return sanitized;
  }
}
