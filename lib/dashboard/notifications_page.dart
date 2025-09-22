import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // for formatting dates
import '../services/notification_storage.dart';
import '../services/notification_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  Map<String, List<Map<String, dynamic>>> groupedNotifications = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    final data = await NotificationStorage.loadNotifications();

    final now = DateTime.now();
    final todayKey = DateFormat('yyyy-MM-dd').format(now);
    final yesterdayKey = DateFormat(
      'yyyy-MM-dd',
    ).format(now.subtract(const Duration(days: 1)));

    final filtered =
        data.where((notif) {
          final date = DateTime.parse(notif["time"]).toLocal();
          final key = DateFormat('yyyy-MM-dd').format(date);
          return key == todayKey || key == yesterdayKey;
        }).toList();

    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var notif in filtered) {
      final date = DateTime.parse(notif["time"]).toLocal();
      final key = DateFormat('yyyy-MM-dd').format(date);

      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(notif);
    }

    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    final sorted = {
      for (var key in sortedKeys)
        key:
            grouped[key]!..sort((a, b) {
              final timeA = DateTime.parse(a["time"]);
              final timeB = DateTime.parse(b["time"]);
              return timeB.compareTo(timeA);
            }),
    };

    setState(() {
      groupedNotifications = sorted;
      isLoading = false;
    });
  }

  String formatHeader(String dateKey) {
    final date = DateTime.parse(dateKey);
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    if (DateFormat('yyyy-MM-dd').format(now) == dateKey) {
      return "Today (${DateFormat('MMMM d').format(date)})";
    } else if (DateFormat('yyyy-MM-dd').format(yesterday) == dateKey) {
      return "Yesterday (${DateFormat('MMMM d').format(date)})";
    } else {
      return DateFormat('MMMM d, yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orange = const Color.fromRGBO(240, 86, 38, 1);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: orange,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : groupedNotifications.isEmpty
              ? const Center(
                child: Text(
                  'No Notifications Yet',
                  style: TextStyle(fontSize: 18),
                ),
              )
              : ListView(
                children:
                    groupedNotifications.entries.map((entry) {
                      final dateKey = entry.key;
                      final notifs = entry.value;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            color: Colors.grey[200],
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 16,
                            ),
                            child: Text(
                              formatHeader(dateKey),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          ...notifs.map((notif) {
                            final notifTime =
                                DateTime.parse(notif["time"]).toLocal();
                            final timeOnly = DateFormat(
                              'HH:mm',
                            ).format(notifTime);

                            return Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: Offset(2, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.notifications, color: orange),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          notif["title"],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          notif["body"],
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    timeOnly,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      );
                    }).toList(),
              ),
    );
  }
}

void showNewItemNotification(String fullBody) {
  NotificationService.showNotification(title: "New Found Item", body: fullBody);

  NotificationStorage.saveNotification("New Found Item", fullBody);
}
