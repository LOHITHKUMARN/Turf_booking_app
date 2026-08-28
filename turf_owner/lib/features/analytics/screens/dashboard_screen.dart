import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/turf_provider.dart';
import '../../payouts/screens/payout_screen.dart';

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final owner = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Dashboard'),
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: Provider.of<TurfProvider>(context, listen: false).fetchStats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final stats = snapshot.data;
          final advanced = stats?['advanced'] ?? {};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(
                  'Total Revenue',
                  'Rs. ${stats?['totalRevenue'] ?? 0}',
                  Icons.payments_outlined,
                  const Color(0xFF00A86B),
                  isLarge: true,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Bookings',
                        '${stats?['totalBookings'] ?? 0}',
                        Icons.event_available_outlined,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Venues',
                        '${stats?['totalTurfs'] ?? 0}',
                        Icons.stadium_outlined,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                // Advanced Analytics Section
                _buildSectionHeader('Performance Insights'),
                const SizedBox(height: 12),
                _buildInsightsSection(advanced['insights']),
                
                const SizedBox(height: 32),
                _buildSectionHeader('Revenue Trend (30 Days)'),
                const SizedBox(height: 12),
                _buildRevenueTrendChart(advanced['revenueTrend']),
                
                const SizedBox(height: 32),
                _buildSectionHeader('Hour-wise Revenue'),
                const SizedBox(height: 12),
                _buildHourWiseRevenueChart(advanced['revenueByHour']),
                
                const SizedBox(height: 32),
                _buildSectionHeader('Sport-wise Split'),
                const SizedBox(height: 12),
                _buildSportWiseSplitChart(advanced['revenueBySport']),

                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionHeader('Payout History'),
                    TextButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => PayoutScreen()));
                      },
                      child: const Text('New Request'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (stats?['payouts'] != null && (stats?['payouts'] as List).isNotEmpty)
                  ... (stats?['payouts'] as List).map((payout) => _buildPayoutItem(
                    payout['date'],
                    'Rs. ${payout['amount']}',
                    payout['status'],
                  )).toList()
                else
                  _buildEmptyPayouts(),
                const SizedBox(height: 32),
                _buildInfoBanner(),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color, {bool isLarge = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: isLarge ? 28 : 22),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: isLarge ? 24 : 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutItem(String date, String amount, String status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF00A86B).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_downward, color: Color(0xFF00A86B), size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  status.toUpperCase(),
                  style: TextStyle(color: const Color(0xFF00A86B), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPayouts() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey[200]),
          const SizedBox(height: 12),
          Text(
            'No payout history yet',
            style: TextStyle(color: Colors.grey[400], fontSize: 14, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF1A1A1A),
      ),
    );
  }

  Widget _buildInsightsSection(List<dynamic>? insights) {
    if (insights == null || insights.isEmpty) return const SizedBox();
    return Column(
      children: insights.map((insight) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.blue, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                insight.toString(),
                style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildRevenueTrendChart(List<dynamic>? trend) {
    if (trend == null || trend.isEmpty) return _buildEmptyChart();
    
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: trend.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value['amount'] ?? 0).toDouble())).toList(),
              isCurved: true,
              color: const Color(0xFF00A86B),
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF00A86B).withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHourWiseRevenueChart(List<dynamic>? revenueByHour) {
    if (revenueByHour == null || revenueByHour.isEmpty) return _buildEmptyChart();
    
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: BarChart(
        BarChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value % 4 == 0) {
                    return Text('${value.toInt()}h', style: const TextStyle(fontSize: 10));
                  }
                  return const SizedBox();
                },
              ),
            ),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: revenueByHour.asMap().entries.map((e) => BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.toDouble(),
                color: Colors.blue.withOpacity(0.8),
                width: 6,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildSportWiseSplitChart(Map<dynamic, dynamic>? revenueBySport) {
    if (revenueBySport == null || revenueBySport.isEmpty) return _buildEmptyChart();
    
    final List<Color> colors = [Colors.green, Colors.blue, Colors.orange, Colors.purple, Colors.red];
    int colorIndex = 0;

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: PieChart(
        PieChartData(
          sections: revenueBySport.entries.map((e) {
            final color = colors[colorIndex % colors.length];
            colorIndex++;
            return PieChartSectionData(
              value: e.value.toDouble(),
              title: e.key.toString(),
              color: color,
              radius: 50,
              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            );
          }).toList(),
          sectionsSpace: 2,
          centerSpaceRadius: 40,
        ),
      ),
    );
  }

  Widget _buildEmptyChart() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Text('No data available yet', style: TextStyle(color: Colors.grey[400])),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF00A86B).withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF00A86B).withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF00A86B)),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Payouts are processed every Monday for the previous week\'s bookings.',
              style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
