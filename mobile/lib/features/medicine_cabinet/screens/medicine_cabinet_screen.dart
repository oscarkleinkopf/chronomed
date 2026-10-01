import 'package:flutter/material.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../ocr/models/medicine_box_scan_result.dart';
import '../../ocr/widgets/medicine_box_scanner_dialog.dart';
import '../models/medicine_cabinet_item.dart';
import '../widgets/medicine_cabinet_card.dart';
import '../widgets/add_edit_medicine_dialog.dart';
import '../widgets/pharmacy_list_dialog.dart';
import '../widgets/nfc_pair_dialog.dart';

enum CabinetFilter {
  all,
  bioequivalentOnly,
  expiringOrExpired,
  lowStock,
}

class MedicineCabinetScreen extends StatefulWidget {
  const MedicineCabinetScreen({super.key});

  @override
  State<MedicineCabinetScreen> createState() => _MedicineCabinetScreenState();
}

class _MedicineCabinetScreenState extends State<MedicineCabinetScreen> {
  final LocalStorageService _storage = LocalStorageService.instance;
  List<MedicineCabinetItem> _items = [];
  CabinetFilter _currentFilter = CabinetFilter.all;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCabinetData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadCabinetData() {
    setState(() {
      _items = _storage.getCabinetItems();
    });
  }

  List<MedicineCabinetItem> get _filteredItems {
    return _items.where((item) {
      // Filtro de búsqueda por texto
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchName = item.name.toLowerCase().contains(q);
        final matchDosage = item.dosage.toLowerCase().contains(q);
        final matchIsp = item.ispRegister?.toLowerCase().contains(q) ?? false;
        final matchLot = item.lotNumber?.toLowerCase().contains(q) ?? false;
        if (!matchName && !matchDosage && !matchIsp && !matchLot) return false;
      }

      // Filtro de categoría
      switch (_currentFilter) {
        case CabinetFilter.all:
          return true;
        case CabinetFilter.bioequivalentOnly:
          return item.isBioequivalent;
        case CabinetFilter.expiringOrExpired:
          return item.expirationStatus == BoxExpirationStatus.expired ||
              item.expirationStatus == BoxExpirationStatus.expiringSoon;
        case CabinetFilter.lowStock:
          return item.stockUnits <= 5;
      }
    }).toList();
  }

  int get _totalCount => _items.length;
  int get _bioequivalentCount => _items.where((i) => i.isBioequivalent).length;
  int get _expiringAlertCount => _items.where((i) =>
      i.expirationStatus == BoxExpirationStatus.expired ||
      i.expirationStatus == BoxExpirationStatus.expiringSoon).length;
  int get _lowStockCount => _items.where((i) => i.stockUnits <= 5).length;

  void _openScanner() {
    showDialog(
      context: context,
      builder: (ctx) => MedicineBoxScannerDialog(
        onStockUpdated: _handleBoxScanResult,
      ),
    );
  }

  Future<void> _handleBoxScanResult(MedicineBoxScanResult result) async {
    final scannedName = result.detectedDrugName?.trim() ?? 'Fármaco Escaneado';
    final scannedUnits = result.detectedUnits ?? 30;

    // Verificar si ya existe en el botiquín
    final existingIndex = _items.indexWhere((i) {
      final a = i.name.toLowerCase().trim();
      final b = scannedName.toLowerCase().trim();
      if (a == b) return true;
      if (result.detectedIspRegister != null &&
          i.ispRegister != null &&
          result.detectedIspRegister == i.ispRegister) {
        return true;
      }
      return false;
    });

    if (existingIndex >= 0) {
      final existing = _items[existingIndex];
      final newUnits = existing.stockUnits + scannedUnits;
      final updated = existing.copyWith(
        stockUnits: newUnits,
        lotNumber: result.detectedLotNumber ?? existing.lotNumber,
        expirationDate: result.detectedExpirationDate ?? existing.expirationDate,
        ispRegister: result.detectedIspRegister ?? existing.ispRegister,
        isBioequivalent: result.isBioequivalent || existing.isBioequivalent,
        expirationStatus: result.expirationStatus != BoxExpirationStatus.unknown
            ? result.expirationStatus
            : existing.expirationStatus,
      );

      await _storage.saveCabinetItem(updated);
      _loadCabinetData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF0F172A),
            content: Text(
              '📦 Stock sumado a "${existing.name}": +$scannedUnits un. (Total: $newUnits)',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        );
      }
    } else {
      // Nuevo fármaco
      final newItem = MedicineCabinetItem.fromScanResult(result);
      await _storage.saveCabinetItem(newItem);
      _loadCabinetData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF059669),
            content: Text(
              '✨ Ingresado al botiquín: ${newItem.name} (${newItem.stockUnits} un.)' +
                  (newItem.isBioequivalent ? ' • ⭐ Bioequivalente ISP' : ''),
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        );
      }
    }
  }

  void _openAddEditDialog([MedicineCabinetItem? item]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, controller) => AddEditMedicineDialog(
          initialItem: item,
          onSave: (savedItem) async {
            await _storage.saveCabinetItem(savedItem);
            _loadCabinetData();

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF0F172A),
                  content: Text(
                    item != null ? 'Fármaco actualizado con éxito' : 'Nuevo fármaco añadido al botiquín',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Future<void> _updateItemStock(MedicineCabinetItem item, int newUnits) async {
    await _storage.updateCabinetStock(item.id, newUnits);
    _loadCabinetData();
  }

  Future<void> _deleteItem(MedicineCabinetItem item) async {
    await _storage.deleteCabinetItem(item.id);
    _loadCabinetData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF334155),
          content: Text('Se eliminó "${item.name}" del botiquín'),
          action: SnackBarAction(
            label: 'DESHACER',
            textColor: const Color(0xFF60A5FA),
            onPressed: () async {
              await _storage.saveCabinetItem(item);
              _loadCabinetData();
            },
          ),
        ),
      );
    }
  }

  Future<void> _openNfcPairDialog(MedicineCabinetItem item) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => NfcPairDialog(medicine: item),
    );
    if (result == true) {
      _loadCabinetData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredItems;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Botiquín & Inventario',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            Text(
              'Control de Cajas, Lotes y Bioequivalencia ISP',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded, color: Color(0xFF16A34A)),
            tooltip: 'Lista para Farmacia / Reposición',
            onPressed: () => showPharmacyListDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Color(0xFF2563EB)),
            tooltip: 'Agregar medicamento manual',
            onPressed: () => _openAddEditDialog(),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Banner resumen
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: _buildSummaryCards(),
            ),
          ),

          // Botón destacado: Escanear Caja OCR
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 1,
                ),
                icon: const Icon(Icons.document_scanner_rounded, size: 22),
                label: const Text(
                  'ESCANEAR CAJA CON OCR (ISP CHILE)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.3),
                ),
                onPressed: _openScanner,
              ),
            ),
          ),

          // Buscador y Filtros
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar fármaco, ISP o lote...',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  ),
                  const SizedBox(height: 10),
                  _buildFilterChips(),
                ],
              ),
            ),
          ),

          // Lista de medicamentos
          if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = filtered[index];
                    return MedicineCabinetCard(
                      key: ValueKey(item.id),
                      item: item,
                      onEdit: () => _openAddEditDialog(item),
                      onDelete: () => _deleteItem(item),
                      onUpdateStock: (newUnits) => _updateItemStock(item, newUnits),
                      onPairNfc: () => _openNfcPairDialog(item),
                    );
                  },
                  childCount: filtered.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 40),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        _buildStatTile(
          title: 'Total',
          count: '$_totalCount',
          color: const Color(0xFF2563EB),
          icon: Icons.inventory_2_outlined,
        ),
        const SizedBox(width: 8),
        _buildStatTile(
          title: 'Bioequiv.',
          count: '$_bioequivalentCount',
          color: const Color(0xFFD97706),
          icon: Icons.verified_rounded,
        ),
        const SizedBox(width: 8),
        _buildStatTile(
          title: 'Vencimientos',
          count: '$_expiringAlertCount',
          color: _expiringAlertCount > 0 ? const Color(0xFFDC2626) : const Color(0xFF64748B),
          icon: Icons.access_time_rounded,
        ),
        const SizedBox(width: 8),
        _buildStatTile(
          title: 'Bajo Stock',
          count: '$_lowStockCount',
          color: _lowStockCount > 0 ? const Color(0xFFEA580C) : const Color(0xFF64748B),
          icon: Icons.warning_amber_rounded,
        ),
      ],
    );
  }

  Widget _buildStatTile({
    required String title,
    required String count,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              count,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            ),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip('Todos (${_items.length})', CabinetFilter.all),
          const SizedBox(width: 6),
          _filterChip('⭐ Bioequivalentes ($_bioequivalentCount)', CabinetFilter.bioequivalentOnly),
          const SizedBox(width: 6),
          _filterChip('⚠️ Por Vencer ($_expiringAlertCount)', CabinetFilter.expiringOrExpired),
          const SizedBox(width: 6),
          _filterChip('🔴 Bajo Stock ($_lowStockCount)', CabinetFilter.lowStock),
        ],
      ),
    );
  }

  Widget _filterChip(String label, CabinetFilter filter) {
    final isSelected = _currentFilter == filter;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF475569),
        ),
      ),
      selected: isSelected,
      selectedColor: const Color(0xFFEFF6FF),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
      ),
      onSelected: (selected) {
        if (selected) setState(() => _currentFilter = filter);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.medication_outlined, size: 64, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 16),
            const Text(
              'No se encontraron medicamentos',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Escanea la caja de un medicamento con OCR o agrégalo manualmente para comenzar.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.document_scanner_rounded),
              label: const Text('Escanear Caja Ahora'),
              onPressed: _openScanner,
            ),
          ],
        ),
      ),
    );
  }
}
