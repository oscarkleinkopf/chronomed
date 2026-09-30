import { Global, Module } from '@nestjs/common';
import { EncryptionService } from './services/encryption.service';
import { AuditService } from './services/audit.service';
import { TokenService } from './services/token.service';

@Global()
@Module({
  providers: [EncryptionService, AuditService, TokenService],
  exports: [EncryptionService, AuditService, TokenService],
})
export class SecurityModule {}
