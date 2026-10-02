import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../models/prescription.dart';
import '../services/repository.dart';
import 'create_prescription_screen.dart';

class PatientDetailScreen extends StatefulWidget {
  final Patient patient;

  const PatientDetailScreen({super.key, required this.patient});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  final Repository _repository = Repository();
  List<PrescriptionItem> _prescribedItems = [];
  List<dynamic> _comments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final items = await _repository.getAllPrescriptionItemsForPatient(widget.patient.id);
    
    List<dynamic> parsedComments = [];
    try {
      if (widget.patient.commentsJson.isNotEmpty) {
        parsedComments = jsonDecode(widget.patient.commentsJson);
      }
    } catch (_) {}

    setState(() {
      _prescribedItems = items;
      _comments = parsedComments;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Информация о пациенте'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.patient.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Медицинская карта: ${widget.patient.medCard}',
                    style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  // Info Card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: _buildDetailCol('Возраст', '${widget.patient.age} лет')),
                              Expanded(child: _buildDetailCol('Пол', widget.patient.gender)),
                            ],
                          ),
                          const Divider(height: 20),
                          _buildDetailCol('Отделение', widget.patient.department),
                          const SizedBox(height: 8),
                          _buildDetailCol('Лечащий врач', widget.patient.doctor),
                          const Divider(height: 20),
                          Row(
                            children: [
                              Expanded(child: _buildDetailCol('Диета', widget.patient.diet)),
                              Expanded(child: _buildDetailCol('Транспортабельность', widget.patient.transportability)),
                            ],
                          ),
                          const Divider(height: 20),
                          InkWell(
                            onTap: _comments.isEmpty ? null : () => _showCommentsModal(context),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Комментарии:', style: TextStyle(color: Colors.grey)),
                                Text(
                                  _comments.isEmpty ? 'Нет комментариев' : '${_comments.length} шт. (посмотреть)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _comments.isEmpty ? Colors.grey : Theme.of(context).primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section Title: Detailed Prescribed Medications
                  const Text(
                    'Назначенные медикаменты',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  if (_prescribedItems.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Text(
                            'Медикаменты пока не назначались.',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      ),
                    )
                  else
                    Card(
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _prescribedItems.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = _prescribedItems[index];
                          final dateStr = item.startDate.isNotEmpty && item.endDate.isNotEmpty
                              ? 'С ${item.startDate} по ${item.endDate}'
                              : '';
                          return ListTile(
                            title: Text(
                              item.medicationName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                decoration: item.isCanceled ? TextDecoration.lineThrough : null,
                                color: item.isCanceled ? Colors.red : Colors.black,
                              ),
                            ),
                            subtitle: Text(
                              'Кол-во: ${item.quantity.toInt()} шт. | Режим: ${item.scheduleName}${dateStr.isNotEmpty ? ' | $dateStr' : ''}${item.isCanceled ? ' (Отменён)' : ''}',
                              style: TextStyle(
                                decoration: item.isCanceled ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 24),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreatePrescriptionScreen(patient: widget.patient),
                        ),
                      ).then((_) => _loadData());
                    },
                    child: const Text('Ввести назначение', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 2),
        Text(value.isEmpty ? '—' : value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  void _showCommentsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Комментарии пациента', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: _comments.length,
                  itemBuilder: (context, index) {
                    final c = _comments[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c['ПользовательНаименование'] ?? 'Пользователь', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                            Text('Дата: ${c['Период'] ?? ''}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text(c['Комментарий'] ?? 'Без текста'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
