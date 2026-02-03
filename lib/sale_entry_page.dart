import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'sale_page.dart';
import '../globals.dart' as globals;

class SaleEntryPage extends StatefulWidget {
  const SaleEntryPage({super.key});

  @override
  State<SaleEntryPage> createState() => _SaleEntryPageState();
}

class _SaleEntryPageState extends State<SaleEntryPage> {
  bool isLoading = true;
  bool isSaving = false;
  List<Map<String, dynamic>> msMake = [];
  List<Map<String, dynamic>> msSize = [];
  List<Map<String, dynamic>> msItem = [];

  /// 🔹 products returned from SalePage
  List<Map<String, dynamic>> addedProducts = [];

  /// 🔹 qty text controllers (key = index)
  final Map<int, TextEditingController> qtyCtrlMap = {};

  final TextEditingController partyNameCtrl = TextEditingController();
  final TextEditingController partyContactCtrl = TextEditingController();
  final TextEditingController partyAddressCtrl = TextEditingController();
  final TextEditingController invCtrl = TextEditingController();
  final TextEditingController narrationCtrl = TextEditingController();

  final String masterApi =
      '${globals.ipAddress}/native_app/sale_master_value.php?subject=sale&action=master';

  @override
  void initState() {
    super.initState();
    _loadMasterData();
  }


  @override
  void dispose() {
    partyNameCtrl.dispose();
    partyContactCtrl.dispose();
    partyAddressCtrl.dispose();
    narrationCtrl.dispose();
    invCtrl.dispose();

    for (final c in qtyCtrlMap.values) {
      c.dispose();
    }

    super.dispose();
  }


  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// ✅ Animated Icon
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 600),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: child,
                    );
                  },
                  child: const CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.green,
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                /// ✅ Title
                const Text(
                  "Sale Saved Successfully!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),

                const SizedBox(height: 10),

                /// ✅ Subtitle
                const Text(
                  "Your sale entry has been saved.\nYou will be redirected to Home.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),

                const SizedBox(height: 25),

                /// ✅ OK BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      "OK",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context); // close dialog

                      /// 🔁 Redirect to Home
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }



  Future<void> _loadMasterData() async {
    try {
      final res = await http.get(Uri.parse(masterApi));
      final data = jsonDecode(res.body);
      if (data['status'] == true) {
        setState(() {
          msMake = List<Map<String, dynamic>>.from(data['ms_make']);
          msSize = List<Map<String, dynamic>>.from(data['ms_size']);
          msItem = List<Map<String, dynamic>>.from(data['ms_item']);
          isLoading = false;
        });
      }
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  /// 🔹 OPEN SEARCH PAGE
  Future<void> _openSearch() async {
    final List<Map<String, dynamic>>? result =
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SalePage(
          msMake: msMake,
          msSize: msSize,
          msItem: msItem,
        ),
      ),
    );

    if (result != null) {

      debugPrint("===== RETURNED FROM SalePage =====");
      debugPrint(jsonEncode(result)); // full structure


      setState(() {
        for (var item in result) {
          addedProducts.add(item);
          qtyCtrlMap[addedProducts.length - 1] =
              TextEditingController(
                  text: item['selected_qty'].toString());
        }
      });
    }
  }

  Future<void> _saveSale() async {




    if (partyNameCtrl.text.isEmpty ||
        partyContactCtrl.text.isEmpty ||
        addedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill required fields")),
      );
      return;
    }
    setState(() {
      isSaving = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? '';
      final mob = prefs.getString('mob') ?? '';

      if (userId.isEmpty || mob.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not logged in")),
        );
        setState(() {
          isSaving = false;
        });
        return;
      }

      final payload = {
        "user_id": userId,
        "mob": mob,
        "type": "add",
        "party_name": partyNameCtrl.text.trim(),
        "party_contact": partyContactCtrl.text.trim(),
        "party_address": partyAddressCtrl.text.trim(),
        "inv_no": invCtrl.text.trim(),
        "narration": narrationCtrl.text.trim(),
        "arr": addedProducts,
      };

      debugPrint("===== SALE SAVE PAYLOAD =====");
      debugPrint(jsonEncode(payload));

      final response = await http.post(
        Uri.parse(
          '${globals.ipAddress}/native_app/sale_save.php?subject=sale&action=save',
        ),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(payload),
      );

      // ✅ PRINT RAW SERVER RESPONSE
      debugPrint("===== SALE SAVE RAW RESPONSE =====");
      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Body:");
      debugPrint(response.body);

      // ✅ TRY TO DECODE JSON
      final resData = jsonDecode(response.body);

      debugPrint("===== SALE SAVE PARSED RESPONSE =====");
      debugPrint(resData.toString());

      if (resData['status'] == true) {
        setState(() {
          isSaving = false;
        });
        _showSuccessDialog();
      } else {
        setState(() {
          isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resData['message'] ?? "Save failed"),
          ),
        );
      }
    } catch (e, stack) {
      setState(() {
        isSaving = false;
      });
      debugPrint("===== SALE SAVE ERROR =====");
      debugPrint(e.toString());
      debugPrint(stack.toString());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }



  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xFFF5F7FF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  /// 🔹 UPDATE QTY WITH LIMIT
  void _updateQty(int index, int value) {
    final int maxQty =
        int.tryParse(addedProducts[index]['qty'].toString()) ?? 0;

    if (value < 0) value = 0;
    if (value > maxQty) value = maxQty;

    setState(() {
      addedProducts[index]['selected_qty'] = value;
      qtyCtrlMap[index]!.text = value.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return SafeArea(
      child: Stack(
        children: [

          Scaffold(
            appBar: AppBar(
              title: const Text("Sale Entry"),
              backgroundColor: const Color(0xFF16038B),
              foregroundColor: Colors.white,
              elevation: 6,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// 🔹 SEARCH & ADD PRODUCT
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.search),
                      label: const Text(
                        "Search and Add Product",
                        style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ),
                      onPressed: _openSearch,
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// 🔹 ADDED PRODUCTS
                  if (addedProducts.isNotEmpty) ...[
                    const Text(
                      "Added Products",
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                  ],

                  ...addedProducts.asMap().entries.map((e) {
                    final index = e.key;
                    final row = e.value;

                    qtyCtrlMap[index] ??=
                        TextEditingController(
                            text: row['selected_qty'].toString());

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.inventory,
                                  color: Colors.deepPurple),
                              title: Text(
                                row['item_name'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    addedProducts.removeAt(index);
                                    qtyCtrlMap.remove(index);
                                  });
                                },
                              ),
                            ),

                            Text(
                              "Batch: ${row['batch_num']} | ${row['warehouse_name']}",
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Available Stock: ${row['qty']} ${row['uom_name']}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green),
                            ),

                            const Divider(),

                            /// 🔹 QTY CONTROLLER
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Enter Qty",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                          Icons.remove_circle_outline),
                                      onPressed: () => _updateQty(
                                          index,
                                          row['selected_qty'] - 1),
                                    ),
                                    SizedBox(
                                      width: 60,
                                      child: TextField(
                                        controller: qtyCtrlMap[index],
                                        keyboardType:
                                        TextInputType.number,
                                        textAlign: TextAlign.center,
                                        decoration:
                                        const InputDecoration(
                                          isDense: true,
                                          border: OutlineInputBorder(),
                                        ),
                                        onChanged: (v) => _updateQty(
                                            index,
                                            int.tryParse(v) ?? 0),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                          Icons.add_circle_outline),
                                      onPressed: () => _updateQty(
                                          index,
                                          row['selected_qty'] + 1),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 30),

                  /// 🔹 PARTY DETAILS
                  Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            "Party Details",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),

                          TextField(
                            controller: partyNameCtrl,
                            decoration: _inputDecoration(
                                "Party Name *", Icons.person),
                          ),
                          const SizedBox(height: 12),

                          TextField(
                            controller: partyContactCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: _inputDecoration(
                                "Party Contact *", Icons.call),
                          ),
                          const SizedBox(height: 12),

                          TextField(
                            controller: partyAddressCtrl,
                            decoration: _inputDecoration(
                                "Party Address", Icons.location_on),
                          ),
                          const SizedBox(height: 12),


                          TextField(
                            controller: invCtrl,
                            decoration: _inputDecoration(
                                "Ref. Inv. / Challan No.", Icons.sd_card_alert),
                          ),
                          const SizedBox(height: 12),

                          TextField(
                            controller: narrationCtrl,
                            maxLines: 3,
                            decoration:
                            _inputDecoration("Narration", Icons.notes),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// 🔹 SAVE BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text(
                        "Save Sale",
                        style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ),
                      onPressed: isSaving ? null : _saveSale,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isSaving)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
