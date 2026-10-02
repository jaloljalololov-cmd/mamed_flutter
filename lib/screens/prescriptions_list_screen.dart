import 'package:flutter/material.dart';
import '../models/prescription.dart';
import '../models/cancellation.dart';
import '../services/repository.dart';

class PrescriptionsListScreen extends StatefulWidget {
  const PrescriptionsListScreen({super.key});

  @override
  State<PrescriptionsListScreen> createState() => _PrescriptionsListScreenState();
}

class _PrescriptionsListScreenState extends State<PrescriptionsListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Repository _repository = Repository();

  List<Prescription> _prescriptions = [];
  List<Cancellation> _cancellations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final pList = await _repository.getAllPrescriptions();
    final cList = await _repository.getAllCancellations();
    setState(() {
      _prescriptions = pList;
      _cancellations = cList;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Реестр документов'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Назначения'),
            Tab(text: 'Отмена документов'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Prescriptions
                _prescriptions.isEmpty
                    ? const Center(child: Text('Назначения пока не выписывались'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _prescriptions.length,
                        itemBuilder: (context, index) {
                          final p = _prescriptions[index];
                          return Card(
                            child: ListTile(
                              title: Text('Пациент: ${p.patientName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Мед. карта: ${p.medCard} | Дата: ${p.date}'),
                              trailing: Text(
                                p.isSynced ? 'Отправлено в 1С' : 'Сохранено локально',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: p.isSynced ? Colors.blue : Colors.orange,
                                ),
                              ),
                              onTap: () => _showPrescriptionModal(context, p),
                            ),
                          );
                        },
                      ),

                // Tab 2: Cancellations
                _cancellations.isEmpty
                    ? const Center(child: Text('Документы отмены пока не создавались'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _cancellations.length,
                        itemBuilder: (context, index) {
                          final c = _cancellations[index];
                          return Card(
                            color: Colors.red[50],
                            child: ListTile(
                              title: Text('Отмена: ${c.patientName}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                              subtitle: Text('Мед. карта: ${c.medCard} | Дата: ${c.date}${c.comment.isNotEmpty ? "\nПричина: ${c.comment}" : ""}'),
                              trailing: Text(
                                c.isSynced ? 'Отправлено в 1С' : 'Сохранено локально',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: c.isSynced ? Colors.blue : Colors.orange,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
    );
  }

  void _showPrescriptionModal(BuildContext context, Prescription prescription) async {
    final items = await _repository.getPrescriptionItems(prescription.id);
    final Map<int, bool> canceledMap = {};
    for (var item in items) {
      if (item.isCanceled && item.id != null) {
        canceledMap[item.id!] = true;
      }
    }
    String cancellationComment = '';

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final newlyCanceledCount = items.where((i) => (canceledMap[i.id] ?? false) && !i.isCanceled).length;

            return Container(
              height: 500,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Назначение для ${prescription.patientName}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Мед. карта: ${prescription.medCard} | Дата: ${prescription.date}', style: const TextStyle(color: Colors.blue)),
                  const SizedBox(height: 12),
                  const Text('Список препаратов:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final isCanceled = canceledMap[item.id] ?? item.isCanceled;

                        return ListTile(
                          title: Text(
                            item.medicationName,
                            style: TextStyle(
                              decoration: isCanceled ? TextDecoration.lineThrough : null,
                              color: isCanceled ? Colors.red : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text('Кол-во: ${item.quantity.toInt()} шт. (${item.scheduleName})${item.isCanceled ? " (Отменён)" : ""}'),
                          trailing: IconButton(
                            icon: Icon(isCanceled ? Icons.check : Icons.close, color: Colors.red),
                            onPressed: item.isCanceled
                                ? null
                                : () {
                                    setModalState(() {
                                      if (item.id != null) {
                                        canceledMap[item.id!] = !isCanceled;
                                      }
                                    });
                                  },
                          ),
                        );
                      },
                    ),
                  ),
                  if (newlyCanceledCount > 0) ...[
                    TextField(
                      decoration: const InputDecoration(labelText: 'Причина отмены (комментарий)', border: OutlineInputBorder()),
                      onChanged: (val) => cancellationComment = val,
                    ),
                    const SizedBox(height: 12),
                  ],
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    onPressed: newlyCanceledCount == 0
                        ? null
                        : () async {
                            final newlyCanceledItems = items.where((i) => (canceledMap[i.id] ?? false) && !i.isCanceled).map((i) => {
                                  'medicationId': i.medicationId,
                                  'medicationName': i.medicationName,
                                  'quantity': i.quantity,
                                  'scheduleId': i.scheduleId,
                                  'scheduleName': i.scheduleName,
                                }).toList();

                            final msg = await _repository.createCancellation(
                              originalPrescriptionId: prescription.id,
                              patientId: prescription.patientId,
                              patientName: prescription.patientName,
                              medCard: prescription.medCard,
                              medCardGuid: prescription.medCardGuid,
                              comment: cancellationComment,
                              items: newlyCanceledItems,
                            );

                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                              _loadData();
                            }
                          },
                    child: Text('Применить ($newlyCanceledCount отменены)'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
