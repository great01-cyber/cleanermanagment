import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  bool _isLoading = true;
  List<QueryDocumentSnapshot> _logs = [];
  Map<String, double> _productCounts = {};
  int _totalCollected = 0;
  String _mostCollectedItem = 'N/A';

  // --- List of colors for our pie chart ---
  final List<Color> _chartColors = [
    Colors.blue.shade400,
    Colors.red.shade400,
    Colors.green.shade400,
    Colors.orange.shade400,
    Colors.purple.shade400,
    Colors.teal.shade400,
    Colors.pink.shade400,
    Colors.indigo.shade400,
  ];

  @override
  void initState() {
    super.initState();
    _fetchStatistics();
  }

  /// Fetches data from the 'inventory_logs' collection and processes it.
  Future<void> _fetchStatistics() async {
    try {
      final now = DateTime.now();
      // Get all logs from the last 30 days
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      // --- This query is the most important part ---
      // It assumes you have a collection 'inventory_logs' with a 'timestamp' field.
      // Make sure you have a Firestore index for this query.
      final querySnapshot = await FirebaseFirestore.instance
          .collection('inventory_logs')
          .where('timestamp', isGreaterThanOrEqualTo: thirtyDaysAgo)
          .orderBy('timestamp', descending: true)
          .get();

      final logs = querySnapshot.docs;

      if (!mounted) return;

      // Process the data
      _processLogData(logs);

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching statistics: $e. Do you have an "inventory_logs" collection?'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('Error fetching statistics: $e');
    }
  }

  /// Processes the raw Firestore logs into usable stats
  void _processLogData(List<QueryDocumentSnapshot> logs) {
    Map<String, double> productCounts = {};
    int totalCollected = 0;

    for (var doc in logs) {
      final data = doc.data() as Map<String, dynamic>;
      final String productName = data['productName'] ?? 'Unknown';
      final int quantity = data['quantity'] ?? 0;

      // Add to product counts
      productCounts.update(productName, (value) => value + quantity, ifAbsent: () => quantity.toDouble());

      // Add to total
      totalCollected += quantity;
    }

    // Find the most collected item
    String mostCollected = 'N/A';
    if (productCounts.isNotEmpty) {
      mostCollected = productCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }

    setState(() {
      _logs = logs;
      _productCounts = productCounts;
      _totalCollected = totalCollected;
      _mostCollectedItem = mostCollected;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Statistics'),
        backgroundColor: Colors.blue, // Consistent with StoreInventory page
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _fetchStatistics();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Summary (Last 30 Days)',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildStatCards(),
              const SizedBox(height: 24),

              Text(
                'Item Collection Breakdown',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildPieChart(),

              const SizedBox(height: 24),
              Text(
                'Recent Activity',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildRecentActivityList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'No Data Available',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              'No items have been collected from the store in the last 30 days.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the top summary cards
  Widget _buildStatCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Total Items Collected',
            value: _totalCollected.toString(),
            icon: Icons.inventory_2,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Most Collected Item',
            value: _mostCollectedItem,
            icon: Icons.star,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        height: 130, // Fixed height for consistent look
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border(left: BorderSide(color: color, width: 5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 30, color: color),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  title,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the Pie Chart and its legend
  Widget _buildPieChart() {
    // This creates the list of PieChartSectionData from our map
    List<PieChartSectionData> sections = [];
    int i = 0;
    _productCounts.entries.forEach((entry) {
      final isTouched = false; // We can add touch interactivity later
      final double radius = isTouched ? 60.0 : 50.0;
      final Color color = _chartColors[i % _chartColors.length];

      sections.add(
        PieChartSectionData(
          color: color,
          value: entry.value,
          title: '${entry.value.toInt()}', // Show quantity on chart
          radius: radius,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      i++;
    });

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // --- The Chart ---
            Expanded(
              child: SizedBox(
                height: 180,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        // TODO: Add interactivity if needed
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: sections,
                  ),
                ),
              ),
            ),

            // --- The Legend ---
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _productCounts.entries.map((entry) {
                  final Color color = _chartColors[sections.indexWhere(
                          (s) => s.value == entry.value) % _chartColors.length];
                  return _buildLegendIndicator(
                    color: color,
                    text: entry.key,
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper widget for the pie chart legend
  Widget _buildLegendIndicator({required Color color, required String text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(4),
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the list of recent transactions
  Widget _buildRecentActivityList() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: _logs.take(5).map((doc) { // Show top 5 recent
          final data = doc.data() as Map<String, dynamic>;
          final String productName = data['productName'] ?? 'Unknown';
          final int quantity = data['quantity'] ?? 0;
          final String cleanerName = data['cleanerName'] ?? 'Unknown User';
          final Timestamp timestamp = data['timestamp'] ?? Timestamp.now();

          // Format the date
          final String formattedDate =
          DateFormat('MMM d, yyyy - hh:mm a').format(timestamp.toDate());

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade50,
              child: Icon(Icons.inventory, color: Colors.blue.shade600),
            ),
            title: Text(
              '$productName (x$quantity)',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Collected by $cleanerName\n$formattedDate',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            isThreeLine: true,
          );
        }).toList(),
      ),
    );
  }
}