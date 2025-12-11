import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../controllers/anaylytics_controller.dart';

class AnalyticsDashboard extends StatelessWidget {
  const AnalyticsDashboard({super.key});

  // Function to generate dynamic colors based on data range
  List<Color> _generateDynamicColors(List<double> data, bool isDarkMode) {
    final colors = <Color>[];
    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final minValue = data.reduce((a, b) => a < b ? a : b);

    for (var value in data) {
      final ratio = (value - minValue) / (maxValue - minValue + 1); // Normalize between 0 and 1
      final r = (50 + (200 * ratio)).toInt(); // Red component (50 to 250)
      final g = (150 - (100 * ratio)).toInt(); // Green component (150 to 50)
      final b = (200 * (1 - ratio)).toInt(); // Blue component (200 to 0)
      colors.add(Color.fromRGBO(r, g, b, 1));
    }
    return colors;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDarkMode ? Colors.tealAccent : Colors.teal;
    final cardColor = isDarkMode ? Colors.grey[850]! : Colors.white;
    final backgroundColor = isDarkMode ? Colors.grey[900]! : Colors.grey[100]!;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return ChangeNotifierProvider(
      create: (_) => AnalyticsProvider(),
      child: Scaffold(
        backgroundColor: backgroundColor,

        body: Consumer<AnalyticsProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return _ShimmerLoader(cardColor: cardColor, isDarkMode: isDarkMode);
            }

            if (provider.errorMessage.isNotEmpty) {
              return _ErrorSection(
                message: provider.errorMessage,
                onRetry: provider.retryFetchAnalytics,
                color: primaryColor,
              );
            }

            final analytics = provider.analytics!;
            final maxY = analytics.chartData.data.reduce((a, b) => a > b ? a : b) * 1.2;
            final screenWidth = MediaQuery.of(context).size.width;
            final dynamicColors = _generateDynamicColors(analytics.chartData.data, isDarkMode);

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04, // Responsive padding
                vertical: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AnimatedHeader("Earnings Overview", primaryColor),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: "Monthly Earnings",
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final chartWidth = analytics.chartData.data.length * 50.0;
                        final fontSize = screenWidth < 400 ? 10.0 : 12.0;

                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: chartWidth < screenWidth ? screenWidth - 32 : chartWidth,
                            height: screenWidth < 400 ? 250 : 300, // Responsive height
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: maxY,
                                barGroups: analytics.chartData.data.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final value = entry.value;
                                  return BarChartGroupData(
                                    x: index,
                                    barRods: [
                                      BarChartRodData(
                                        toY: value,
                                        color: dynamicColors[index],
                                        width: screenWidth < 400 ? 16 : 20,
                                        borderRadius: BorderRadius.circular(8),
                                        backDrawRodData: BackgroundBarChartRodData(
                                          show: true,
                                          toY: maxY,
                                          color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                                        ),
                                      ),
                                    ],
                                    showingTooltipIndicators: [0],
                                  );
                                }).toList(),
                                titlesData: FlTitlesData(
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 50,
                                      getTitlesWidget: (value, meta) => Text(
                                        '₹${value.toInt()}',
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: fontSize,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        int index = value.toInt();
                                        if (index < 0 || index >= analytics.chartData.labels.length) {
                                          return const SizedBox.shrink();
                                        }
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Transform.rotate(
                                            angle: -0.3, // Reduced rotation for better visibility
                                            child: Text(
                                              analytics.chartData.labels[index],
                                              style: TextStyle(
                                                color: textColor,
                                                fontSize: fontSize,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              textAlign: TextAlign.center,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        );
                                      },
                                      reservedSize: 50, // Increased to prevent clipping
                                    ),
                                  ),
                                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                ),
                                borderData: FlBorderData(show: false),
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval: maxY / 5,
                                  getDrawingHorizontalLine: (value) => FlLine(
                                    color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                                    strokeWidth: 1,
                                  ),
                                ),
                                barTouchData: BarTouchData(
                                  enabled: true,
                                  touchTooltipData: BarTouchTooltipData(
                                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                      return BarTooltipItem(
                                        '₹${rod.toY.toInt()}',
                                        TextStyle(color: textColor, fontWeight: FontWeight.bold),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  _AnimatedHeader("Category Distribution", primaryColor),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: "Earnings by Category",
                    child: SizedBox(
                      height: screenWidth < 400 ? 250 : 300, // Responsive height
                      child: PieChart(
                        PieChartData(
                          sections: analytics.chartData.data.asMap().entries.map((entry) {
                            final index = entry.key;
                            final value = entry.value;
                            return PieChartSectionData(
                              color: dynamicColors[index],
                              value: value,
                              title: '${(value / analytics.chartData.data.reduce((a, b) => a + b) * 100).toStringAsFixed(1)}%',
                              radius: screenWidth < 400 ? 80 : 100,
                              titleStyle: TextStyle(
                                fontSize: screenWidth < 400 ? 10 : 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              badgeWidget: Text(
                                analytics.chartData.labels[index],
                                style: TextStyle(
                                  fontSize: screenWidth < 400 ? 10 : 12,
                                  color: textColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              badgePositionPercentageOffset: 1.2,
                            );
                          }).toList(),
                          sectionsSpace: 2,
                          centerSpaceRadius: screenWidth < 400 ? 30 : 40,
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, pieTouchResponse) {
                              // Handle touch interactions if needed
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AnimatedHeader extends StatelessWidget {
  final String title;
  final Color color;
  const _AnimatedHeader(this.title, this.color);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0, end: 1),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset((1 - value) * 30, 0),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0, end: 1),
      curve: Curves.easeOutQuad,
      builder: (context, value, childWidget) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 20),
            child: childWidget,
          ),
        );
      },
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorSection extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final Color color;
  const _ErrorSection({required this.message, required this.onRetry, required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 5,
              ),
              child: const Text(
                'Retry',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerLoader extends StatelessWidget {
  final Color cardColor;
  final bool isDarkMode;
  const _ShimmerLoader({required this.cardColor, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}