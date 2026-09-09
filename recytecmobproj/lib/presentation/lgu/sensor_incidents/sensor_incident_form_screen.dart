import 'package:flutter/material.dart';

import '../../../core/theme/recytechtheme.dart';
import '../../../data/models/bin_monitoring_models.dart';
import '../../../data/models/sensor_incident_model.dart';
import '../../../data/repositories/sensor_incident_repository.dart';

class SensorIncidentFormScreen extends StatefulWidget {
  const SensorIncidentFormScreen({
    super.key,
    required this.bin,
    this.repository,
  });

  final RecyTechBin bin;
  final SensorIncidentRepository? repository;

  static bool requiresMaintenanceConfirmation(String severity) =>
      SensorIncidentSeverities.placesBinInMaintenance(severity);

  @override
  State<SensorIncidentFormScreen> createState() =>
      _SensorIncidentFormScreenState();
}

class _SensorIncidentFormScreenState extends State<SensorIncidentFormScreen> {
  late final SensorIncidentRepository _repository;
  final _description = TextEditingController();
  String _severity = SensorIncidentSeverities.medium;
  String? _error;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ApiSensorIncidentRepository();
  }

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final description = _description.text.trim();
    if (description.isEmpty) {
      setState(() => _error = 'Issue description is required.');
      return;
    }

    if (SensorIncidentFormScreen.requiresMaintenanceConfirmation(_severity)) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Maintenance warning'),
          content: const Text(
            'This severity will place the bin in Maintenance status until the issue is handled by Web Admin/Staff. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final result = await _repository.createIncident(
        binId: widget.bin.apiId,
        issueDescription: description,
        severity: _severity,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
      Navigator.pop(context, true);
    } on SensorIncidentRepositoryException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unable to report this sensor issue.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RecyTechTheme.bg,
      appBar: AppBar(title: const Text('Report Sensor Issue')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.bin.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(widget.bin.location.isEmpty
                        ? 'Address not supplied'
                        : widget.bin.location),
                    const SizedBox(height: 10),
                    const Text(
                      'Sensor: Fullness Sensor (ToF)',
                      key: Key('sensor-type-read-only'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const Key('incident-description'),
              controller: _description,
              enabled: !_submitting,
              minLines: 4,
              maxLines: 7,
              decoration: const InputDecoration(
                labelText: 'Issue Description',
                hintText: 'Describe the sensor problem',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              key: const Key('incident-severity'),
              initialValue: _severity,
              decoration: const InputDecoration(labelText: 'Severity'),
              items: SensorIncidentSeverities.values
                  .map(
                    (severity) => DropdownMenuItem(
                      value: severity,
                      child: Text(severity),
                    ),
                  )
                  .toList(growable: false),
              onChanged: _submitting
                  ? null
                  : (value) {
                      if (value != null) setState(() => _severity = value);
                    },
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                key: const Key('incident-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 18),
            ElevatedButton.icon(
              key: const Key('report-incident-submit'),
              onPressed: _submitting ? null : _submit,
              icon: const Icon(Icons.report_problem_outlined),
              label: Text(_submitting ? 'Reporting...' : 'Report Issue'),
            ),
          ],
        ),
      ),
    );
  }
}
