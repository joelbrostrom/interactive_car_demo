import 'package:flutter/material.dart';

import '../supabase_config.dart';
import '../widgets/interactive_car.dart';

class CarStatusPage extends StatefulWidget {
  const CarStatusPage({super.key});

  @override
  State<CarStatusPage> createState() => _CarStatusPageState();
}

class _CarStatusPageState extends State<CarStatusPage> {
  String? _carId;
  String? _statusId;
  CarStatus _status = const CarStatus();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCarStatus();
  }

  Future<void> _loadCarStatus() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final carData = await supabase
          .from('cars')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (carData == null) {
        final newCar = await supabase.from('cars').insert({
          'user_id': userId,
          'model': 'Camry',
          'year': 2024,
          'distance_km': 15420,
          'color': 'Silver',
        }).select().single();

        _carId = newCar['id'];

        final newStatus = await supabase.from('car_status').insert({
          'car_id': _carId,
        }).select().single();

        _statusId = newStatus['id'];
        _status = CarStatus.fromJson(newStatus);
      } else {
        _carId = carData['id'];

        final statusData = await supabase
            .from('car_status')
            .select()
            .eq('car_id', _carId!)
            .maybeSingle();

        if (statusData != null) {
          _statusId = statusData['id'];
          _status = CarStatus.fromJson(statusData);
        } else {
          final newStatus = await supabase.from('car_status').insert({
            'car_id': _carId,
          }).select().single();

          _statusId = newStatus['id'];
          _status = CarStatus.fromJson(newStatus);
        }
      }

      _subscribeToUpdates();
    } catch (e) {
      print('Error loading car status: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _subscribeToUpdates() {
    if (_statusId == null) return;

    supabase
        .from('car_status')
        .stream(primaryKey: ['id'])
        .eq('id', _statusId!)
        .listen((data) {
          if (data.isNotEmpty && mounted) {
            setState(() {
              _status = CarStatus.fromJson(data.first);
            });
          }
        });
  }

  Future<void> _onPartTapped(CarPart part) async {
    final partInfo = _getPartInfo(part);
    final currentValue = _getPartValue(part);

    showModalBottomSheet(
      context: context,
      builder: (context) => _buildPartActionSheet(partInfo, currentValue, part),
    );
  }

  String _getPartInfo(CarPart part) {
    switch (part) {
      case CarPart.frontLeftDoor:
        return 'Front Left Door';
      case CarPart.frontRightDoor:
        return 'Front Right Door';
      case CarPart.rearLeftDoor:
        return 'Rear Left Door';
      case CarPart.rearRightDoor:
        return 'Rear Right Door';
      case CarPart.trunk:
        return 'Trunk';
      case CarPart.hood:
        return 'Hood';
      case CarPart.lights:
        return 'Lights';
      case CarPart.wipers:
        return 'Windshield Wipers';
    }
  }

  bool _getPartValue(CarPart part) {
    switch (part) {
      case CarPart.frontLeftDoor:
        return _status.frontLeftDoor;
      case CarPart.frontRightDoor:
        return _status.frontRightDoor;
      case CarPart.rearLeftDoor:
        return _status.rearLeftDoor;
      case CarPart.rearRightDoor:
        return _status.rearRightDoor;
      case CarPart.trunk:
        return _status.trunk;
      case CarPart.hood:
        return _status.hood;
      case CarPart.lights:
        return _status.lights;
      case CarPart.wipers:
        return _status.wipers;
    }
  }

  String _getPartColumnName(CarPart part) {
    switch (part) {
      case CarPart.frontLeftDoor:
        return 'front_left_door';
      case CarPart.frontRightDoor:
        return 'front_right_door';
      case CarPart.rearLeftDoor:
        return 'rear_left_door';
      case CarPart.rearRightDoor:
        return 'rear_right_door';
      case CarPart.trunk:
        return 'trunk';
      case CarPart.hood:
        return 'hood';
      case CarPart.lights:
        return 'lights';
      case CarPart.wipers:
        return 'wipers';
    }
  }

  bool _isTogglePart(CarPart part) {
    return part == CarPart.lights || part == CarPart.wipers;
  }

  Widget _buildPartActionSheet(String partName, bool currentValue, CarPart part) {
    final isToggle = _isTogglePart(part);
    final actionOn = isToggle ? 'Turn On' : 'Open';
    final actionOff = isToggle ? 'Turn Off' : 'Close';
    final stateOn = isToggle ? 'On' : 'Open';
    final stateOff = isToggle ? 'Off' : 'Closed';

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                _getPartIcon(part),
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    partName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    'Current status: ${currentValue ? stateOn : stateOff}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: currentValue ? Colors.amber.shade700 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: currentValue
                      ? null
                      : () {
                          _updatePartStatus(part, true);
                          Navigator.pop(context);
                        },
                  icon: Icon(isToggle ? Icons.power : Icons.lock_open),
                  label: Text(actionOn),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: !currentValue
                      ? null
                      : () {
                          _updatePartStatus(part, false);
                          Navigator.pop(context);
                        },
                  icon: Icon(isToggle ? Icons.power_off : Icons.lock),
                  label: Text(actionOff),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  IconData _getPartIcon(CarPart part) {
    switch (part) {
      case CarPart.frontLeftDoor:
      case CarPart.frontRightDoor:
      case CarPart.rearLeftDoor:
      case CarPart.rearRightDoor:
        return Icons.door_sliding_outlined;
      case CarPart.trunk:
        return Icons.inventory_2_outlined;
      case CarPart.hood:
        return Icons.construction_outlined;
      case CarPart.lights:
        return Icons.lightbulb_outline;
      case CarPart.wipers:
        return Icons.water_drop_outlined;
    }
  }

  Future<void> _updatePartStatus(CarPart part, bool value) async {
    if (_statusId == null) return;

    try {
      await supabase.from('car_status').update({
        _getPartColumnName(part): value,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', _statusId!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Car Status'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Text(
                                  'Tap any part to control',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Highlighted areas indicate open/on status',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 600,
                          child: InteractiveCar(
                            status: _status,
                            onPartTapped: _onPartTapped,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildStatusBar(),
              ],
            ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatusItem(
            Icons.door_sliding,
            'Doors',
            _countOpenDoors(),
          ),
          _buildStatusItem(
            Icons.lightbulb,
            'Lights',
            _status.lights ? 'On' : 'Off',
          ),
          _buildStatusItem(
            Icons.water_drop,
            'Wipers',
            _status.wipers ? 'On' : 'Off',
          ),
          _buildStatusItem(
            Icons.inventory_2,
            'Trunk',
            _status.trunk ? 'Open' : 'Closed',
          ),
          _buildStatusItem(
            Icons.construction,
            'Hood',
            _status.hood ? 'Open' : 'Closed',
          ),
        ],
      ),
    );
  }

  String _countOpenDoors() {
    int count = 0;
    if (_status.frontLeftDoor) count++;
    if (_status.frontRightDoor) count++;
    if (_status.rearLeftDoor) count++;
    if (_status.rearRightDoor) count++;
    return '$count/4 Open';
  }

  Widget _buildStatusItem(IconData icon, String label, String value) {
    final isActive = value.contains('On') || value.contains('Open') || 
                     (value.contains('/') && !value.startsWith('0'));
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isActive ? Colors.amber.shade700 : Colors.grey,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.amber.shade700 : null,
          ),
        ),
      ],
    );
  }
}
