import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../models/department.dart';
import '../services/repository.dart';
import 'patient_detail_screen.dart';

class PatientsListScreen extends StatefulWidget {
  const PatientsListScreen({super.key});

  @override
  State<PatientsListScreen> createState() => _PatientsListScreenState();
}

class _PatientsListScreenState extends State<PatientsListScreen> {
  final Repository _repository = Repository();
  List<Patient> _allPatients = [];
  List<Patient> _filteredPatients = [];
  List<Department> _departments = [];
  String _selectedDeptId = '';
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final patients = await _repository.getPatients();
    final depts = await _repository.getDepartments();
    setState(() {
      _allPatients = patients;
      _departments = depts;
      _applyFilter();
      _isLoading = false;
    });
  }

  void _applyFilter() {
    setState(() {
      _filteredPatients = _allPatients.where((p) {
        final matchesDept = _selectedDeptId.isEmpty || p.departmentId == _selectedDeptId;
        final matchesSearch = _searchQuery.isEmpty || p.name.toLowerCase().contains(_searchQuery.toLowerCase());
        return matchesDept && matchesSearch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Пациенты', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Синхронизация...')),
              );
              final msg = await _repository.syncDirectories();
              _loadData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filter bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Поиск пациента',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    ),
                    onChanged: (val) {
                      _searchQuery = val;
                      _applyFilter();
                    },
                  ),
                ),
                if (_departments.isNotEmpty)
                  SizedBox(
                    height: 48,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: const Text('Все отделения'),
                            selected: _selectedDeptId.isEmpty,
                            onSelected: (_) {
                              setState(() {
                                _selectedDeptId = '';
                                _applyFilter();
                              });
                            },
                          ),
                        ),
                        ..._departments.map((d) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(d.name),
                                selected: _selectedDeptId == d.id,
                                onSelected: (_) {
                                  setState(() {
                                    _selectedDeptId = d.id;
                                    _applyFilter();
                                  });
                                },
                              ),
                            )),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Expanded(
                  child: _filteredPatients.isEmpty
                      ? const Center(child: Text('Пациенты не найдены'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredPatients.length,
                          itemBuilder: (context, index) {
                            final patient = _filteredPatients[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(
                                  patient.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text('Мед. карта: ${patient.medCard} | ${patient.department}'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PatientDetailScreen(patient: patient),
                                    ),
                                  ).then((_) => _loadData());
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
