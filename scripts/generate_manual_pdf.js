const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const marked = require('../docs/js/marked.min.js');

function getBase64Image(filePath) {
  try {
    const fullPath = path.resolve(filePath);
    if (!fs.existsSync(fullPath)) return null;
    const ext = path.extname(fullPath).toLowerCase();
    const mime = ext === '.png' ? 'image/png' : 'image/jpeg';
    const data = fs.readFileSync(fullPath).toString('base64');
    return `data:${mime};base64,${data}`;
  } catch (e) {
    console.error(`Error encoding image ${filePath}:`, e);
    return null;
  }
}

async function run() {
  console.log('🚀 Iniciando generador de Manual de Usuario en PDF de Alta Calidad Gráfica...');
  
  const manualMdPath = path.resolve('MANUAL_USUARIO.md');
  let mdContent = fs.readFileSync(manualMdPath, 'utf8');

  // Convert image references to Base64 data URIs
  const imageMap = {
    'assets/app_icon.png': getBase64Image('assets/app_icon.png'),
    'assets/app_icon.jpg': getBase64Image('assets/app_icon.jpg'),
    'assets/banner.jpg': getBase64Image('assets/banner.jpg'),
    'assets/dashboard_banner.jpg': getBase64Image('assets/dashboard_banner.jpg'),
    'assets/feature_senior_mode.jpg': getBase64Image('assets/feature_senior_mode.jpg'),
    'assets/feature_ocr_scan.jpg': getBase64Image('assets/feature_ocr_scan.jpg'),
    'assets/feature_pharmacy_stock.jpg': getBase64Image('assets/feature_pharmacy_stock.jpg'),
    'assets/feature_clinical_report.jpg': getBase64Image('assets/feature_clinical_report.jpg'),
    'assets/feature_drug_safety.jpg': getBase64Image('assets/feature_drug_safety.jpg')
  };

  for (const [relPath, b64] of Object.entries(imageMap)) {
    if (b64) {
      mdContent = mdContent.split(relPath).join(b64);
    }
  }

  // Configure marked custom renderer
  const renderer = {
    code({ text, lang }) {
      if (lang === 'mermaid') {
        return `<div class="diagram-wrapper"><div class="mermaid">${text}</div></div>`;
      }
      return false; // default code block
    }
  };
  marked.use({ renderer });

  // Convert markdown to HTML
  console.log('📄 Procesando Markdown con Marked...');
  let htmlBody = marked.parse(mdContent);

  // Enhance callouts and alerts in HTML
  htmlBody = htmlBody.replace(/<blockquote>\s*<h3[^>]*>⚠️\s*([^<]+)<\/h3>/g, '<div class="callout callout-warning"><div class="callout-header"><span class="callout-icon">⚠️</span> $1</div>');
  htmlBody = htmlBody.replace(/<blockquote>\s*<h3[^>]*>🔒\s*([^<]+)<\/h3>/g, '<div class="callout callout-security"><div class="callout-header"><span class="callout-icon">🔒</span> $1</div>');
  htmlBody = htmlBody.replace(/<blockquote>\s*<h3[^>]*>🚨\s*([^<]+)<\/h3>/g, '<div class="callout callout-critical"><div class="callout-header"><span class="callout-icon">🚨</span> $1</div>');
  htmlBody = htmlBody.replace(/<blockquote>\s*<h3[^>]*>💡\s*([^<]+)<\/h3>/g, '<div class="callout callout-info"><div class="callout-header"><span class="callout-icon">💡</span> $1</div>');
  htmlBody = htmlBody.replace(/<\/blockquote>/g, '</div>');

  // Mermaid JS script
  const mermaidScript = fs.readFileSync('docs/js/mermaid.min.js', 'utf8');

  // Complete HTML Template
  const fullHtml = `<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>ChronoMed — Manual de Usuario Maestro (v1.0.0)</title>
  <style>
    @page {
      size: A4 portrait;
      margin: 16mm 14mm 18mm 14mm;
      @bottom-left {
        content: "ChronoMed v1.0.0 — Manual de Usuario Maestro";
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
        font-size: 8pt;
        color: #64748B;
      }
      @bottom-right {
        content: "Página " counter(page);
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
        font-size: 8pt;
        font-weight: 600;
        color: #2563EB;
      }
    }

    * {
      box-sizing: border-box;
      -webkit-print-color-adjust: exact !important;
      print-color-adjust: exact !important;
    }

    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
      font-size: 10pt;
      line-height: 1.6;
      color: #1E293B;
      background-color: #FFFFFF;
      margin: 0;
      padding: 0;
    }

    /* Cover Page */
    .cover-page {
      page-break-after: always;
      break-after: page;
      min-height: 98vh;
      background: linear-gradient(135deg, #0B132B 0%, #0F172A 50%, #1E293B 100%);
      color: #FFFFFF;
      padding: 40px 30px;
      display: flex;
      flex-direction: column;
      justify-content: space-between;
      border-radius: 12px;
      position: relative;
      overflow: hidden;
    }

    .cover-top {
      display: flex;
      justify-content: space-between;
      align-items: center;
      border-bottom: 1px solid rgba(255, 255, 255, 0.15);
      padding-bottom: 20px;
    }

    .cover-badge-chile {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      background: rgba(255, 255, 255, 0.1);
      border: 1px solid rgba(255, 255, 255, 0.2);
      padding: 6px 14px;
      border-radius: 20px;
      font-size: 9pt;
      font-weight: 600;
      letter-spacing: 0.5px;
    }

    .cover-center {
      text-align: center;
      margin: 40px 0;
    }

    .cover-icon {
      width: 140px;
      height: 140px;
      border-radius: 32px;
      box-shadow: 0 16px 36px rgba(0, 210, 255, 0.35);
      margin-bottom: 24px;
      border: 2px solid rgba(0, 210, 255, 0.5);
    }

    .cover-title {
      font-size: 38pt;
      font-weight: 900;
      letter-spacing: -1px;
      margin: 0;
      background: linear-gradient(90deg, #FFFFFF 0%, #00D2FF 100%);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
    }

    .cover-subtitle {
      font-size: 15pt;
      font-weight: 600;
      color: #94A3B8;
      margin-top: 10px;
      max-width: 600px;
      margin-left: auto;
      margin-right: auto;
      line-height: 1.4;
    }

    .cover-doc-type {
      display: inline-block;
      margin-top: 24px;
      background: rgba(37, 99, 235, 0.25);
      color: #60A5FA;
      border: 1px solid rgba(96, 165, 250, 0.4);
      padding: 8px 22px;
      border-radius: 8px;
      font-size: 11pt;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 1px;
    }

    .cover-badges-grid {
      display: grid;
      grid-template-columns: repeat(3, 1fr);
      gap: 12px;
      margin-top: 20px;
    }

    .badge-card {
      background: rgba(255, 255, 255, 0.05);
      border: 1px solid rgba(255, 255, 255, 0.1);
      border-radius: 10px;
      padding: 10px 12px;
      text-align: left;
    }

    .badge-card-title {
      font-size: 8.5pt;
      font-weight: 700;
      color: #38BDF8;
      margin-bottom: 3px;
    }

    .badge-card-desc {
      font-size: 7.5pt;
      color: #94A3B8;
      line-height: 1.3;
    }

    .cover-bottom {
      border-top: 1px solid rgba(255, 255, 255, 0.15);
      padding-top: 16px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      font-size: 8.5pt;
      color: #94A3B8;
    }

    /* Headings */
    h1, h2, h3, h4 {
      color: #0F172A;
      break-after: avoid;
      page-break-after: avoid;
    }

    h2 {
      page-break-before: always;
      break-before: page;
      font-size: 18pt;
      font-weight: 800;
      border-bottom: 2.5px solid #2563EB;
      padding-bottom: 8px;
      margin-top: 30px;
      margin-bottom: 16px;
      letter-spacing: -0.5px;
    }

    /* First h2 right after cover shouldn't break page twice */
    .content > h2:first-of-type {
      page-break-before: avoid;
      break-before: avoid;
    }

    h3 {
      font-size: 13pt;
      font-weight: 700;
      color: #1E293B;
      margin-top: 22px;
      margin-bottom: 10px;
      border-left: 3px solid #00D2FF;
      padding-left: 8px;
    }

    h4 {
      font-size: 11pt;
      font-weight: 600;
      color: #334155;
      margin-top: 16px;
      margin-bottom: 6px;
    }

    p {
      margin: 8px 0;
      text-align: justify;
    }

    ul, ol {
      margin: 8px 0;
      padding-left: 24px;
    }

    li {
      margin-bottom: 4px;
    }

    /* Tables */
    table {
      width: 100%;
      border-collapse: collapse;
      margin: 16px 0;
      font-size: 8.5pt;
      page-break-inside: avoid;
      break-inside: avoid;
      border-radius: 8px;
      overflow: hidden;
      box-shadow: 0 1px 3px rgba(0,0,0,0.05);
    }

    th {
      background-color: #1E293B;
      color: #FFFFFF;
      font-weight: 700;
      padding: 9px 10px;
      text-align: left;
      border: 1px solid #334155;
    }

    td {
      padding: 7px 10px;
      border: 1px solid #CBD5E1;
      vertical-align: top;
    }

    tr:nth-child(even) td {
      background-color: #F8FAFC;
    }

    /* Images */
    img {
      max-width: 100%;
      height: auto;
      border-radius: 10px;
      box-shadow: 0 4px 14px rgba(0, 0, 0, 0.08);
      margin: 14px auto;
      display: block;
      page-break-inside: avoid;
      break-inside: avoid;
    }

    /* Callouts & Alerts */
    .callout {
      border-radius: 8px;
      padding: 14px 16px;
      margin: 16px 0;
      page-break-inside: avoid;
      break-inside: avoid;
      font-size: 9pt;
      line-height: 1.5;
    }

    .callout-header {
      font-weight: 800;
      font-size: 10pt;
      margin-bottom: 6px;
      display: flex;
      align-items: center;
      gap: 6px;
    }

    .callout-warning {
      background-color: #FEF2F2;
      border: 1px solid #FCA5A5;
      border-left: 5px solid #EF4444;
      color: #991B1B;
    }

    .callout-security {
      background-color: #F0F9FF;
      border: 1px solid #BAE6FD;
      border-left: 5px solid #0284C7;
      color: #0369A1;
    }

    .callout-critical {
      background-color: #FFF1F2;
      border: 1px solid #FECDD3;
      border-left: 5px solid #E11D48;
      color: #881337;
    }

    .callout-info {
      background-color: #ECFDF5;
      border: 1px solid #A7F3D0;
      border-left: 5px solid #10B981;
      color: #065F46;
    }

    /* Diagrams */
    .diagram-wrapper {
      margin: 20px 0;
      padding: 16px;
      background: #F8FAFC;
      border: 1px solid #E2E8F0;
      border-radius: 12px;
      page-break-inside: avoid;
      break-inside: avoid;
      text-align: center;
    }

    .mermaid {
      display: flex;
      justify-content: center;
      font-size: 9pt;
    }

    /* Code & Mono */
    code {
      font-family: "SFMono-Regular", Consolas, "Liberation Mono", Menlo, monospace;
      font-size: 8.5pt;
      background-color: #F1F5F9;
      color: #0F172A;
      padding: 2px 5px;
      border-radius: 4px;
      border: 1px solid #E2E8F0;
    }

    pre {
      background-color: #0F172A;
      color: #F8FAFC;
      padding: 14px;
      border-radius: 8px;
      overflow-x: auto;
      font-size: 8pt;
      page-break-inside: avoid;
      break-inside: avoid;
    }

    pre code {
      background: transparent;
      border: none;
      color: inherit;
      padding: 0;
    }

    /* Blockquotes */
    blockquote {
      margin: 14px 0;
      padding: 10px 18px;
      border-left: 4px solid #3B82F6;
      background-color: #F8FAFC;
      border-radius: 0 8px 8px 0;
      font-style: italic;
    }

    hr {
      border: 0;
      height: 1px;
      background: #E2E8F0;
      margin: 24px 0;
    }
  </style>
</head>
<body>

  <!-- Official Editorial Cover Page -->
  <div class="cover-page">
    <div class="cover-top">
      <div class="cover-badge-chile">
        🇨🇱 REPÚBLICA DE CHILE • SALUD DIGITAL
      </div>
      <div style="font-size: 9pt; font-weight: 600; color: #94A3B8;">
        EDICIÓN OFICIAL 2026
      </div>
    </div>

    <div class="cover-center">
      <img src="${imageMap['assets/app_icon.png']}" alt="ChronoMed Isotipo" class="cover-icon" />
      <div class="cover-title">ChronoMed</div>
      <div class="cover-subtitle">
        Sincronización Inteligente de Medicación, Cronobiología y Adherencia Clínica con Arquitectura Dual
      </div>
      <div class="cover-doc-type">
        Manual de Usuario Maestro — Producción v1.0.0
      </div>

      <div class="cover-badges-grid">
        <div class="badge-card">
          <div class="badge-card-title">⚖️ LEY N° 20.584</div>
          <div class="badge-card-desc">Derechos y Deberes del Paciente y Reserva de la Ficha Clínica.</div>
        </div>
        <div class="badge-card">
          <div class="badge-card-title">🔒 LEY N° 19.628</div>
          <div class="badge-card-desc">Protección de Datos Sensibles de Salud y Privacidad Soberana.</div>
        </div>
        <div class="badge-card">
          <div class="badge-card-title">🏥 CATÁLOGO ISP</div>
          <div class="badge-card-desc">Vademécum Oficial y Verificación de Bioequivalencia.</div>
        </div>
        <div class="badge-card">
          <div class="badge-card-title">♿ WCAG 2.2 AAA</div>
          <div class="badge-card-desc">Áreas táctiles ≥ 48 dp, contraste extremo y guía de voz TTS.</div>
        </div>
        <div class="badge-card">
          <div class="badge-card-title">🚨 SAMU 131</div>
          <div class="badge-card-desc">Acceso instantáneo a urgencias y toxicología CITUC UC.</div>
        </div>
        <div class="badge-card">
          <div class="badge-card-title">🔐 SEGURIDAD MILITAR</div>
          <div class="badge-card-desc">Cifrado AES-256-GCM y Blind Indexing HMAC-SHA256.</div>
        </div>
      </div>
    </div>

    <div class="cover-bottom">
      <div>
        <strong>Plataforma:</strong> Android Nativo (APK) & Web PWA (Offline-First)
      </div>
      <div>
        <strong>Autor:</strong> Equipo Médico-Tecnológico ChronoMed • Santiago de Chile
      </div>
    </div>
  </div>

  <!-- Document Body Content -->
  <div class="content">
    ${htmlBody}
  </div>

  <!-- Mermaid Renderer Script -->
  <script>
    ${mermaidScript}
    mermaid.initialize({
      startOnLoad: true,
      theme: 'neutral',
      securityLevel: 'loose',
      flowchart: { useMaxWidth: true, htmlLabels: true }
    });
  </script>
</body>
</html>`;

  const htmlOutputPath = path.resolve('docs/manual_imprimible.html');
  fs.writeFileSync(htmlOutputPath, fullHtml, 'utf8');
  console.log(`✅ Archivo HTML imprimible guardado en: ${htmlOutputPath}`);

  // Compiling to PDF via Edge Headless
  const rootPdfPath = path.resolve('ChronoMed_Manual_de_Usuario_v1.0.0.pdf');
  const docsPdfPath = path.resolve('docs/ChronoMed_Manual_de_Usuario_v1.0.0.pdf');
  const edgePath = 'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe';

  console.log('🖨️ Compilando PDF oficial con Microsoft Edge Headless...');
  const edgeCmd = `"${edgePath}" --headless=new --virtual-time-budget=6000 --disable-gpu --no-pdf-header-footer --print-to-pdf="${rootPdfPath}" "file:///${htmlOutputPath.replace(/\\/g, '/')}"`;
  
  execSync(edgeCmd);

  if (fs.existsSync(rootPdfPath)) {
    const sizeKb = (fs.statSync(rootPdfPath).size / 1024).toFixed(1);
    console.log(`🎉 PDF Generado con éxito en: ${rootPdfPath} (${sizeKb} KB)`);
    
    // Copy to docs/ for online access
    fs.copyFileSync(rootPdfPath, docsPdfPath);
    console.log(`📁 Copia de descarga web guardada en: ${docsPdfPath}`);
  } else {
    throw new Error('No se encontró el archivo PDF generado.');
  }
}

run().catch(err => {
  console.error('❌ Error generando manual PDF:', err);
  process.exit(1);
});
