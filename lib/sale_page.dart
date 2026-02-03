import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../globals.dart' as globals;

class SalePage extends StatefulWidget {
  final List<Map<String, dynamic>> msMake;
  final List<Map<String, dynamic>> msSize;
  final List<Map<String, dynamic>> msItem;

  const SalePage({
    super.key,
    required this.msMake,
    required this.msSize,
    required this.msItem,
  });

  @override
  State<SalePage> createState() => _SalePageState();
}

class _SalePageState extends State<SalePage> {
  bool isSearching = false;

  late List<Map<String, dynamic>> msMake;
  late List<Map<String, dynamic>> msSize;
  late List<Map<String, dynamic>> msItem;

  List<Map<String, dynamic>> searchResult = [];

  /// qty keyed by index
  Map<int, int> qtyMap = {};

  /// qty text controllers
  Map<int, TextEditingController> qtyCtrlMap = {};

  String? selectedMakeId;
  String? selectedSizeId;
  String? selectedItemId;

  final TextEditingController makeCtrl = TextEditingController();
  final TextEditingController sizeCtrl = TextEditingController();
  final TextEditingController itemCtrl = TextEditingController();

  final String searchApi =
      '${globals.ipAddress}/native_app/sale_search.php?subject=sale&action=search';

  @override
  void initState() {
    super.initState();
    msMake = widget.msMake;
    msSize = widget.msSize;
    msItem = widget.msItem;
  }

  /// 🔹 Auto-suggest
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

  /// 🔹 Search API
  Future<void> _search() async {
    FocusScope.of(context).unfocus();

    setState(() {
      isSearching = true;
      searchResult.clear();
      qtyMap.clear();
      qtyCtrlMap.clear();
    });

    try {
      // ───────────── REQUEST LOG ─────────────
      debugPrint("\n════════════════ STOCK SEARCH REQUEST ════════════════");
      debugPrint("URL : $searchApi");
      debugPrint("PAYLOAD :");
      debugPrint(
        const JsonEncoder.withIndent('  ').convert({
          'make': selectedMakeId ?? '',
          'size': selectedSizeId ?? '',
          'item': selectedItemId ?? '',
        }),
      );
      debugPrint("═══════════════════════════════════════════════════════\n");

      final res = await http.post(
        Uri.parse(searchApi),
        body: {
          'make': selectedMakeId ?? '',
          'size': selectedSizeId ?? '',
          'item': selectedItemId ?? '',
        },
      );

      // ───────────── RAW RESPONSE LOG ─────────────
      debugPrint("\n════════════════ STOCK SEARCH RAW RESPONSE ════════════════");
      debugPrint("STATUS CODE : ${res.statusCode}");
      debugPrint("RAW BODY :");
      debugPrint(res.body);
      debugPrint("══════════════════════════════════════════════════════════\n");

      final data = jsonDecode(res.body);

      // ───────────── PARSED RESPONSE LOG ─────────────
      debugPrint("\n════════════════ STOCK SEARCH PARSED RESPONSE ════════════════");
      debugPrint(const JsonEncoder.withIndent('  ').convert(data));
      debugPrint("════════════════════════════════════════════════════════════\n");

      if (data['status'] == true) {
        setState(() {
          searchResult =
          List<Map<String, dynamic>>.from(data['data'] ?? []);
        });
      }
    } catch (e, stack) {
      debugPrint("\n════════════════ STOCK SEARCH ERROR ════════════════");
      debugPrint("ERROR : $e");
      debugPrint("STACK TRACE :");
      debugPrint(stack.toString());
      debugPrint("═══════════════════════════════════════════════════════\n");
    } finally {
      setState(() => isSearching = false);
    }
  }


  /// 🔹 Result Card
  Widget _buildResultCard(Map<String, dynamic> row, int index) {
    final int maxQty = int.tryParse(row['qty'].toString()) ?? 0;

    qtyMap[index] ??= 0;
    qtyCtrlMap[index] ??= TextEditingController(text: "0");

    void updateQty(int value) {
      if (value < 0) value = 0;
      if (value > maxQty) value = maxQty;
      setState(() {
        qtyMap[index] = value;
        qtyCtrlMap[index]!.text = value.toString();
      });
    }

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



            /// ✅ AVAILABLE STOCK
            Text(
              "Available Stock : $maxQty ${row['uom_name']}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),

            const Divider(),

            /// 🔹 QTY CONTROLLER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Enter Qty",
                    style: TextStyle(fontWeight: FontWeight.w600)),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () =>
                          updateQty((qtyMap[index] ?? 0) - 1),
                    ),

                    /// 🔹 DIRECT INPUT
                    SizedBox(
                      width: 60,
                      child: TextField(
                        controller: qtyCtrlMap[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.all(8),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) {
                          final v = int.tryParse(val) ?? 0;
                          updateQty(v);
                        },
                      ),
                    ),

                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () =>
                          updateQty((qtyMap[index] ?? 0) + 1),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 SAVE SELECTED ITEMS
  void _saveSelected() {
    final List<Map<String, dynamic>> selected = [];

    qtyMap.forEach((index, qty) {
      if (qty > 0) {
        final item = Map<String, dynamic>.from(searchResult[index]);
        item['selected_qty'] = qty;
        selected.add(item);
      }
    });

    Navigator.pop(context, selected);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title:
          const Text("Sale Search", style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF16038b),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
      
        /// 🔹 STICKY SAVE BUTTON
        bottomNavigationBar: qtyMap.values.any((q) => q > 0)
            ? Padding(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text(
              "Save Selected Items",
              style:
              TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
            onPressed: _saveSelected,
          ),
        )
            : null,
      
        body: SingleChildScrollView(
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
                  label:
                  const Text("Search", style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: _search,
                ),
              ),
      
              const SizedBox(height: 20),
              if (isSearching) const CircularProgressIndicator(),
      
              if (!isSearching && searchResult.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: searchResult.length,
                  itemBuilder: (c, i) =>
                      _buildResultCard(searchResult[i], i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
