import 'package:breath_state/constants/file_constants.dart';
import 'package:breath_state/providers/polar_connect_provider.dart';
import 'package:breath_state/services/ble_service/ble_scanning.dart';
import 'package:breath_state/services/file_service/file_write.dart';
import 'package:breath_state/theme/app_theme.dart';
import 'package:breath_state/widgets/ble_device_select.dart';
import 'package:breath_state/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _selectDeviceUUID;
  bool _isConnected = false;
  final fileSharer = FileWriterService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.deepOceanBlue,
              AppTheme.midnightBlue,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    "Settings",
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                ),
                const SizedBox(height: 40),

                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.bluetooth,
                              size: 24,
                              color: Colors.blueAccent,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Polar Sensor",
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                                Text(
                                  _isConnected ? "Connected" : "Disconnected",
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: _isConnected ? Colors.greenAccent : Colors.redAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            await BleScanning.requestPermissions();
                            await BleScanning.checkAndRequestBluetooth(context);
                            await BleScanning.checkAndRequestLocation(context);
                            _selectDeviceUUID = await Navigator.push<String>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const BleDeviceSelect(),
                              ),
                            );
                            developer.log(
                              "Selected Device UUID: $_selectDeviceUUID",
                            );
                            if (_selectDeviceUUID != null) {
                              setState(() => _isConnected = true);
                              await context
                                  .read<PolarConnectProvider>()
                                  .connectToPolarSensor(_selectDeviceUUID!);
                            }
                          },
                          child: Text(_isConnected ? "Reconnect" : "Connect Device"),
                        ),
                      ),
                      if (_selectDeviceUUID != null) ...[
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            "Device ID: $_selectDeviceUUID",
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                           Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.softTeal.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.download_rounded,
                              size: 24,
                              color: AppTheme.softTeal,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            "Export Data",
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            _showExportDialog(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.softTeal,
                            foregroundColor: AppTheme.deepOceanBlue,
                          ),
                          child: const Text("Export CSV"),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.midnightBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Export Data", style: Theme.of(context).textTheme.titleLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Select data to share",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            _ExportOption(
              label: "Breathing Data",
              onTap: () async {
                 Navigator.of(context).pop();
                await fileSharer.shareFile(BREATH_FILE_NAME);
              },
            ),
            const SizedBox(height: 12),
             _ExportOption(
              label: "ECG Data",
              onTap: () async {
                 Navigator.of(context).pop();
                await fileSharer.shareFile(ECG_FILE_NAME);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }
}

class _ExportOption extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ExportOption({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
    );
  }
}
