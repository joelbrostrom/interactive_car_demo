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

      final carData =
          await supabase
              .from('cars')
              .select('id')
              .eq('user_id', userId)
              .maybeSingle();

      if (carData == null) {
        final newCar =
            await supabase
                .from('cars')
                .insert({
                  'user_id': userId,
                  'model': 'Camry',
                  'year': 2024,
                  'distance_km': 15420,
                  'color': 'Silver',
                })
                .select()
                .single();

        _carId = newCar['id'];

        final newStatus =
            await supabase
                .from('car_status')
                .insert({'car_id': _carId})
                .select()
                .single();

        _statusId = newStatus['id'];
        _status = CarStatus.fromJson(newStatus);
      } else {
        _carId = carData['id'];

        final statusData =
            await supabase
                .from('car_status')
                .select()
                .eq('car_id', _carId!)
                .maybeSingle();

        if (statusData != null) {
          _statusId = statusData['id'];
          _status = CarStatus.fromJson(statusData);
        } else {
          final newStatus =
              await supabase
                  .from('car_status')
                  .insert({'car_id': _carId})
                  .select()
                  .single();

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

  Widget _buildPartActionSheet(
    String partName,
    bool currentValue,
    CarPart part,
  ) {
    final isToggle = _isTogglePart(part);
    final actionOn = isToggle ? 'Turn On' : 'Open';
    final actionOff = isToggle ? 'Turn Off' : 'Close';
    final stateOn = isToggle ? 'On' : 'Open';
    final stateOff = isToggle ? 'Off' : 'Closed';

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: const Color(0xFF30363D), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: const Color(0xFF30363D),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF00E5FF).withValues(alpha: 0.2),
                      const Color(0xFF7C4DFF).withValues(alpha: 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(
                  _getPartIcon(part),
                  size: 28,
                  color: const Color(0xFF00E5FF),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      partName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFF0F6FC),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                currentValue
                                    ? const Color(0xFFFFAB00)
                                    : const Color(0xFF8B949E),
                            boxShadow:
                                currentValue
                                    ? [
                                      BoxShadow(
                                        color: const Color(
                                          0xFFFFAB00,
                                        ).withValues(alpha: 0.5),
                                        blurRadius: 8,
                                      ),
                                    ]
                                    : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          currentValue ? stateOn : stateOff,
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                currentValue
                                    ? const Color(0xFFFFAB00)
                                    : const Color(0xFF8B949E),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  label: actionOn,
                  icon:
                      isToggle
                          ? Icons.power_settings_new
                          : Icons.lock_open_rounded,
                  isEnabled: !currentValue,
                  isPrimary: true,
                  onPressed: () {
                    _updatePartStatus(part, true);
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  label: actionOff,
                  icon: isToggle ? Icons.power_off_rounded : Icons.lock_rounded,
                  isEnabled: currentValue,
                  isPrimary: false,
                  onPressed: () {
                    _updatePartStatus(part, false);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required bool isEnabled,
    required bool isPrimary,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient:
            isEnabled && isPrimary
                ? const LinearGradient(
                  colors: [Color(0xFF00E5FF), Color(0xFF00B8D4)],
                )
                : null,
        color: isEnabled && !isPrimary ? const Color(0xFF21262D) : null,
        border:
            !isEnabled
                ? Border.all(color: const Color(0xFF30363D))
                : isPrimary
                ? null
                : Border.all(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
                ),
        boxShadow:
            isEnabled && isPrimary
                ? [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
                : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color:
                    isEnabled
                        ? isPrimary
                            ? const Color(0xFF003544)
                            : const Color(0xFF00E5FF)
                        : const Color(0xFF30363D),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color:
                      isEnabled
                          ? isPrimary
                              ? const Color(0xFF003544)
                              : const Color(0xFF00E5FF)
                          : const Color(0xFF30363D),
                ),
              ),
            ],
          ),
        ),
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
      await supabase
          .from('car_status')
          .update({
            _getPartColumnName(part): value,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', _statusId!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating status: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.dashboard_rounded,
                size: 20,
                color: Color(0xFF00E5FF),
              ),
            ),
            const SizedBox(width: 12),
            const Text('Vehicle Control'),
          ],
        ),
        centerTitle: true,
      ),
      body:
          _isLoading
              ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Color(0xFF00E5FF),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Connecting to vehicle...',
                      style: TextStyle(
                        color: const Color(0xFF8B949E),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFF21262D),
                                  const Color(
                                    0xFF21262D,
                                  ).withValues(alpha: 0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF30363D),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF00E5FF,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.touch_app_rounded,
                                    color: Color(0xFF00E5FF),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Interactive Control',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFFF0F6FC),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Tap any highlighted zone to control',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: const Color(0xFF8B949E),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF238636,
                                    ).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF238636,
                                      ).withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: const Color(0xFF3FB950),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(
                                                0xFF3FB950,
                                              ).withValues(alpha: 0.5),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'Live',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF3FB950),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        border: const Border(
          top: BorderSide(color: Color(0xFF30363D), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatusItem(
              Icons.sensor_door_rounded,
              'Doors',
              _countOpenDoors(),
            ),
            _buildStatusItem(
              Icons.lightbulb_rounded,
              'Lights',
              _status.lights ? 'On' : 'Off',
            ),
            _buildStatusItem(
              Icons.water_drop_rounded,
              'Wipers',
              _status.wipers ? 'On' : 'Off',
            ),
            _buildStatusItem(
              Icons.inventory_2_rounded,
              'Trunk',
              _status.trunk ? 'Open' : 'Closed',
            ),
            _buildStatusItem(
              Icons.handyman_rounded,
              'Hood',
              _status.hood ? 'Open' : 'Closed',
            ),
          ],
        ),
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
    final isActive =
        value.contains('On') ||
        value.contains('Open') ||
        (value.contains('/') && !value.startsWith('0'));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color:
            isActive
                ? const Color(0xFFFFAB00).withValues(alpha: 0.1)
                : const Color(0xFF21262D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isActive
                  ? const Color(0xFFFFAB00).withValues(alpha: 0.3)
                  : const Color(0xFF30363D),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 22,
            color: isActive ? const Color(0xFFFFAB00) : const Color(0xFF8B949E),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color:
                  isActive ? const Color(0xFFF0F6FC) : const Color(0xFF8B949E),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color:
                  isActive ? const Color(0xFFFFAB00) : const Color(0xFF8B949E),
            ),
          ),
        ],
      ),
    );
  }
}
