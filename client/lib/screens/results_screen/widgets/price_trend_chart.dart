import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class PriceTrendChart extends StatelessWidget {
  final Map<String, List<PricePoint>> platformData;
  final Map<String, dynamic>? lowestPrice;

  const PriceTrendChart({super.key, required this.platformData, this.lowestPrice});

  @override
  Widget build(BuildContext context) {
    if (platformData.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('暂无历史价格数据')),
      );
    }

    final colors = _platformColors();
    final allDates = <String>{};
    for (final points in platformData.values) {
      for (final p in points) {
        allDates.add(p.date);
      }
    }
    final sortedDates = allDates.toList()..sort();

    double minPrice = double.infinity;
    double maxPrice = 0;
    for (final points in platformData.values) {
      for (final p in points) {
        if (p.price < minPrice) minPrice = p.price;
        if (p.price > maxPrice) maxPrice = p.price;
      }
    }
    if (minPrice == double.infinity) {
      minPrice = 0;
      maxPrice = 100;
    }
    final priceMargin = (maxPrice - minPrice) * 0.25;
    minPrice = (minPrice - priceMargin).clamp(0, double.infinity);
    maxPrice = maxPrice + priceMargin * 1.2;

    final lineBars = <LineChartBarData>[];
    int colorIndex = 0;

    platformData.forEach((platform, points) {
      final dateIndexMap = <String, int>{};
      for (int i = 0; i < sortedDates.length; i++) {
        dateIndexMap[sortedDates[i]] = i;
      }

      final spots = <FlSpot>[];
      for (final p in points) {
        final idx = dateIndexMap[p.date];
        if (idx != null) {
          spots.add(FlSpot(idx.toDouble(), p.price));
        }
      }
      spots.sort((a, b) => a.x.compareTo(b.x));

      final color = colors[platform] ??
          Colors.primaries[colorIndex % Colors.primaries.length];
      colorIndex++;

      lineBars.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          preventCurveOverShooting: true,
          color: color,
          barWidth: 2.5,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, _, __, ___) =>
                FlDotCirclePainter(radius: 4, color: color),
          ),
          belowBarData: BarAreaData(
            show: true,
            color: color.withOpacity(0.1),
          ),
        ),
      );
    });

    // Build lowest price horizontal line if available
    LineChartBarData? lowestPriceLine;
    if (lowestPrice != null) {
      final lp = (lowestPrice!['price'] as num?)?.toDouble() ?? 0;
      final lpPlatform = lowestPrice!['platform'] as String? ?? '';
      lowestPriceLine = LineChartBarData(
        spots: [
          FlSpot(0, lp),
          FlSpot((sortedDates.length - 1).toDouble(), lp),
        ],
        isCurved: false,
        color: Colors.red,
        barWidth: 1.5,
        dashArray: [5, 3],
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (lowestPrice != null) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '历史最低 ¥${lowestPrice!['price']} (${lowestPrice!['platform']})',
              style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
        SizedBox(
          height: 280,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: (sortedDates.length - 1).toDouble(),
              minY: minPrice,
              maxY: maxPrice,
              lineBarsData: [...lineBars, if (lowestPriceLine != null) lowestPriceLine],
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: ((maxPrice - minPrice) / 5).clamp(1, double.infinity),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx >= 0 && idx < sortedDates.length) {
                        final short = sortedDates[idx].length >= 10
                            ? sortedDates[idx].substring(5, 10)
                            : sortedDates[idx];
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Transform.rotate(
                            angle: -0.6,
                            child: Text(
                              short,
                              style: const TextStyle(fontSize: 9),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 48,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '¥${value.toInt()}',
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Legend
        Wrap(
          spacing: 16,
          children: platformData.keys.map((platform) {
            final color = colors[platform] ?? Colors.grey;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(platform, style: const TextStyle(fontSize: 12)),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Map<String, Color> _platformColors() {
    return {
      '淘宝': Colors.orange,
      '京东': Colors.red,
      '拼多多': Colors.teal,
    };
  }
}

class PricePoint {
  final String date;
  final double price;

  const PricePoint({required this.date, required this.price});

  factory PricePoint.fromJson(Map<String, dynamic> json) {
    return PricePoint(
      date: json['date'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
    );
  }
}
