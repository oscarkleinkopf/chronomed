import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/sync/local_p2p_sync_service.dart';

class P2pSyncDialog extends StatefulWidget {
  final VoidCallback? onConfigSaved;

  const P2pSyncDialog({
    super.key,
    this.onConfigSaved,
  });

  @override
  State<P2pSyncDialog> createState() => _P2pSyncDialogState();
}

class _P2pSyncDialogState extends State<P2pSyncDialog> {
  late TextEditingController _hostController;
  late TextEditingController _portController;
  late TextEditingController _secretController;
  List<String> _localIps = [];
  bool _isLoadingIps = true;
  bool _isTesting = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    final storage = LocalStorageService.instance;
    _hostController = TextEditingController(text: storage.caregiverHost ?? '');
    _portController = TextEditingController(text: storage.p2pPort.toString());
    _secretController = TextEditingController(text: storage.p2pSecret);
    _discoverLocalIps();
  }

  Future<void> _discoverLocalIps() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      final ips = <String>[];
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback) {
            ips.add('${addr.address} (${interface.name})');
          }
        }
      }
      if (mounted) {
        setState(() {
          _localIps = ips;
          _isLoadingIps = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _localIps = ['127.0.0.1 (Loopback)'];
          _isLoadingIps = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _secretController.dispose();
    super.dispose();
  }

  Future<void> _saveConfig() async {
    final host = _hostController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? LocalP2pSyncService.defaultPort;
    final secret = _secretController.text.trim();

    await LocalStorageService.instance.setP2pConfig(
      caregiverHost: host.isEmpty ? null : host,
      p2pPort: port,
      p2pSecret: secret.isEmpty ? LocalP2pSyncService.defaultSecret : secret,
    );

    LocalP2pSyncService.instance.setSharedSecret(
      secret.isEmpty ? LocalP2pSyncService.defaultSecret : secret,
    );

    widget.onConfigSaved?.call();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF047857),
          content: Text('✅ Configuración P2P guardada correctamente'),
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _testConnection() async {
    final targetHost = _hostController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? LocalP2pSyncService.defaultPort;

    if (targetHost.isEmpty) {
      setState(() => _testResult = '⚠️ Ingresa la IP destino del Cuidador para probar');
      return;
    }

    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 3);

    try {
      final uri = Uri.parse('http://$targetHost:$port/api/status');
      final req = await client.getUrl(uri).timeout(const Duration(seconds: 3));
      final res = await req.close().timeout(const Duration(seconds: 3));

      if (res.statusCode == HttpStatus.ok) {
        setState(() {
          _testResult = '🟢 Conexión exitosa con $targetHost:$port (Protocolo OK)';
        });
      } else {
        setState(() {
          _testResult = '🟠 Servidor respondió con código HTTP ${res.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _testResult = '🔴 No se pudo conectar: verifica que ambos teléfonos estén en el mismo Wi-Fi.';
      });
    } finally {
      client.close();
      if (mounted) {
        setState(() => _isTesting = false);
      }
    }
  }

  Future<void> _flushPendingQueue() async {
    final targetHost = _hostController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? LocalP2pSyncService.defaultPort;

    if (targetHost.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Configura primero la IP del Cuidador'),
        ),
      );
      return;
    }

    final sent = await LocalP2pSyncService.instance.flushPendingQueue(
      caregiverHost: targetHost,
      port: port,
    );

    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0F172A),
          content: Text('📡 Sincronización offline completada: $sent tomas enviadas.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p2pService = LocalP2pSyncService.instance;
    final isListening = p2pService.isServerRunning;
    final queueCount = p2pService.pendingQueue.length;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE0E7FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.wifi_tethering_rounded, color: Color(0xFF4338CA), size: 24),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Sincronización P2P Local',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ley de Privacidad y Cero Servidores Cloud
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.shield_outlined, color: Color(0xFF16A34A), size: 22),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '100% Soberano: Comunicación directa en la misma red Wi-Fi o Zona Wi-Fi. Sin servidores cloud ni recolección de datos (Ley N° 20.584 y 19.628).',
                      style: TextStyle(fontSize: 11, color: Color(0xFF14532D), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Estado del Servidor Receptor
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isListening ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isListening ? const Color(0xFF93C5FD) : const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Icon(
                    isListening ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: isListening ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isListening
                          ? 'Servidor Receptor: Activo (Puerto ${p2pService.activePort ?? LocalP2pSyncService.defaultPort})'
                          : 'Servidor Receptor: Detenido',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isListening ? const Color(0xFF1E40AF) : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // IPs locales detectadas
            const Text('IPs Locales de este Dispositivo:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569))),
            const SizedBox(height: 4),
            _isLoadingIps
                ? const Text('Buscando interfaces de red...', style: TextStyle(fontSize: 11, color: Color(0xFF64748B)))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _localIps.map((ip) => Text('• $ip', style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Color(0xFF0F172A)))).toList(),
                  ),
            const SizedBox(height: 16),

            // IP del Cuidador (Destino de sincronización del Senior)
            const Text('IP del Cuidador (Destino):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569))),
            const SizedBox(height: 4),
            TextField(
              controller: _hostController,
              decoration: InputDecoration(
                hintText: 'Ej: 192.168.1.45',
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),

            // Puerto y Clave HMAC
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Puerto:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569))),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _portController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Firma HMAC:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569))),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _secretController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'Clave Secreta',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Botón de Probar Conexión
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: _isTesting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.network_check_rounded, size: 18),
              label: Text(_isTesting ? 'Probando...' : 'Probar Conexión P2P'),
              onPressed: _isTesting ? null : _testConnection,
            ),

            if (_testResult != null) ...[
              const SizedBox(height: 8),
              Text(
                _testResult!,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],

            const SizedBox(height: 16),

            // Cola Offline de Retransmisión
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: queueCount > 0 ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: queueCount > 0 ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Icon(
                    queueCount > 0 ? Icons.schedule_send_rounded : Icons.cloud_done_rounded,
                    color: queueCount > 0 ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      queueCount > 0
                          ? '$queueCount tomas en cola offline pendiente'
                          : 'Cola offline vacía (Al día)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: queueCount > 0 ? const Color(0xFF991B1B) : const Color(0xFF15803D),
                      ),
                    ),
                  ),
                  if (queueCount > 0)
                    TextButton(
                      onPressed: _flushPendingQueue,
                      child: const Text('Reintentar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CERRAR', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F172A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _saveConfig,
          child: const Text('GUARDAR AJUSTES', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
