import 'package:flutter/material.dart';

import '../../../core/theme/recytechtheme.dart';
import '../../../data/models/sensor_incident_model.dart';
import '../../../data/repositories/sensor_incident_repository.dart';
import '../../../widgets/empty_state.dart';

class SensorIncidentHistoryScreen extends StatefulWidget {
  const SensorIncidentHistoryScreen({super.key, this.repository});

  final SensorIncidentRepository? repository;

  @override
  State<SensorIncidentHistoryScreen> createState() =>
      _SensorIncidentHistoryScreenState();
}

class _SensorIncidentHistoryScreenState
    extends State<SensorIncidentHistoryScreen> {
  late final SensorIncidentRepository _repository;
  late Future<List<SensorIncident>> _future;
  Future<void>? _refreshing;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ApiSensorIncidentRepository();
    _future = _repository.fetchMyIncidents();
  }

  Future<void> _refresh() async {
    final active = _refreshing;
    if (active != null) return active;

    final future = _repository.fetchMyIncidents();
    setState(() => _future = future);
    final refresh = future.whenComplete(() {
      if (mounted) _refreshing = null;
    });
    _refreshing = refresh;
    await refresh;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RecyTechTheme.bg,
      appBar: AppBar(
        title: const Text('Sensor Incident History'),
        actions: [
          IconButton(
            tooltip: 'Refresh incidents',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<SensorIncident>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingState(message: 'Loading incidents...');
          }
          if (snapshot.hasError) {
            return AppErrorState(
              title: 'Unable to load sensor incident history.',
              onRetry: _refresh,
            );
          }
          final incidents = snapshot.data ?? const <SensorIncident>[];
          return RefreshIndicator(
            onRefresh: _refresh,
            child: incidents.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 120),
                      EmptyState(
                        icon: Icons.sensors_outlined,
                        title: 'No sensor incidents reported yet.',
                        message: 'Reported bin sensor issues will appear here.',
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: incidents.length,
                    itemBuilder: (_, index) => _incidentCard(incidents[index]),
                  ),
          );
        },
      ),
    );
  }

  Widget _incidentCard(SensorIncident incident) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(incident.bin.displayName),
        subtitle: Text('${incident.severity} - ${incident.status}'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row('Address', incident.bin.address),
          _row('Sensor', incident.sensorType),
          _row('Issue', incident.issueDescription),
          _row('Severity', incident.severity),
          _row('Status', incident.status),
          _row('Reported', _date(incident.createdAt)),
          if (incident.resolutionNotes != null)
            _row('Resolution notes', incident.resolutionNotes),
          if (incident.resolvedAt != null)
            _row('Resolved', _date(incident.resolvedAt!)),
        ],
      ),
    );
  }

  Widget _row(String label, String? value) {
    if ((value ?? '').trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Expanded(child: Text(value!)),
        ],
      ),
    );
  }

  String _date(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$month-$day $hour:$minute';
  }
}
