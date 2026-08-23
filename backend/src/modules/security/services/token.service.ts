import * as crypto from 'crypto';
import { PairingTokenPayload } from '../types/security.types';

export class TokenService {
  private readonly tokenSecret: Buffer;
  private readonly tokenTtlSeconds = 600;

  constructor(tokenSecretHex?: string) {
    const secret = tokenSecretHex || process.env.PAIRING_TOKEN_SECRET || '11223344556677889900aabbccddeeff11223344556677889900aabbccddeeff';
    this.tokenSecret = Buffer.from(secret, 'hex');
  }

  public generatePairingToken(caregiverId: string, patientId: string): string {
    const issuedAt = Math.floor(Date.now() / 1000);
    const expiresAt = issuedAt + this.tokenTtlSeconds;
    const nonce = crypto.randomBytes(16).toString('hex');

    const payload: PairingTokenPayload = {
      caregiverId,
      patientId,
      nonce,
      issuedAt,
      expiresAt,
    };

    const payloadBase64 = Buffer.from(JSON.stringify(payload)).toString('base64url');
    const signature = crypto
      .createHmac('sha256', this.tokenSecret)
      .update(payloadBase64)
      .digest('base64url');

    return `${payloadBase64}.${signature}`;
  }

  public verifyPairingToken(token: string): PairingTokenPayload {
    const parts = token.split('.');
    if (parts.length !== 2) {
      throw new Error('Formato de token inválido.');
    }

    const [payloadBase64, signature] = parts;
    const expectedSignature = crypto
      .createHmac('sha256', this.tokenSecret)
      .update(payloadBase64)
      .digest('base64url');

    if (!crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(expectedSignature))) {
      throw new Error('Firma criptográfica del código QR no válida.');
    }

    const payload: PairingTokenPayload = JSON.parse(
      Buffer.from(payloadBase64, 'base64url').toString('utf8'),
    );

    const now = Math.floor(Date.now() / 1000);
    if (now > payload.expiresAt) {
      throw new Error('El código QR ha expirado.');
    }

    return payload;
  }
}
