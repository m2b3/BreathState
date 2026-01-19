import 'package:breath_state/constants/db_constants.dart';
import 'package:breath_state/services/db_service/database_service.dart';
import 'package:breath_state/theme/app_theme.dart';
import 'package:breath_state/widgets/glass_card.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map> breathRows = [];
  List<Map> heartRows = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final dbService = DatabaseService.instance;
      List<Map> breathData = [];
      List<Map> heartData = [];
      
      try {
        breathData = await dbService.getData(BREATH_TABLE_NAME);
        heartData = await dbService.getData(HEART_TABLE_NAME);
      } catch (e) {
        debugPrint("Error loading data (tables might not exist): $e");
      }

      if (mounted) {
        setState(() {
          breathRows = breathData;
          heartRows = heartData;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  List<FlSpot> _mapToSpots(List<Map> rows) {
    if (rows.isEmpty) return [];
    final recentRows = rows.length > 20 ? rows.sublist(rows.length - 20) : rows;
    
    return recentRows.asMap().entries.map((entry) {
      final i = entry.key.toDouble();
      final rate = double.tryParse(entry.value['rate'].toString()) ?? 0.0;
      return FlSpot(i, rate);
    }).toList();
  }

  Widget _buildChartCard(List<Map> rows, String title, Color color, String unit) {
    final spots = _mapToSpots(rows);
    final hasData = spots.isNotEmpty;
    String displayValue = "--";
    if (hasData) {
      final lastVal = spots.last.y;
      displayValue = lastVal.toStringAsFixed(1);
    }

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        title.contains("Heart") ? Icons.favorite_rounded : Icons.air_rounded,
                        color: color.withOpacity(0.8),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: AppTheme.textDim,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        displayValue,
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        unit,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.show_chart_rounded,
                  color: color,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          AspectRatio(
            aspectRatio: 2.0,
            child: hasData
                ? LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: (spots.length - 1).toDouble(),
                      minY: spots.map((e) => e.y).reduce((a, b) => a < b ? a : b) * 0.8,
                      maxY: spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) * 1.2,
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          curveSmoothness: 0.35,
                          color: color,
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: color,
                                strokeWidth: 2,
                                strokeColor: Colors.white,
                              );
                            },
                            checkToShowDot: (spot, barData) {
                              return spot.x == barData.spots.last.x; // Only show last dot
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                color.withOpacity(0.25),
                                color.withOpacity(0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (touchedSpot) => AppTheme.midnightBlue.withOpacity(0.8),
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              return LineTooltipItem(
                                '${spot.y.toStringAsFixed(1)} $unit',
                                const TextStyle(
                                  color: Colors.white, 
                                  fontWeight: FontWeight.bold
                                ),
                              );
                            }).toList();
                          },
                        ),
                        handleBuiltInTouches: true,
                      ),
                    ),
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "Record data to generate summary graphs",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white30,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.mainBackgroundGradient,
        ),
        child: SafeArea(
          bottom: false,
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            Text(
                              _getGreeting(),
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppTheme.textDim,
                                    fontSize: 18,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Welcome Back",
                              style: Theme.of(context).textTheme.displayLarge,
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildChartCard(
                            breathRows,
                            "Breathing Rate",
                            AppTheme.softTeal,
                            "bpm",
                          ),
                          _buildChartCard(
                            heartRows,
                            "Heart Rate",
                            AppTheme.calmBlue,
                            "bpm",
                          ),
                          const SizedBox(height: 100), 
                        ]),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
