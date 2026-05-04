import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/firebase_service.dart';
import '../../../data/models/user_model.dart';
import '../../providers/auth_provider.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});
  @override State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final _ctrl = MobileScannerController();
  bool _scanned = false;
  bool _showMyQr = false;

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final barcode = capture.barcodes.firstOrNull;
    final value = barcode?.rawValue;
    if (value != null) {
      setState(() => _scanned = true);
      _ctrl.stop();
      _processScan(value);
    }
  }

  Future<void> _processScan(String studentId) async {
    // This method now returns the NEW status ('Boarded' or 'Dropped')
    final newStatus = await FirebaseService.notifyStudentStatus(studentId);
    
    if (!mounted) return;
    
    if (newStatus == 'error') {
      _showError('Student ID $studentId not found in database.');
    } else {
      _showResult(studentId, newStatus);
    }
  }

  void _showResult(String studentId, String status) {
    bool isBoarding = status == 'Boarded';
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Icon(
            isBoarding ? Icons.directions_bus_rounded : Icons.home_rounded, 
            color: isBoarding ? AppColors.success : AppColors.primary, 
            size: 56
          ),
          const SizedBox(height: 12),
          Text(isBoarding ? '$studentId Boarded!' : '$studentId Dropped!',
            style: TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.bold, 
              color: isBoarding ? AppColors.success : AppColors.primary
            )),
          const SizedBox(height: 8),
          Text('Student has ${isBoarding ? "boarded the bus" : "reached the destination"}. Parent notified.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _scanned = false);
                _ctrl.start();
              },
              child: const Text('Scan Next Student'),
            ),
          ),
        ]),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error));
    setState(() => _scanned = false);
    _ctrl.start();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    
    if (!_scanned && user?.role == UserRole.parent && !_showMyQr) {
      Future.delayed(Duration.zero, () {
        if (mounted) setState(() => _showMyQr = true);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_showMyQr ? 'My Student QR' : 'Bus Attendance'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (user?.role == UserRole.driver)
            IconButton(
              icon: Icon(_showMyQr ? Icons.qr_code_scanner : Icons.qr_code_2),
              onPressed: () => setState(() => _showMyQr = !_showMyQr),
            ),
        ],
      ),
      body: _showMyQr ? _buildMyQr(user?.userId ?? 'Unknown') : _buildScanner(),
    );
  }

  Widget _buildScanner() {
    return Stack(children: [
      MobileScanner(controller: _ctrl, onDetect: _onDetect),
      Center(
        child: Container(
          width: 250, height: 250,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary, width: 3),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      Positioned(
        bottom: 40, left: 0, right: 0,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(14)),
          child: const Text('Scan student ID to update status',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 14)),
        ),
      ),
    ]);
  }

  Widget _buildMyQr(String parentUid) {
    return StreamBuilder(
      stream: FirebaseService.getStudentsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final students = snapshot.data!.docs;
        final studentDoc = students.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['parentUid'] == parentUid;
        }).firstOrNull;

        if (studentDoc == null) {
          return const Center(child: Text('No student linked to this account.'));
        }

        final studentData = studentDoc.data() as Map<String, dynamic>;
        final studentId = studentData['studentId'] ?? 'Unknown';
        final studentName = studentData['name'] ?? 'Student';
        final status = studentData['status'] ?? 'absent';

        return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(studentName,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text('Show this to the driver during boarding',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
            ),
            child: QrImageView(
              data: studentId, 
              version: QrVersions.auto,
              size: 240,
              eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.textPrimary),
              dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(color: AppColors.cardBlue, borderRadius: BorderRadius.circular(12)),
            child: Text('ID: $studentId',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16)),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Status: ', style: TextStyle(fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: status == 'Boarded' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(status,
                  style: TextStyle(
                    color: status == 'Boarded' ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  )),
              ),
            ],
          ),
        ]));
      }
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
}
