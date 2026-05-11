import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:d_table_erp_app/provider/notification_provider.dart';
import 'package:d_table_erp_app/model/notification_model.dart';
import 'package:d_table_erp_app/screen/home/task_detail.dart';
import 'package:d_table_erp_app/widget/shimmer_loading.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  IconData _notificationIcon(String type) {
    switch (type) {
      case 'delegation':
        return Icons.inbox_outlined;
      case 'remark':
      case 'remark_added':
        return Icons.info_outline;
      case 'revision':
        return Icons.history_toggle_off;
      case 'status_change':
      case 'status_changed':
        return Icons.check_circle_outline;
      case 'overdue':
        return Icons.warning_amber_rounded;
      default:
        return Icons.notifications_none;
    }
  }

  Color _notificationIconColor(String type) {
    switch (type) {
      case 'delegation':
        return const Color(0xFF3B82F6);
      case 'remark':
      case 'remark_added':
        return const Color(0xFF003366);
      case 'revision':
        return const Color(0xFFF59E0B);
      case 'status_change':
      case 'status_changed':
        return const Color(0xFF8B5CF6);
      case 'overdue':
        return const Color(0xFFF97316);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _formatNotificationDate(String rawDate) {
    if (rawDate.trim().isEmpty) {
      return '';
    }

    try {
      final parsed = DateTime.parse(rawDate).toLocal();
      return DateFormat('dd MMM yyyy').format(parsed);
    } catch (_) {
      return rawDate;
    }
  }

  Widget _buildErrorState(NotificationProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 42),
            const SizedBox(height: 12),
            Text(
              provider.errorMessage ?? 'Failed to load notifications.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  context.read<NotificationProvider>().fetchNotifications(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openNotificationTarget(NotificationModel notif) async {
    if (!notif.isRead) {
      await context.read<NotificationProvider>().markOneAsRead(notif.id);
    }

    final refId = notif.refId?.trim();
    if (!mounted) return;

    if (refId == null || refId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No linked task is available for this notification.'),
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskDetailScreen(task: {'id': refId}, allowEdit: false),
      ),
    );
  }

  Future<void> _confirmClearAll(NotificationProvider provider) async {
    if (provider.notifications.isEmpty) return;

    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Notifications'),
        content: const Text(
          'This will permanently remove all notifications from your inbox.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (shouldClear == true && mounted) {
      await provider.clearAllNotifications();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Notifications'),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.done_all),
                  tooltip: 'Mark all as read',
                  onPressed: provider.notifications.isEmpty
                      ? null
                      : () => provider.markAllAsRead(),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined),
                  tooltip: 'Clear all',
                  onPressed: provider.notifications.isEmpty
                      ? null
                      : () => _confirmClearAll(provider),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const ShimmerListLoading();
          }

          if (provider.errorMessage != null && provider.notifications.isEmpty) {
            return _buildErrorState(provider);
          }

          if (provider.notifications.isEmpty) {
            return const Center(child: Text("You have no notifications."));
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: RefreshIndicator(
                onRefresh: () async {
                  await context
                      .read<NotificationProvider>()
                      .fetchNotifications();
                },
                child: ListView(
                  children: [
                    if (provider.errorMessage != null)
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade100),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.redAccent,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                provider.errorMessage!,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ...provider.notifications.map((notif) {
                      final iconColor = _notificationIconColor(notif.type);
                      final title = notif.title.trim().isEmpty
                          ? notif.message
                          : notif.title;

                      return Dismissible(
                        key: ValueKey(notif.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          color: Colors.red,
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                          ),
                        ),
                        confirmDismiss: (_) async {
                          return await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Notification'),
                                  content: const Text(
                                    'Remove this notification from your inbox?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              ) ??
                              false;
                        },
                        onDismissed: (_) =>
                            provider.deleteNotification(notif.id),
                        child: Container(
                          decoration: BoxDecoration(
                            color: notif.isRead
                                ? Colors.transparent
                                : const Color(0xFF003366).withOpacity(0.06),
                            border: notif.isRead
                                ? null
                                : const Border(
                                    left: BorderSide(
                                      color: Color(0xFF003366),
                                      width: 4,
                                    ),
                                  ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: iconColor.withOpacity(0.14),
                              child: Icon(
                                _notificationIcon(notif.type),
                                color: iconColor,
                              ),
                            ),
                            title: Text(
                              title,
                              style: TextStyle(
                                fontWeight: notif.isRead
                                    ? FontWeight.w600
                                    : FontWeight.w800,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (notif.message.trim().isNotEmpty &&
                                    notif.message.trim() != title.trim()) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    notif.message,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Text(
                                  _formatNotificationDate(notif.createdAt),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              onPressed: () =>
                                  provider.deleteNotification(notif.id),
                              tooltip: 'Delete',
                            ),
                            onTap: () => _openNotificationTarget(notif),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
