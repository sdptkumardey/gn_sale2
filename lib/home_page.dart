import 'package:flutter/material.dart';
import 'package:gmpl_tiffin/sale_entry_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  String userName = "";
  late TabController _tabController;

  // 🔹 Sample Data
  final List<Map<String, dynamic>> todaySales = [
    {
      "invoice": "INV-001",
      "party": "ABC Traders",
      "amount": 12500,
    },
    {
      "invoice": "INV-002",
      "party": "XYZ Stores",
      "amount": 8200,
    },
    {
      "invoice": "INV-003",
      "party": "Modern Retail",
      "amount": 15400,
    },
    {
      "invoice": "INV-001",
      "party": "ABC Traders",
      "amount": 12500,
    },
    {
      "invoice": "INV-002",
      "party": "XYZ Stores",
      "amount": 8200,
    },
    {
      "invoice": "INV-003",
      "party": "Modern Retail",
      "amount": 15400,
    },
  ];

  final List<Map<String, dynamic>> warehouseReleases = [
    {
      "ref": "WR-101",
      "item": "Rice Bag",
      "qty": 50,
    },
    {
      "ref": "WR-102",
      "item": "Wheat Flour",
      "qty": 30,
    },
    {
      "ref": "WR-103",
      "item": "Cooking Oil",
      "qty": 20,
    },
    {
      "ref": "WR-101",
      "item": "Rice Bag",
      "qty": 50,
    },
    {
      "ref": "WR-102",
      "item": "Wheat Flour",
      "qty": 30,
    },
    {
      "ref": "WR-103",
      "item": "Cooking Oil",
      "qty": 20,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString("name") ?? "User";
    });
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

  Widget _buildTodaySaleList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: todaySales.length,
      itemBuilder: (context, index) {
        final item = todaySales[index];
        return Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: const Icon(Icons.receipt_long, color: Colors.blue),
            title: Text(
              item['party'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text("Invoice: ${item['invoice']}"),
            trailing: Text(
              "₹${item['amount']}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWarehouseReleaseList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: warehouseReleases.length,
      itemBuilder: (context, index) {
        final item = warehouseReleases[index];
        return Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: const Icon(Icons.inventory, color: Colors.deepPurple),
            title: Text(
              item['item'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text("Release Ref: ${item['ref']}"),
            trailing: Text(
              "Qty: ${item['qty']}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ),
        );
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
          elevation: 0,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  _buildActionButton(
                    icon: Icons.point_of_sale,
                    label: "Sale",
                    colors: [Colors.orange, Colors.deepOrange],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SaleEntryPage()),
                      );
                    },
                  ),

                  _buildActionButton(
                    icon: Icons.bar_chart_rounded,
                    label: "Sale Report",
                    colors: [Colors.indigo, Colors.blue],
                    onTap: () {},
                  ),
                  _buildActionButton(
                    icon: Icons.inventory_2_rounded,
                    label: "Check Stock",
                    colors: [Colors.green, Colors.teal],
                    onTap: () {},
                  ),
                ],
              ),
            ),
            Container(
              color: const Color(0xFF16038b),
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.orangeAccent,
                indicatorWeight: 4,
                tabs: const [
                  Tab(icon: Icon(Icons.today), text: "Today's Sale"),
                  Tab(icon: Icon(Icons.warehouse), text: "Warehouse Release"),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTodaySaleList(),
                  _buildWarehouseReleaseList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
