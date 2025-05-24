import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: OrderScreen(),
    );
  }
}

class OrderScreen extends StatelessWidget {
  const OrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {},
        ),
        title: Text('Xác nhận đơn hàng'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Khách đã chọn món nay cứ thêm',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: Image.network(
                  'https://via.placeholder.com/50', // Placeholder image
                  width: 50,
                  height: 50,
                ),
                title: Text('COMBO VIÊN CHIÊN - FLASH SALE 1đ'),
                subtitle: Text('9.000đ 10.000đ'),
                trailing: IconButton(
                  icon: Icon(Icons.add, color: Colors.red),
                  onPressed: () {},
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Chi tiết thanh toán',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tổng giá món (2 món)'),
                        Text('79.000đ'),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Phí giao hàng (0.8 km)'),
                        Text('16.000đ'),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Phí áp dụng (?)'),
                        Text('6.000đ'),
                      ],
                    ),
                    Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tổng thanh toán', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('101.000đ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                      ],
                    ),
                    Text('Đã bao gồm thuế', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton(
                  onPressed: () {},
                  child: Text('Thêm voucher'),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text('Chọn voucher >'),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.local_taxi),
                SizedBox(width: 10),
                Text('Thường cho Tài xế'),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: Text('Chưa...'),
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: Text('5K'),
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: Text('10K'),
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: Text('15K'),
                ),
                OutlinedButton(
                  onPressed: () {},
                  child: Text('Khác'),
                ),
              ],
            ),
            SizedBox(height: 10),
            Card(
              child: ListTile(
                title: Text('ShopeePay · MB 300 Xu'),
                trailing: Text('Tiến mát'),
              ),
            ),
            Spacer(),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text('Đặt đơn - 101.000đ'),
            ),
          ],
        ),
      ),
    );
  }
}