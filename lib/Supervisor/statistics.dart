import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

// --- 1. The Data Model ---
class CleaningItem {
  final String name;
  final String type;
  final Color color;
  int quantity;

  CleaningItem({
    required this.name,
    required this.type,
    required this.color,
    required this.quantity,
  });
}

// --- 2. The Hard-Coded Data ---
final List<CleaningItem> cleaningItems = [
  CleaningItem(name: 'Blue Mop', type: 'Mop', color: Colors.blue, quantity: 8),
  CleaningItem(name: 'Red Mop', type: 'Mop', color: Colors.red, quantity: 4),
  CleaningItem(name: 'Spray Bottle', type: 'Spray', color: Colors.grey, quantity: 12),
  CleaningItem(name: 'White Tissue', type: 'Tissue', color: Colors.white, quantity: 200),
  CleaningItem(name: 'Yellow Mop', type: 'Mop', color: Colors.yellow, quantity: 2),
];

// Helper to get a readable color name
String colorToString(Color color) {
  if (color == Colors.blue) return 'Blue';
  if (color == Colors.red) return 'Red';
  if (color == Colors.yellow) return 'Yellow';
  if (color == Colors.white) return 'White';
  if (color == Colors.grey) return 'Grey';
  return 'Other';
}

// --- 3. The Statistics Page ---
class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  late Map<String, int> typeTotals;
  late Map<Color, int> colorTotals;
  late int totalItems;
  late int totalTypes;
  int _pieTouchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _calculateStats();
  }

  void _calculateStats() {
    final Map<String, int> typeData = {};
    final Map<Color, int> colorData = {};
    int items = 0;
    final Set<String> uniqueTypes = {};

    for (var item in cleaningItems) {
      typeData[item.type] = (typeData[item.type] ?? 0) + item.quantity;
      colorData[item.color] = (colorData[item.color] ?? 0) + item.quantity;
      items += item.quantity;
      uniqueTypes.add(item.type);
    }

    setState(() {
      typeTotals = typeData;
      colorTotals = colorData;
      totalItems = items;
      totalTypes = uniqueTypes.length;
    });
  }

  Future<void> _refreshData() async {
    final random = Random();
    setState(() {
      for (var item in cleaningItems) {
        item.quantity = random.nextInt(150) + 1;
        if (item.type == 'Tissue') {
          item.quantity += 50;
        }
      }
      _calculateStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cleaning Dashboard'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[100],
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Total Items',
                      value: totalItems.toString(),
                      icon: Icons.all_inbox_rounded,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatCard(
                      title: 'Item Types',
                      value: totalTypes.toString(),
                      icon: Icons.category_rounded,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Quantity by Type'),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildBarChart(typeTotals),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Quantity by Color'),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildPieChart(colorTotals),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  // --- Bar Chart ---
  Widget _buildBarChart(Map<String, int> data) {
    if (data.isEmpty) return const SizedBox(height: 200, child: Center(child: Text('No data')));
    final keys = data.keys.toList();
    final values = data.values.toList();

    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (values.reduce(max) / 4).clamp(1, double.infinity).toDouble(),
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey[300],
              strokeWidth: 1,
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${keys[groupIndex]}\n',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  children: [
                    TextSpan(
                      text: rod.toY.round().toString(),
                      style: const TextStyle(color: Colors.cyan, fontWeight: FontWeight.w500),
                    ),
                  ],
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= keys.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(keys[index], style: const TextStyle(fontWeight: FontWeight.w500)),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox();
                  return Text(
                    value.round().toString(),
                    style: TextStyle(color: Colors.grey[700]),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(
            data.length,
                (index) => BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: values[index].toDouble(),
                  gradient: LinearGradient(
                    colors: [Colors.indigo.shade300, Colors.indigo],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  width: 24,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Pie Chart ---
  Widget _buildPieChart(Map<Color, int> data) {
    if (data.isEmpty) return const SizedBox(height: 200, child: Center(child: Text('No data')));
    final total = data.values.fold<int>(0, (a, b) => a + b);
    final entries = data.entries.toList();

    return SizedBox(
      height: 220,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        _pieTouchedIndex = -1;
                        return;
                      }
                      _pieTouchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                sectionsSpace: 4,
                centerSpaceRadius: 50,
                sections: List.generate(entries.length, (i) {
                  final e = entries[i];
                  final isTouched = i == _pieTouchedIndex;
                  final double radius = isTouched ? 70 : 60;
                  final double percent = (e.value / total * 100);

                  return PieChartSectionData(
                    color: e.key == Colors.white ? Colors.grey[300] : e.key,
                    value: e.value.toDouble(),
                    title: '${percent.toStringAsFixed(0)}%',
                    radius: radius,
                    titleStyle: TextStyle(
                      fontSize: isTouched ? 16 : 14,
                      fontWeight: FontWeight.bold,
                      color: e.key == Colors.yellow ? Colors.black87 : Colors.white,
                      shadows: const [Shadow(color: Colors.black26, blurRadius: 2)],
                    ),
                  );
                }),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: data.entries.map((e) {
                return Indicator(
                  color: e.key == Colors.white ? Colors.grey[300]! : e.key,
                  text: colorToString(e.key),
                  isSquare: false,
                  size: 14,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Stat Card ---
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: color, width: 5)),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}

// --- Legend Indicator ---
class Indicator extends StatelessWidget {
  const Indicator({
    super.key,
    required this.color,
    required this.text,
    this.isSquare = false,
    this.size = 16,
    this.textColor,
  });

  final Color color;
  final String text;
  final bool isSquare;
  final double size;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textColor ?? Colors.black,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
