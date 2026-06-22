import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  // Mock invoice data
  final List<Map<String, dynamic>> _invoices = [
    {
      'id': 'inv-1',
      'invoiceNumber': 'INV-20260618-0021',
      'doctorName': 'PGS.TS.BS Nguyễn Văn An',
      'specializationName': 'Nội khoa',
      'clinicName': 'Phòng khám Đa khoa Sài Gòn',
      'patientName': 'Nguyễn Văn A',
      'subtotal': 250000.0,
      'tax': 0.0,
      'discount': 0.0,
      'total': 250000.0,
      'status': 'UNPAID', // UNPAID, PAID
      'createdDate': '2026-06-18',
    },
    {
      'id': 'inv-2',
      'invoiceNumber': 'INV-20260510-0004',
      'doctorName': 'BSCKII Lê Hoàng Nam',
      'specializationName': 'Da liễu',
      'clinicName': 'Phòng khám Đa khoa Sài Gòn',
      'patientName': 'Nguyễn Văn A',
      'subtotal': 200000.0,
      'tax': 0.0,
      'discount': 50000.0,
      'total': 150000.0,
      'status': 'PAID',
      'createdDate': '2026-05-10',
    }
  ];

  void _payInvoice(int index) {
    final invoice = _invoices[index];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _buildPaymentSheet(invoice, () {
          setState(() {
            _invoices[index]['status'] = 'PAID';
          });
          Navigator.pop(context); // Close bottom sheet
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Thanh toán thành công hóa đơn ${invoice['invoiceNumber']}!'),
              backgroundColor: AppColors.success,
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Thanh Toán Viện Phí'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _invoices.length,
        itemBuilder: (context, index) {
          final inv = _invoices[index];
          final bool isUnpaid = inv['status'] == 'UNPAID';

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        inv['invoiceNumber'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textLight),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isUnpaid
                              ? AppColors.danger.withOpacity(0.1)
                              : AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isUnpaid ? 'Chưa thanh toán' : 'Đã thanh toán',
                          style: TextStyle(
                            color: isUnpaid ? AppColors.danger : AppColors.success,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Text(
                    inv['doctorName'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                  ),
                  Text(
                    'Khoa: ${inv['specializationName']} - ${inv['clinicName']}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Bệnh nhân:', style: TextStyle(fontSize: 13, color: AppColors.textLight)),
                      Text(inv['patientName'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Ngày phát hành:', style: TextStyle(fontSize: 13, color: AppColors.textLight)),
                      Text(inv['createdDate'] ?? '', style: const TextStyle(fontSize: 13, color: AppColors.textDark)),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng tiền viện phí:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                      Text(
                        currencyFormat.format(inv['total']),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                      ),
                    ],
                  ),
                  if (isUnpaid) ...[
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _payInvoice(index),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: const Text('Thanh Toán Ngay', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ]
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaymentSheet(Map<String, dynamic> invoice, VoidCallback onConfirm) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Thanh toán điện tử',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              currencyFormat.format(invoice['total']),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ),
          Center(
            child: Text(
              invoice['invoiceNumber'],
              style: const TextStyle(fontSize: 12, color: AppColors.textLight),
            ),
          ),
          const SizedBox(height: 24),
          
          // QR Code simulation
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Fake QR Code graphic using layout widgets
                  Image.network(
                    'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=https://github.com/google/deepmind',
                    width: 180,
                    height: 180,
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                    ),
                    child: const Icon(Icons.local_hospital, color: AppColors.primary, size: 24),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Quét mã QR bằng ứng dụng ngân hàng hoặc ví MoMo/VNPAY\nđể hoàn tất thanh toán.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textLight),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Xác nhận Đã Chuyển Khoản', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
