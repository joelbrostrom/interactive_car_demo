import 'package:flutter/material.dart';

import '../supabase_config.dart';

class CarDetailsPage extends StatefulWidget {
  const CarDetailsPage({super.key});

  @override
  State<CarDetailsPage> createState() => _CarDetailsPageState();
}

class _CarDetailsPageState extends State<CarDetailsPage> {
  Map<String, dynamic>? _carData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCarDetails();
  }

  Future<void> _loadCarDetails() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final data =
          await supabase
              .from('cars')
              .select()
              .eq('user_id', userId)
              .maybeSingle();

      if (mounted) {
        setState(() {
          _carData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading car details: $e');
      if (mounted) {
        setState(() => _isLoading = false);
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
                color: const Color(0xFF7C4DFF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.analytics_rounded,
                size: 20,
                color: Color(0xFF7C4DFF),
              ),
            ),
            const SizedBox(width: 12),
            const Text('Vehicle Details'),
          ],
        ),
        centerTitle: true,
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
              )
              : _carData == null
              ? _buildNoCar()
              : _buildCarDetails(),
    );
  }

  Widget _buildNoCar() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF21262D),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF30363D)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF8B949E).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_car_outlined,
                size: 60,
                color: Color(0xFF8B949E),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No vehicle registered',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFFF0F6FC),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Go to Control to initialize your car',
              style: TextStyle(fontSize: 14, color: Color(0xFF8B949E)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarDetails() {
    final model = _carData!['model'] ?? 'Unknown';
    final year = _carData!['year'] ?? 0;
    final distanceKm = _carData!['distance_km'] ?? 0;
    final color = _carData!['color'] ?? 'Unknown';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCarImage(model),
          const SizedBox(height: 24),
          _buildHeaderCard(model, year),
          const SizedBox(height: 16),
          _buildSpecsGrid(year, distanceKm, color),
          const SizedBox(height: 16),
          _buildFeaturesCard(),
        ],
      ),
    );
  }

  Widget _buildCarImage(String model) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A365D), Color(0xFF0D1117)],
        ),
        border: Border.all(color: const Color(0xFF30363D), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
            blurRadius: 30,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00E5FF).withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.directions_car,
                    size: 56,
                    color: Color(0xFF00E5FF),
                  ),
                ),
                const SizedBox(height: 16),
                ShaderMask(
                  shaderCallback:
                      (bounds) => const LinearGradient(
                        colors: [Color(0xFF00E5FF), Color(0xFF7C4DFF)],
                      ).createShader(bounds),
                  child: Text(
                    'Toyota $model',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(String model, int year) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF21262D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF00E5FF).withValues(alpha: 0.2),
                      const Color(0xFF7C4DFF).withValues(alpha: 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                  ),
                ),
                child: const Text(
                  'TOYOTA',
                  style: TextStyle(
                    color: Color(0xFF00E5FF),
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF238636).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF238636).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      size: 16,
                      color: Color(0xFF3FB950),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Registered',
                      style: TextStyle(
                        color: Color(0xFF3FB950),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            model,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Color(0xFFF0F6FC),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$year Model Year',
            style: const TextStyle(fontSize: 16, color: Color(0xFF8B949E)),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecsGrid(int year, int distanceKm, String color) {
    return Row(
      children: [
        Expanded(
          child: _buildSpecCard(
            icon: Icons.calendar_today,
            label: 'Year',
            value: year.toString(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSpecCard(
            icon: Icons.speed,
            label: 'Odometer',
            value: '${_formatNumber(distanceKm)} km',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSpecCard(
            icon: Icons.palette,
            label: 'Color',
            value: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSpecCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF21262D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF00E5FF), size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF8B949E)),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFFF0F6FC),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF21262D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C4DFF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFF7C4DFF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Features',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF0F6FC),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildFeatureRow(
            Icons.local_gas_station_rounded,
            'Fuel Type',
            'Hybrid',
          ),
          _buildFeatureRow(Icons.settings_rounded, 'Transmission', 'Automatic'),
          _buildFeatureRow(Icons.event_seat_rounded, 'Seats', '5'),
          _buildFeatureRow(
            Icons.ac_unit_rounded,
            'Climate Control',
            'Dual Zone',
          ),
          _buildFeatureRow(
            Icons.speaker_rounded,
            'Audio System',
            'Premium JBL',
          ),
          _buildFeatureRow(Icons.shield_rounded, 'Safety Rating', '5 Stars'),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF8B949E)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: Color(0xFF8B949E)),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF30363D),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFFF0F6FC),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}
