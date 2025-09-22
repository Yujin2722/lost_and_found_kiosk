import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ClaimedPage extends StatefulWidget {
  const ClaimedPage({super.key});

  @override
  State<ClaimedPage> createState() => _ClaimedPageState();
}

class _ClaimedPageState extends State<ClaimedPage> {
  List<dynamic> claims = [];
  List<dynamic> filteredClaims = [];
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
    fetchClaims();
  }

  Future<void> fetchClaims() async {
    try {
      final response = await http.get(
        Uri.parse(
          "https://60c4fd2e22e0.ngrok-free.app/claims",
        ), 
      );
      if (response.statusCode == 200) {
        final items = json.decode(response.body);
        setState(() {
          claims = items;
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load claims");
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
        filteredClaims = claims;
      } else {
        filteredClaims = claims
            .where((item) =>
                (item['found_item']?['category'] ?? '')
                    .toString()
                    .toLowerCase() ==
                selectedCategory.toLowerCase())
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
              'Claimed Items',
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
              : claims.isEmpty
              ? RefreshIndicator(
                onRefresh: fetchClaims,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 200),
                    Center(
                      child: Text(
                        'No Claimed Items Yet',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: fetchClaims,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: claims.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return const Padding(
                        padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                        child: Text(
                          'Claim History',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }
                    final claim = claims[index - 1];
                    return claimCard(
                      claim['tcc'],
                      claim['images'],
                      claim['timestamp'],
                      foundItem: claim['found_item'],
                    );
                  },
                ),
              ),
    );
  }

  Widget claimCard(
    String tcc,
    List<dynamic> images,
    String timestamp, {
    Map<String, dynamic>? foundItem,
  }) {
    final category = foundItem?['category'] ?? 'Unknown';
    final description = foundItem?['description'] ?? '';
    final iconPath = getIconPath(category);

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
                    Text(
                      "Category: $category",
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Claimed By: $tcc",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Timestamp: $timestamp",
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 4, right: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Claimed',
                  style: TextStyle(
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
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
