import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'login_screen.dart';
import 'sale_entry_page.dart';
import 'sale_report_page.dart';
import 'sale_stock_report_page.dart';
import '../globals.dart' as globals;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  String userName = "";
  late TabController _tabController;

  bool isLoading = false;

  List<Map<String, dynamic>> msSale = [];
  List<Map<String, dynamic>> msDispatch = [];

  final Set<String> selectedIds = {};

  final String apiUrl =
      '${globals.ipAddress}/native_app/sale_today_show.php?subject=warehouse&action=view';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUser();
    _fetchTodayData();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString("name") ?? "User";
    });
  }

  Future<void> _fetchTodayData() async {
    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? '';
      final mob = prefs.getString('mob') ?? '';

      if (userId.isEmpty || mob.isEmpty) {
        setState(() => isLoading = false);
        return;
      }

      final res = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'mob': mob,
        }),
      );

      final data = jsonDecode(res.body);

      if (data['status'] == true) {
        setState(() {
          msSale =
          List<Map<String, dynamic>>.from(data['ms_sale'] ?? []);
          msDispatch =
          List<Map<String, dynamic>>.from(data['ms_dispatch'] ?? []);
        });
      }
    } catch (e) {
      debugPrint("HOME FETCH ERROR: $e");
    }

    setState(() => isLoading = false);
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  // ───────────────────── CARD UI ─────────────────────
  Widget _buildWarehouseCard(Map<String, dynamic> row, int index) {
    final id = row['id'].toString();
    final isSelected = selectedIds.contains(id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.green.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? Colors.green : Colors.grey.shade300,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ITEM + QTY
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    "${index + 1}. ${row['make_name']} ${row['size_name']} "
                        "${row['item_name']}  Batch: ${row['batch_num']}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "${row['qty']} ${row['uom_name']}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
              ],
            ),

            const Divider(height: 18),

            Text(
              "Sold On: ${row['voucher_date']}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            // 🔹 DISPATCH STATUS
            if ((row['status'] ?? '') == 'DISPATCHED' &&
                (row['warehouse_on'] ?? '').toString().isNotEmpty)
              Text(
                "Dispatched On: ${row['warehouse_on']}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),

            if ((row['status'] ?? '') == 'PENDING')
              Text(
                row['status'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),




            if ((row['inv_no'] ?? '').toString().isNotEmpty)
              Text("Ref No. ${row['inv_no']}"),

            if ((row['party_name'] ?? '').toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  "${row['party_name']} [ ${row['party_contact']} ]",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),

            if ((row['party_address'] ?? '').toString().isNotEmpty)
              Text(row['party_address']),

            const SizedBox(height: 6),

            Text(
              "Sale By ${row['sale_by_name']}",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> data) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (data.isEmpty) {
      return const Center(child: Text("No data found"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: data.length,
      itemBuilder: (context, index) {
        return _buildWarehouseCard(data[index], index);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "Welcome, $userName",
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF16038b),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: _logout,
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildActionButton(
                    icon: Icons.point_of_sale,
                    label: "Sale",
                    colors: [Colors.orange, Colors.deepOrange],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SaleEntryPage()),
                      );
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.bar_chart_rounded,
                    label: "Sale Report",
                    colors: [Colors.indigo, Colors.blue],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SaleReportPage()),
                      );
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.inventory_2_rounded,
                    label: "Check Stock",
                    colors: [Colors.green, Colors.teal],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SaleStockReportPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
            Container(
              color: const Color(0xFF16038b),
              child: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,   // indicator also white
                labelColor: Colors.white,       // selected tab text & icon
                unselectedLabelColor: Colors.white, // unselected tab text & icon
                tabs: const [
                  Tab(
                    icon: Icon(Icons.today),
                    text: "Today's Sale",
                  ),
                  Tab(
                    icon: Icon(Icons.warehouse),
                    text: "Warehouse Release",
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildList(msSale),
                  _buildList(msDispatch),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 90,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.last.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 20),
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white70),
            const SizedBox(width: 20),
          ],
        ),
      ),
    );
  }
}
