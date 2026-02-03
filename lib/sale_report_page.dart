import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'globals.dart' as globals;

class SaleReportPage extends StatefulWidget {
  const SaleReportPage({super.key});

  @override
  State<SaleReportPage> createState() => _SaleReportPageState();
}

class _SaleReportPageState extends State<SaleReportPage> {
  final String apiUrl =
      '${globals.ipAddress}/native_app/salepoint_sale_report.php?subject=warehouse&action=view';

  bool isLoading = false;

  DateTime fromDate = DateTime.now().subtract(const Duration(days: 5));
  DateTime toDate = DateTime.now();

  List<Map<String, dynamic>> allData = [];
  List<Map<String, dynamic>> filteredData = [];

  String statusFilter = "ALL";

  final TextEditingController searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  // ───────────────────────── DATE PICKER ─────────────────────────
  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? fromDate : toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        isFrom ? fromDate = picked : toDate = picked;
      });
    }
  }

  // API DATE FORMAT → yyyy-MM-dd
  String _formatDate(DateTime d) {
    return "${d.year}-"
        "${d.month.toString().padLeft(2, '0')}-"
        "${d.day.toString().padLeft(2, '0')}";
  }

  // DISPLAY DATE FORMAT → dd/MM/yyyy
  String _formatDateDisplay(DateTime d) {
    return "${d.day.toString().padLeft(2, '0')}/"
        "${d.month.toString().padLeft(2, '0')}/"
        "${d.year}";
  }

  // ───────────────────────── API CALL ─────────────────────────
  Future<void> _fetchReport() async {
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
          'from_date': _formatDate(fromDate),
          'to_date': _formatDate(toDate),
        }),
      );

      final data = jsonDecode(res.body);

      if (data['status'] == true && data['ms_data'] != null) {
        setState(() {
          allData = List<Map<String, dynamic>>.from(data['ms_data']);
          _applyFilters();
          isLoading = false;
        });
      } else {
        setState(() {
          allData.clear();
          filteredData.clear();
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // ───────────────────────── FILTER + SEARCH ─────────────────────────
  void _applyFilters() {
    final q = searchCtrl.text.toLowerCase();

    filteredData = allData.where((row) {
      final matchSearch = row.values.any(
            (v) => v.toString().toLowerCase().contains(q),
      );

      final matchStatus = statusFilter == "ALL"
          ? true
          : row['status'].toString().toUpperCase() == statusFilter;

      return matchSearch && matchStatus;
    }).toList();
  }

  void _onSearch(String value) {
    setState(() => _applyFilters());
  }

  // ───────────────────────── STATUS BADGE ─────────────────────────
  Widget _statusBadge(String status) {
    Color bg;
    switch (status.toUpperCase()) {
      case "DISPATCHED":
        bg = Colors.green;
        break;
      case "PENDING":
        bg = Colors.orange;
        break;
      default:
        bg = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ───────────────────────── CARD UI ─────────────────────────
  Widget _buildSaleCard(Map<String, dynamic> row, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${row['qty']} ${row['uom_name']}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _statusBadge(row['status']),
                  ],
                ),
              ],
            ),

            const Divider(height: 18),

            Text(
              "Sold On : ${row['voucher_date']}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            if(row['status']=='DISPATCHED')Text(
              "Dispatched On : ${row['warehouse_on']}",
              style: const TextStyle(fontWeight: FontWeight.bold),
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

  // ───────────────────────── UI ─────────────────────────
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Sale Report with Status"),
        ),
        body: Column(
          children: [
            // DATE PICKERS
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.date_range),
                      onPressed: () => _pickDate(true),
                      label: Text("From Date: ${_formatDate(fromDate)}"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.date_range),
                      onPressed: () => _pickDate(false),
                      label: Text("To Date: ${_formatDate(toDate)}"),
                    ),
                  ),
                ],
              ),
            ),

            // SUBMIT BUTTON
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.filter_alt, color: Colors.white),
                  label: const Text(
                    "Submit / Filter",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.indigo,
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: _fetchReport,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // SEARCH + STATUS FILTER
            if (allData.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: searchCtrl,
                        onChanged: _onSearch,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: "Search...",
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: statusFilter,
                      items: const [
                        DropdownMenuItem(value: "ALL", child: Text("ALL")),
                        DropdownMenuItem(
                            value: "DISPATCHED",
                            child: Text("DISPATCHED")),
                        DropdownMenuItem(
                            value: "PENDING", child: Text("PENDING")),
                      ],
                      onChanged: (v) {
                        setState(() {
                          statusFilter = v!;
                          _applyFilters();
                        });
                      },
                    ),
                  ],
                ),
              ),

            // DATE RANGE + COUNT
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Showing results from ${_formatDateDisplay(fromDate)} to ${_formatDateDisplay(toDate)}",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.indigo,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "${filteredData.length}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // LIST
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredData.isEmpty
                  ? const Center(child: Text("No records found"))
                  : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: filteredData.length,
                itemBuilder: (context, index) {
                  return _buildSaleCard(
                      filteredData[index], index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
