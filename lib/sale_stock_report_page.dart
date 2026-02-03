import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../globals.dart' as globals;

class SaleStockReportPage extends StatefulWidget {
  const SaleStockReportPage({super.key});

  @override
  State<SaleStockReportPage> createState() => _SaleStockReportPageState();
}

class _SaleStockReportPageState extends State<SaleStockReportPage> {
  bool isMasterLoading = true;
  bool isSearching = false;

  List<Map<String, dynamic>> msMake = [];
  List<Map<String, dynamic>> msSize = [];
  List<Map<String, dynamic>> msItem = [];

  List<Map<String, dynamic>> searchResult = [];

  String? selectedMakeId;
  String? selectedSizeId;
  String? selectedItemId;

  final TextEditingController makeCtrl = TextEditingController();
  final TextEditingController sizeCtrl = TextEditingController();
  final TextEditingController itemCtrl = TextEditingController();

  final String masterApi =
      '${globals.ipAddress}/native_app/sale_master_value.php?subject=sale&action=master';

  final String searchApi =
      '${globals.ipAddress}/native_app/salepoint_stock_search.php?subject=sale&action=search';

  @override
  void initState() {
    super.initState();
    _loadMasterData();
  }

  // ───────────────────────── LOAD MASTER ─────────────────────────
  Future<void> _loadMasterData() async {
    try {
      final res = await http.get(Uri.parse(masterApi));
      final data = jsonDecode(res.body);

      if (data['status'] == true) {
        msMake = List<Map<String, dynamic>>.from(data['ms_make'] ?? []);
        msSize = List<Map<String, dynamic>>.from(data['ms_size'] ?? []);
        msItem = List<Map<String, dynamic>>.from(data['ms_item'] ?? []);
      }
    } catch (e) {
      debugPrint("MASTER LOAD ERROR: $e");
    }

    setState(() => isMasterLoading = false);
  }

  // ───────────────────────── AUTO SUGGEST ─────────────────────────
  Widget _buildAutoSuggest({
    required String label,
    required TextEditingController controller,
    required List<Map<String, dynamic>> data,
    required Function(String id) onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Autocomplete<Map<String, dynamic>>(
          optionsBuilder: (value) {
            if (value.text.isEmpty) return const Iterable.empty();
            return data.where((item) => item['name']
                .toString()
                .toLowerCase()
                .contains(value.text.toLowerCase()));
          },
          displayStringForOption: (o) => o['name'].toString(),
          onSelected: (o) {
            controller.text = o['name'].toString();
            onSelected(o['id'].toString());
            FocusScope.of(context).unfocus();
          },
          fieldViewBuilder:
              (context, textController, focusNode, onFieldSubmitted) {
            textController.text = controller.text;
            return TextField(
              controller: textController,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: "Type to search",
                suffixIcon: const Icon(Icons.search),
                border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          },
        ),
      ],
    );
  }

  // ───────────────────────── SEARCH API ─────────────────────────
  Future<void> _search() async {
    FocusScope.of(context).unfocus();

    setState(() {
      isSearching = true;
      searchResult.clear();
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? '';
      final mob = prefs.getString('mob') ?? '';

      // 🔹 LOG STORED USER DATA
      debugPrint("===== STORED USER DATA =====");
      debugPrint("user_id: $userId");
      debugPrint("mob    : $mob");

      if (userId.isEmpty || mob.isEmpty) {
        debugPrint("❌ USER NOT LOGGED IN");
        setState(() => isSearching = false);
        return;
      }

      // 🔹 BUILD PAYLOAD
      final payload = {
        'user_id': userId,
        'mob': mob,
        'make': selectedMakeId ?? '',
        'size': selectedSizeId ?? '',
        'item': selectedItemId ?? '',
      };

      // 🔹 PRINT PAYLOAD
      debugPrint("===== STOCK SEARCH REQUEST PAYLOAD =====");
      debugPrint(const JsonEncoder.withIndent('  ').convert(payload));

      final res = await http.post(
        Uri.parse(searchApi),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      // 🔹 PRINT RAW RESPONSE
      debugPrint("===== STOCK SEARCH RAW RESPONSE =====");
      debugPrint("STATUS CODE: ${res.statusCode}");
      debugPrint("BODY:");
      debugPrint(res.body);

      final data = jsonDecode(res.body);

      // 🔹 PRINT PARSED RESPONSE
      debugPrint("===== STOCK SEARCH PARSED RESPONSE =====");
      debugPrint(const JsonEncoder.withIndent('  ').convert(data));

      if (data['status'] == true) {
        searchResult =
        List<Map<String, dynamic>>.from(data['data'] ?? []);
      }
    } catch (e, stack) {
      debugPrint("===== STOCK SEARCH ERROR =====");
      debugPrint(e.toString());
      debugPrint(stack.toString());
    }

    setState(() => isSearching = false);
  }



  // ───────────────────────── RESULT CARD ─────────────────────────
  Widget _buildResultCard(Map<String, dynamic> row) {
    final int availableQty = int.tryParse(row['qty'].toString()) ?? 0;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${row['make_name']} | ${row['size_name']} | ${row['item_name']}",
              style:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text("Batch : ${row['batch_num']}"),
            Text("Warehouse : ${row['warehouse_name']}"),
            const SizedBox(height: 6),
            if ((row['transit'] ?? 0) > 0)
              Text(
                "On Transit : ${row['transit']} ${row['uom_name']}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            Text(
              "Available Stock : $availableQty ${row['uom_name']}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────── UI ─────────────────────────
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Warehouse Stock Report",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF16038b),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: isMasterLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildAutoSuggest(
                label: "Search By Make",
                controller: makeCtrl,
                data: msMake,
                onSelected: (id) => selectedMakeId = id,
              ),
              const SizedBox(height: 16),
              _buildAutoSuggest(
                label: "Search By Size",
                controller: sizeCtrl,
                data: msSize,
                onSelected: (id) => selectedSizeId = id,
              ),
              const SizedBox(height: 16),
              _buildAutoSuggest(
                label: "Search By Item",
                controller: itemCtrl,
                data: msItem,
                onSelected: (id) => selectedItemId = id,
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.search),
                  label: const Text("Search",
                      style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: _search,
                ),
              ),

              const SizedBox(height: 20),

              if (isSearching)
                const CircularProgressIndicator(),

              if (!isSearching && searchResult.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: searchResult.length,
                  itemBuilder: (c, i) =>
                      _buildResultCard(searchResult[i]),
                ),

              if (!isSearching && searchResult.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Text(
                    "No records found",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
