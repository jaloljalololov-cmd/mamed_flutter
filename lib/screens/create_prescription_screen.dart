import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/patient.dart';
import '../models/medication.dart';
import '../models/schedule.dart';
import '../services/repository.dart';

class CreatePrescriptionScreen extends StatefulWidget {
  final Patient patient;

  const CreatePrescriptionScreen({super.key, required this.patient});

  @override
  State<CreatePrescriptionScreen> createState() => _CreatePrescriptionScreenState();
}

class _CreatePrescriptionScreenState extends State<CreatePrescriptionScreen> {
  final Repository _repository = Repository();
  List<Medication> _medications = [];
  List<Schedule> _schedules = [];
  final List<Map<String, dynamic>> _selectedItems = [];
  String _comment = '';
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final meds = await _repository.getMedications();
    final scheds = await _repository.getSchedules();
    setState(() {
      _medications = meds;
      _schedules = scheds;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Выписка назначения')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Пациент: ${widget.patient.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Мед. карта: ${widget.patient.medCard}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              icon: const Icon(Icons.add),
              label: const Text('Добавить номенклатуру (Медикаменты)'),
              onPressed: () => _showMedicationModal(context),
            ),
            const SizedBox(height: 20),
            const Text('Состав назначения:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),

            if (_selectedItems.isEmpty)
              const Text('Таблица пуста. Выберите товары из списка выше.', style: TextStyle(color: Colors.grey))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _selectedItems.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = _selectedItems[index];
                  return ListTile(
                    title: Text(item['medicationName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Кол-во: ${item['quantity'].toInt()} шт. | Режим: ${item['scheduleName']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.calendar_month, color: Colors.blue),
                          onPressed: () => _showPeriodModal(context, index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => setState(() => _selectedItems.removeAt(index)),
                        ),
                      ],
                    ),
                  );
                },
              ),

            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Комментарий к назначению (опционально)',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => _comment = val,
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              onPressed: (_selectedItems.isEmpty || _isSending) ? null : _savePrescription,
              child: _isSending
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Выписать назначение', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePrescription() async {
    setState(() => _isSending = true);
    final msg = await _repository.createPrescription(
      patientId: widget.patient.id,
      patientName: widget.patient.name,
      medCard: widget.patient.medCard,
      medCardGuid: widget.patient.medCardId,
      comment: _comment,
      items: _selectedItems,
    );

    setState(() => _isSending = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      Navigator.pop(context);
    }
  }

  void _showMedicationModal(BuildContext context) {
    final Map<String, double> tempQuantities = {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: 500,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('Выбор номенклатуры', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _medications.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final med = _medications[index];
                        final qty = tempQuantities[med.id] ?? 0.0;
                        return ListTile(
                          title: Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Доступно: ${med.stock.toInt()} ${med.unitName}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: qty > 0 ? () => setModalState(() => tempQuantities[med.id] = qty - 1.0) : null,
                              ),
                              Text('${qty.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () => setModalState(() => tempQuantities[med.id] = qty + 1.0),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    onPressed: () {
                      final defaultSched = _schedules.isNotEmpty ? _schedules.first : Schedule(id: '1', name: 'Ежедневно');
                      final now = DateTime.now();
                      final startStr = DateFormat('dd.MM.yyyy').format(now);
                      final endStr = DateFormat('dd.MM.yyyy').format(now.add(const Duration(days: 7)));

                      tempQuantities.forEach((medId, qty) {
                        if (qty > 0) {
                          final med = _medications.firstWhere((m) => m.id == medId);
                          _selectedItems.add({
                            'medicationId': med.id,
                            'medicationName': med.name,
                            'quantity': qty,
                            'unitId': med.unitId,
                            'unitName': med.unitName,
                            'scheduleId': defaultSched.id,
                            'scheduleName': defaultSched.name,
                            'startDate': startStr,
                            'endDate': endStr,
                          });
                        }
                      });
                      setState(() {});
                      Navigator.pop(context);
                    },
                    child: const Text('Добавить выбранное'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showPeriodModal(BuildContext context, int index) {
    final item = _selectedItems[index];
    String startDate = item['startDate'];
    String endDate = item['endDate'];
    Schedule selectedSched = _schedules.firstWhere((s) => s.id == item['scheduleId'], orElse: () => Schedule(id: '1', name: 'Ежедневно'));

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(16),
              height: 350,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Настройка периода приёма', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (d != null) {
                              setModalState(() => startDate = DateFormat('dd.MM.yyyy').format(d));
                            }
                          },
                          child: Text('С: $startDate'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().add(const Duration(days: 7)),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (d != null) {
                              setModalState(() => endDate = DateFormat('dd.MM.yyyy').format(d));
                            }
                          },
                          child: Text('ПО: $endDate'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Режим приёма:'),
                  DropdownButton<Schedule>(
                    isExpanded: true,
                    value: selectedSched,
                    items: _schedules.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedSched = val);
                    },
                  ),
                  const Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    onPressed: () {
                      setState(() {
                        item['startDate'] = startDate;
                        item['endDate'] = endDate;
                        item['scheduleId'] = selectedSched.id;
                        item['scheduleName'] = selectedSched.name;
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('Сохранить период'),
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
