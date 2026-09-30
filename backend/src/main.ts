import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Prefijo global de API
  app.setGlobalPrefix('api/v1');

  // Habilitar CORS para cliente móvil y web
  app.enableCors({
    origin: '*',
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS',
    credentials: true,
  });

  // Validación estricta de DTOs
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: false,
    }),
  );

  // Documentación OpenAPI / Swagger
  const config = new DocumentBuilder()
    .setTitle('ChronoMed API & Motores Clínicos')
    .setDescription(
      'Servidor de respaldo y sincronización para ChronoMed. Cumple con normativas chilenas de salud (Leyes N° 20.584 y 19.628) con cifrado AES-256-GCM y Blind Index HMAC-SHA256.',
    )
    .setVersion('1.0.0')
    .addTag('Patients & Intakes', 'Ficha clínica, tomas programadas y confirmación con auditoría')
    .addTag('Cloud & P2P Sync', 'Sincronización bidireccional y recepción P2P')
    .addTag('Clinical Interactions', 'Verificación de contraindicaciones y restricciones alimentarias')
    .addTag('Smart Inventory', 'Proyección de agotamiento de stock y compras preventivas')
    .addTag('Clinical Analytics & Audit (Ley 20.584)', 'Ficha clínica digital e informes de adherencia firmados')
    .addBearerAuth()
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document);

  const port = process.env.PORT || 3000;
  await app.listen(port);

  console.log(`🚀 ChronoMed Backend en ejecución en: http://localhost:${port}/api/v1`);
  console.log(`📚 Documentación Swagger disponible en: http://localhost:${port}/api/docs`);
}

bootstrap();
