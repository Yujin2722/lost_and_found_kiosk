import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

import '../services/notification_service.dart';
import '../services/notification_storage.dart';
import 'claimed_page.dart';
import 'found_page.dart';
import 'lost_page.dart';
import 'notifications_page.dart';
import '../services/user_guide_pdf_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late PageController _pageController;
  Timer? _timer;

  List<dynamic> foundItems = [];
  List<dynamic> lostItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    NotificationService.init();
    _pageController = PageController();
    fetchItems();
    _timer = Timer.periodic(Duration(seconds: 15), (timer) {
      fetchItems();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  bool _hasLoadedOnce = false;

  Future<void> fetchItems() async {
    try {
      final responses = await Future.wait([
        http.get(Uri.parse("https://throneless-ebony-billety.ngrok-free.dev/found-items")),
        http.get(Uri.parse("https://throneless-ebony-billety.ngrok-free.dev/lost-items")),
      ]);

      final foundRes = responses[0];
      final lostRes = responses[1];

      if (foundRes.statusCode == 200 && lostRes.statusCode == 200) {
        final newFoundItems = json.decode(foundRes.body) as List;
        final newLostItems = json.decode(lostRes.body) as List;

        if (_hasLoadedOnce) {
          final oldFoundIds = foundItems.map((e) => e['id']).toSet();
          final newFoundIds = newFoundItems.map((e) => e['id']).toSet();
          final addedFoundIds = newFoundIds.difference(oldFoundIds);

          for (var addedItem in newFoundItems.where(
            (item) => addedFoundIds.contains(item['id']),
          )) {
            final fullBody =
                "${addedItem['tcc_number']} reported found\n"
                "${addedItem['category']} - ${addedItem['description']}\n"
                "Claim your item within 5 days, otherwise it will be removed from the kiosk.\n"
                "Kindly coordinate with the CSU to retrieve your item.";

            final shortBody =
                "${addedItem['category']} - ${addedItem['description']}\n"
                "Kindly check if the item is yours.";

            NotificationService.showNotification(
              title: "New Found Item",
              body: shortBody,
            );

            await NotificationStorage.saveNotification(
              "New Found Item",
              fullBody,
            );
          }

          final oldLostIds = lostItems.map((e) => e['id']).toSet();
          final newLostIds = newLostItems.map((e) => e['id']).toSet();
          final addedLostIds = newLostIds.difference(oldLostIds);

          for (var addedItem in newLostItems.where(
            (item) => addedLostIds.contains(item['id']),
          )) {
            final fullBody =
                "${addedItem['tcc_number']} reported lost\n"
                "${addedItem['category']} - ${addedItem['description']}\n"
                "Claim your item within 5 days, otherwise it will be removed from the kiosk.\n"
                "Kindly coordinate with the CSU to retrieve your item.";

            final shortBody =
                "${addedItem['category']} - ${addedItem['description']}\n"
                "Kindly check if the item is yours.";

            NotificationService.showNotification(
              title: "New Lost Item",
              body: shortBody,
            );

            await NotificationStorage.saveNotification(
              "New Lost Item",
              fullBody,
            );
          }
        }

        setState(() {
          foundItems = newFoundItems;
          lostItems = newLostItems;
        });

        _hasLoadedOnce = true;
      }

      if (isLoading) {
        setState(() => isLoading = false);
      }
    } catch (e) {
      if (isLoading) {
        setState(() => isLoading = false);
      }
      print("Error fetching items: $e");
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: [
          _buildHomeContent(),
          const FoundPage(),
          const LostPage(),
          const ClaimedPage(),
        ],
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(
                  255,
                  0,
                  0,
                  0,
                ).withValues(alpha: 0.1),
                blurRadius: 6,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            selectedItemColor: const Color.fromRGBO(240, 86, 38, 1),
            unselectedItemColor: const Color.fromARGB(255, 84, 103, 89),
            onTap: _onItemTapped,
            items: [
              _buildNavItem(Icons.home, 'Home', 0),
              _buildNavItem(Icons.search, 'Found', 1),
              _buildNavItem(Icons.search_off, 'Lost', 2),
              _buildNavItem(Icons.outbox_rounded, 'Claimed', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    if (isLoading && foundItems.isEmpty && lostItems.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          Stack(
            children: [
              SizedBox(
                height: 240,
                width: double.infinity,
                child: Image.asset(
                  'assets/images/tcc_background.png',
                  fit: BoxFit.cover,
                ),
              ),
              Container(
                height: 240,
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
                color: const Color.fromARGB(
                  255,
                  0,
                  0,
                  0,
                ).withAlpha((0.7 * 255).toInt()),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Image.asset(
                          'assets/images/logo_orange.png',
                          height: 40,
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => const UserGuidePdfPage(),
                                  ),
                                );
                              },
                              child: Image.asset(
                                'assets/icons/help.gif',
                                width: 32,
                                height: 32,
                              ),
                            ),

                            const SizedBox(width: 20),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => NotificationsPage(),
                                  ),
                                );
                              },
                              child: Image.asset(
                                'assets/icons/notification.gif',
                                width: 32,
                                height: 32,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Hi there TCCians!",
                      style: TextStyle(
                        color: Color.fromARGB(255, 255, 255, 255),
                        fontSize: 24,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    RichText(
                      text: const TextSpan(
                        text: "LOST SOMETHING?\n",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color.fromRGBO(240, 86, 38, 1),
                        ),
                        children: [
                          TextSpan(
                            text: "you might find it ",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                              color: Color.fromARGB(255, 255, 255, 255),
                            ),
                          ),
                          TextSpan(
                            text: "here,\n",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 255, 255, 255),
                            ),
                          ),
                          TextSpan(
                            text: "look for the ",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                              color: Color.fromARGB(255, 254, 254, 254),
                            ),
                          ),
                          TextSpan(
                            text: "recent updates",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color.fromRGBO(240, 86, 38, 1),
                            ),
                          ),
                          TextSpan(
                            text: " below",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                              color: Color.fromARGB(255, 255, 255, 255),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color.fromRGBO(240, 86, 38, 1),
            ),
            child: Text(
              "Recent Updates (${DateFormat('MM-dd-yyyy').format(DateTime.now())})",
              style: const TextStyle(
                fontSize: 18,
                fontStyle: FontStyle.italic,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          buildSectionWithGrid(
            title: "Found Items",
            items:
                foundItems
                    .take(3)
                    .map(
                      (item) => itemCard(
                        getIconPath(item['category']),
                        item['category'],
                      ),
                    )
                    .toList(),
            onSeeAllTap: () => _onItemTapped(1),
          ),

          buildSectionWithGrid(
            title: "Lost Items",
            items:
                lostItems
                    .take(3)
                    .map(
                      (item) => itemCard(
                        getIconPath(item['category']),
                        item['category'],
                      ),
                    )
                    .toList(),
            onSeeAllTap: () => _onItemTapped(2),
          ),
          Card(
            color: const Color(0xFFFFF3E6),
            elevation: 0,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logo_orange.png',
                    width: 38,
                    height: 38,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '"You shall not steal; you shall not deal falsely; you shall not lie to one another."\n— Exodus 20:15-16',
                      style: const TextStyle(
                        color: Color.fromRGBO(240, 86, 38, 1),
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
    IconData icon,
    String label,
    int index,
  ) {
    bool isSelected = _selectedIndex == index;
    return BottomNavigationBarItem(
      icon: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 4),
              height: 3,
              width: 20,
              color: const Color(0xFFF05626),
            ),
        ],
      ),
      label: label,
    );
  }

  Widget buildSectionWithGrid({
    required String title,
    required List<Widget> items,
    required VoidCallback onSeeAllTap,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              GestureDetector(
                onTap: onSeeAllTap,
                child: const Row(
                  children: [
                    Text("See all", style: TextStyle(fontSize: 16)),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_circle_right, color: Colors.black),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child:
              items.isEmpty
                  ? Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        title == "Found Items"
                            ? "No items found. Check your internet connection or try again later."
                            : "No items lost. Check your internet connection or try again later.",
                        style: const TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                  : GridView.count(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 0,
                    children: items,
                  ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget itemCard(String iconPath, String label) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2, 2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(iconPath, width: 50, height: 50),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
