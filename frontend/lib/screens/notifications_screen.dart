import 'package:flutter/material.dart';

import '../services/notification_service.dart';

class NotificationsScreen
    extends StatefulWidget {

  final String email;

  const NotificationsScreen({

    super.key,

    required this.email,
  });

  @override
  State<NotificationsScreen>
      createState() =>
          _NotificationsScreenState();
}

class _NotificationsScreenState
    extends State<NotificationsScreen> {

  bool loading = true;

  List notifications = [];

  @override
  void initState() {

    super.initState();

    loadNotifications();
  }

  Future<void>
      loadNotifications() async {

    try {

      final data =
          await NotificationService
              .getNotifications(
        widget.email,
      );

      setState(() {

        notifications = data;

        loading = false;
      });

    } catch (e) {

      setState(() {

        loading = false;
      });
    }
  }

  Future<void> markAsRead(
    String id,
  ) async {

    await NotificationService
        .markAsRead(id);

    loadNotifications();
  }

  Future<void> deleteNotification(
    String id,
  ) async {

    await NotificationService
        .deleteNotification(id);

    loadNotifications();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
          Colors.black,

      appBar: AppBar(

        backgroundColor:
            Colors.black,

        title: const Text(
          "Notificaciones",
        ),
      ),

      body: loading

          ? const Center(
              child:
                  CircularProgressIndicator(),
            )

          : notifications.isEmpty

              ? const Center(

                  child: Text(

                    "No tienes notificaciones",

                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                )

              : ListView.builder(

                  padding:
                      const EdgeInsets.all(16),

                  itemCount:
                      notifications.length,

                  itemBuilder:
                      (context, index) {

                    final item =
                        notifications[index];

                    final bool read =
                        item["read"] == true;

                    return Card(

                      color: read
                          ? const Color(
                              0xFF111111,
                            )
                          : const Color(
                              0xFF123524,
                            ),

                      child: ListTile(

                        leading: Icon(

                          read
                              ? Icons.notifications_none
                              : Icons.notifications_active,

                          color:
                              const Color(
                            0xFF10B981,
                          ),
                        ),

                        title: Text(

                          item["title"] ??
                              "",

                          style:
                              const TextStyle(

                            color:
                                Colors.white,

                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        subtitle: Text(

                          item["message"] ??
                              "",

                          style: TextStyle(

                            color:
                                Colors.grey.shade300,
                          ),
                        ),

                        trailing: PopupMenuButton(

                          color:
                              const Color(
                            0xFF111111,
                          ),

                          icon: const Icon(

                            Icons.more_vert,

                            color:
                                Colors.white,
                          ),

                          itemBuilder:
                              (context) => [

                            const PopupMenuItem(

                              value: "read",

                              child: Text(
                                "Marcar leída",
                              ),
                            ),

                            const PopupMenuItem(

                              value: "delete",

                              child: Text(
                                "Eliminar",
                              ),
                            ),
                          ],

                          onSelected:
                              (value) {

                            if (value ==
                                "read") {

                              markAsRead(
                                item["_id"],
                              );
                            }

                            if (value ==
                                "delete") {

                              deleteNotification(
                                item["_id"],
                              );
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}