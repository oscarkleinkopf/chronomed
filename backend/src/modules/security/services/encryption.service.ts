import * as crypto from 'crypto';

export class EncryptionService {
  private readonly algorithm = 'aes-256-gcm';
  private readonly masterKey: Buffer;
  private readonly searchPepper: Buffer;

  constructor(masterKeyHex?: string, searchPepperHex?: string) {
    const keyString = masterKeyHex || process.env.ENCRYPTION_MASTER_KEY || '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
    const pepperString = searchPepperHex || process.env.SEARCH_PEPPER_KEY || 'fedcba9876543210fedcba9876543210fedcba9876543210fedcba9876543210';
    this.masterKey = Buffer.from(keyString, 'hex');
    this.searchPepper = Buffer.from(pepperString, 'hex');
  }

  public encrypt(plainText: string) {
    const iv = crypto.randomBytes(12);
    const cipher = crypto.createCipheriv(this.algorithm, this.masterKey, iv, { authTagLength: 16 });
    let encrypted = cipher.update(plainText, 'utf8', 'base64');
    encrypted += cipher.final('base64');
    return {
      cipherText: encrypted,
      iv: iv.toString('base64'),
      authTag: cipher.getAuthTag().toString('base64'),
    };
  }

  public decrypt(payload: { cipherText: string; iv: string; authTag: string }) {
    const decipher = crypto.createDecipheriv(this.algorithm, this.masterKey, Buffer.from(payload.iv, 'base64'), { authTagLength: 16 });
    decipher.setAuthTag(Buffer.from(payload.authTag, 'base64'));
    let decrypted = decipher.update(payload.cipherText, 'base64', 'utf8');
    decrypted += decipher.final('utf8');
    return decrypted;
  }

  public generateBlindIndex(value: string): string {
    const normalized = value.trim().toUpperCase().replace(/[^0-9K]/g, '');
    return crypto.createHmac('sha256', this.searchPepper).update(normalized).digest('hex');
  }
}
