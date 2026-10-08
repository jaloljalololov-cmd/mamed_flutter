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
  String _selectedDeptName = '';
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

    // Replicate Native Android departmentsList logic:
    final Map<String, String> deptMap = {};
    for (var d in depts) {
      if (d.id.trim().isNotEmpty && d.name.trim().isNotEmpty) {
        deptMap[d.id.trim()] = d.name.trim();
      }
    }
    for (var p in patients) {
      if (p.departmentId.trim().isNotEmpty && p.department.trim().isNotEmpty) {
        if (!deptMap.containsKey(p.departmentId.trim())) {
          deptMap[p.departmentId.trim()] = p.department.trim();
        }
      }
    }

    final combinedDepts = deptMap.entries
        .map((e) => Department(id: e.key, name: e.value))
        .toList();

    if (combinedDepts.isNotEmpty) {
      final currentExists = combinedDepts.any((d) => d.id == _selectedDeptId);
      if (!currentExists) {
        _selectedDeptId = combinedDepts.first.id;
        _selectedDeptName = combinedDepts.first.name;
      }
    }

    setState(() {
      _allPatients = patients;
      _departments = combinedDepts;
      _applyFilter();
      _isLoading = false;
    });
  }

  void _applyFilter() {
    setState(() {
      _filteredPatients = _allPatients.where((p) {
        final matchesDept = _selectedDeptId.isEmpty ||
            p.departmentId.trim().toLowerCase() == _selectedDeptId.trim().toLowerCase() ||
            p.department.trim().toLowerCase() == _selectedDeptName.trim().toLowerCase();
        final matchesSearch = _searchQuery.isEmpty ||
            p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            p.medCard.toLowerCase().contains(_searchQuery.toLowerCase());
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
                if (_departments.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: DropdownButtonFormField<String>(
                      initialValue: _departments.any((d) => d.id == _selectedDeptId)
                          ? _selectedDeptId
                          : _departments.first.id,
                      decoration: InputDecoration(
                        labelText: 'Отделение',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      items: _departments.map((d) {
                        return DropdownMenuItem<String>(
                          value: d.id,
                          child: Text(d.name, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          final selected = _departments.firstWhere((d) => d.id == val);
                          setState(() {
                            _selectedDeptId = selected.id;
                            _selectedDeptName = selected.name;
                            _applyFilter();
                          });
                        }
                      },
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Поиск пациента по ФИО или медокарте',
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
                                subtitle: Text('Отделение: ${patient.department}\nМед. карта: ${patient.medCard} | Возраст: ${patient.age} лет'),
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
