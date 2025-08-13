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
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchLostItems();
  }

  Future<void> fetchLostItems() async {
    try {
      final response = await http.get(
        Uri.parse("http://192.168.1.12:5001/lost-items"), //  CHANGE IP
      );
      if (response.statusCode == 200) {
        setState(() {
          lostItems = json.decode(response.body);
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
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : lostItems.isEmpty
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
                  itemCount: lostItems.length,
                  itemBuilder: (context, index) {
                    final item = lostItems[index];
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
      child: Row(
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
    );
  }

  String getIconPath(String category) {
    switch (category.toLowerCase()) {
      case 'wallet':
        return 'assets/icons/wallet_black.png';
      case 'umbrella':
        return 'assets/icons/umbrella_black.png';
      case 'calculator':
        return 'assets/icons/calculator_black.png';
      case 'phone':
        return 'assets/icons/phone_black.png';
      default:
        return 'assets/icons/random_black.png';
    }
  }
}
