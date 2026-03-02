import 'package:flutter/material.dart';
import 'package:breath_state/services/hrv_analysis/hrv_time_domain.dart';
import 'package:breath_state/widgets/glass_card.dart';
import 'package:breath_state/theme/app_theme.dart';

class HrvResultCard extends StatefulWidget {
  final HrvTimeDomainResult result;
  final bool expanded;

  const HrvResultCard({
    super.key,
    required this.result,
    this.expanded = false,
  });

  @override
  State<HrvResultCard> createState() => _HrvResultCardState();
}

class _HrvResultCardState extends State<HrvResultCard> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.expanded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.monitor_heart_rounded,
                color: AppTheme.roseAccent,
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                "HRV Analysis",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              _buildBadge(context, isDark),
            ],
          ),
          const SizedBox(height: 16),
          _buildEssentialsGrid(context, isDark),
          if (_expanded) ...[
            const SizedBox(height: 20),
            _buildDivider(isDark),
            const SizedBox(height: 16),
            _buildExpandedMetrics(context, isDark),
          ],
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _expanded = !_expanded),
              icon: Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                size: 20,
                color: AppTheme.softTeal,
              ),
              label: Text(
                _expanded ? "Show less" : "Show all metrics",
                style: TextStyle(
                  color: AppTheme.softTeal,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(BuildContext context, bool isDark) {
    final hr = (60000.0 / widget.result.meanNN).toStringAsFixed(0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.roseAccent.withOpacity(isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        "$hr bpm",
        style: TextStyle(
          color: AppTheme.roseAccent,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildEssentialsGrid(BuildContext context, bool isDark) {
    final essentials = widget.result.essentials();
    final entries = essentials.entries.toList();

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: entries.map((e) {
        return SizedBox(
          width: (MediaQuery.of(context).size.width - 96) / 2,
          child: _MetricTile(
            label: e.key,
            value: e.value,
            isDark: isDark,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            (isDark ? Colors.white : Colors.black).withOpacity(0.15),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedMetrics(BuildContext context, bool isDark) {
    final r = widget.result;

    final groups = <String, List<_MetricEntry>>{
      'Deviation-based': [
        _MetricEntry('Mean NN', r.meanNN, 'ms'),
        _MetricEntry('SDNN', r.sdnn, 'ms'),
      ],
      'Difference-based': [
        _MetricEntry('RMSSD', r.rmssd, 'ms'),
        _MetricEntry('SDSD', r.sdsd, 'ms'),
      ],
      'Normalised': [
        _MetricEntry('CVNN', r.cvnn, ''),
        _MetricEntry('CVSD', r.cvsd, ''),
      ],
      'Robust': [
        _MetricEntry('Median NN', r.medianNN, 'ms'),
        _MetricEntry('MAD NN', r.madNN, 'ms'),
        _MetricEntry('MCVNN', r.mcvnn, ''),
        _MetricEntry('IQR NN', r.iqrnn, 'ms'),
        _MetricEntry('SD/RMSSD', r.sdrmssd, ''),
        _MetricEntry('P20 NN', r.prc20nn, 'ms'),
        _MetricEntry('P80 NN', r.prc80nn, 'ms'),
      ],
      'Count / Extreme': [
        _MetricEntry('pNN50', r.pnn50, '%'),
        _MetricEntry('pNN20', r.pnn20, '%'),
        _MetricEntry('Min NN', r.minNN, 'ms'),
        _MetricEntry('Max NN', r.maxNN, 'ms'),
      ],
      'Geometric': [
        _MetricEntry('HTI', r.hti, ''),
        _MetricEntry('TINN', r.tinn, 'ms'),
      ],
      'Long-duration': [
        _MetricEntry('SDANN-1', r.sdann1, 'ms'),
        _MetricEntry('SDANN-2', r.sdann2, 'ms'),
        _MetricEntry('SDANN-5', r.sdann5, 'ms'),
        _MetricEntry('SDNNI-1', r.sdnni1, 'ms'),
        _MetricEntry('SDNNI-2', r.sdnni2, 'ms'),
        _MetricEntry('SDNNI-5', r.sdnni5, 'ms'),
      ],
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groups.entries.map((group) {
        final hasValues = group.value.any((m) => m.value != null && m.value!.isFinite);
        if (!hasValues) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 4),
              child: Text(
                group.key,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.softTeal.withOpacity(0.8),
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: group.value
                  .where((m) => m.value != null && m.value!.isFinite)
                  .map((m) {
                final formatted = m.unit == '%'
                    ? '${m.value!.toStringAsFixed(1)}%'
                    : m.unit.isNotEmpty
                        ? '${m.value!.toStringAsFixed(1)} ${m.unit}'
                        : m.value!.toStringAsFixed(3);
                return SizedBox(
                  width: (MediaQuery.of(context).size.width - 96) / 2,
                  child: _MetricTile(
                    label: m.label,
                    value: formatted,
                    isDark: isDark,
                    compact: true,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }
}

class _MetricEntry {
  final String label;
  final double? value;
  final String unit;
  _MetricEntry(this.label, this.value, this.unit);
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final bool compact;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.isDark,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: compact ? 6 : 10,
      ),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(isDark ? 0.06 : 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w600,
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: compact ? 13 : 15,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
