import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LostPage extends StatefulWidget {
  const LostPage({super.key});

  @override
  State<LostPage> createState() => _LostPageState();
}

class _LostPageState extends State<LostPage> {
  List<dynamic> lostItems = [];
  List<dynamic> filteredItems = [];
  bool isLoading = true;

  final List<String> categories = [
    'All',
    'Wallet',
    'Umbrella',
    'Calculator',
    'Phone',
    'Random',
  ];

  String selectedCategory = "All";

  @override
  void initState() {
    super.initState();
    fetchLostItems();
  }

  Future<void> fetchLostItems() async {
    try {
      final response = await http.get(
        Uri.parse("https://throneless-ebony-billety.ngrok-free.dev/lost-items"),
      );
      if (response.statusCode == 200) {
        final items = json.decode(response.body);
        setState(() {
          lostItems = List.from(items.reversed);
          applyFilter();
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load lost items");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error: $e");
    }
  }

  void applyFilter() {
    setState(() {
      if (selectedCategory == "All") {
        filteredItems = lostItems;
      } else {
        filteredItems =
            lostItems
                .where(
                  (item) =>
                      item['category'].toString().toLowerCase() ==
                      selectedCategory.toLowerCase(),
                )
                .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(240, 86, 38, 1),
        title: Row(
          children: [
            Image.asset('assets/images/logo_white.png', height: 20, width: 20),
            const SizedBox(width: 8),
            const Text(
              'Lost Items',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            constraints: const BoxConstraints(minHeight: 30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Color.fromRGBO(240, 86, 38, 1),
                width: 1.5,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedCategory,
                icon: const Icon(
                  Icons.filter_list,
                  size: 18,
                  color: Color.fromRGBO(240, 86, 38, 1),
                ),
                dropdownColor: Colors.white,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color.fromRGBO(240, 86, 38, 1),
                  fontWeight: FontWeight.bold,
                ),
                items:
                    categories.map((cat) {
                      return DropdownMenuItem(value: cat, child: Text(cat));
                    }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedCategory = value;
                    applyFilter();
                  }
                },
              ),
            ),
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredItems.isEmpty
              ? RefreshIndicator(
                onRefresh: fetchLostItems,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 200),
                    Center(
                      child: Text(
                        'No Lost Items Yet, check back again later',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: fetchLostItems,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    return itemCard(
                      getIconPath(item['category']),
                      item['tcc_number'],
                      item['category'],
                      item['description'],
                    );
                  },
                ),
              ),
    );
  }

  Widget itemCard(
    String iconPath,
    String tccNumber,
    String category,
    String description,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2, 2)),
        ],
      ),
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  iconPath,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      "Category: $category",
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      tccNumber,
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Lost',
                style: TextStyle(
                  color: Color.fromRGBO(220, 38, 38, 1),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String getIconPath(String category) {
    switch (category.toLowerCase()) {
      case 'wallet':
        return 'assets/icons/wallet_orange.png';
      case 'umbrella':
        return 'assets/icons/umbrella_orange.png';
      case 'calculator':
        return 'assets/icons/calculator_orange.png';
      case 'phone':
        return 'assets/icons/phone_orange.png';
      default:
        return 'assets/icons/random_orange.png';
    }
  }
}
