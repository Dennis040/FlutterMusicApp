import 'package:flutter/material.dart';
import 'package:flutter_music_app/screens/home_screen.dart';
import 'package:flutter_zalopay_sdk/flutter_zalopay_sdk.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/config.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  int _selectedPlan = 0;

  final List<Map<String, dynamic>> _plans = [
    {'name': '1 tháng', 'price': 59000},
    {'name': '3 tháng', 'price': 159000},
    {'name': '12 tháng', 'price': 499000},
  ];

  @override
  void initState() {
    super.initState();
  }

 Future<void> _handleZaloPayPayment() async {
  final plan = _plans[_selectedPlan];

  try {
    // Gọi API backend để lấy zp_trans_token
    final response = await http.post(
      Uri.parse('${ip}ZaloPay/payment'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "amount": plan['price'],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Lỗi server: ${response.statusCode}");
    }

    final data = json.decode(response.body);
    final zpToken = data['zp_trans_token']; // ← kiểm tra đúng key mà backend trả

    if (zpToken == null) {
      throw Exception("Không nhận được zpToken từ server.");
    }

    final result = await FlutterZaloPaySdk.payOrder(zpToken: zpToken);

    String message;
    switch (result) {
      case FlutterZaloPayStatus.success:
        message = "Thanh toán thành công!";
        if (!mounted) return;

        // ✅ Điều hướng về màn hình chính (hoặc màn bạn muốn)
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()), // hoặc DashboardPage()
          (route) => false,
        );
        break;

      case FlutterZaloPayStatus.cancelled:
        message = "Bạn đã huỷ thanh toán.";
        Navigator.pop(context);
        break;

      case FlutterZaloPayStatus.failed:
      default:
        message = "Thanh toán thất bại!";
        Navigator.pop(context);
        break;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Lỗi khi gọi thanh toán: $e")),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text("Chọn gói Premium"),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          ...List.generate(_plans.length, (index) {
            final plan = _plans[index];
            return ListTile(
              title: Text(
                plan['name'],
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              subtitle: Text(
                '${plan['price']} VNĐ',
                style: const TextStyle(color: Colors.grey),
              ),
              trailing: Radio<int>(
                value: index,
                groupValue: _selectedPlan,
                onChanged: (value) {
                  setState(() {
                    _selectedPlan = value!;
                  });
                },
              ),
            );
          }),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _handleZaloPayPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent[400],
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              icon: const Icon(Icons.payment, color: Colors.black),
              label: const Text(
                "Đăng ký & Thanh toán",
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
            ),
          )
        ],
      ),
    );
  }
}
