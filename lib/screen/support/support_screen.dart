import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:d_table_erp_app/model/ticket_model.dart';
import 'package:d_table_erp_app/provider/auth_provider.dart';
import 'package:d_table_erp_app/provider/ticket_provider.dart';
import 'package:d_table_erp_app/widget/app_dropdown.dart';
import 'raise_ticket.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({Key? key}) : super(key: key);

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedStatus = "Pending";
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTickets();
    });
  }

  void _loadTickets() {
    final ticketProvider = context.read<TicketProvider>();
    final authProvider = context.read<AuthProvider>();

    // Always fetch my tickets
    ticketProvider.fetchMyTickets();

    // If Admin, also fetch all tickets
    if (authProvider.isAdmin) {
      ticketProvider.fetchAllTickets();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TicketProvider>();
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;
    final userName =
        "${auth.currentUser?.firstName} ${auth.currentUser?.lastName}";
    final isUnavailable =
        provider.errorMessage != null &&
        provider.errorMessage!.contains('not available in the current backend');
    return Scaffold(
      backgroundColor: const Color(
        0xFFC7F0DF,
      ), // Light greenish background as in screenshot
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color(0xFF003366),
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Support / Help Tickets',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadTickets,
          ),
        ],
        bottom: isAdmin
            ? TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(text: "My Tickets"),
                  Tab(text: "All Tickets"),
                ],
              )
            : null,
      ),
      body: isUnavailable
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.support_agent_outlined,
                      size: 64,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Support tickets are not available in the current backend.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This screen will be enabled once the backend exposes ticket APIs.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : isAdmin
          ? TabBarView(
              controller: _tabController,
              children: [
                _buildMainContent(
                  provider.myTickets,
                  provider.isLoading,
                  "My Tickets",
                  userName,
                ),
                _buildMainContent(
                  provider.allTickets,
                  provider.isLoading,
                  "All Tickets",
                  null,
                ),
              ],
            )
          : _buildMainContent(
              provider.myTickets,
              provider.isLoading,
              "My Tickets",
              userName,
            ),
    );
  }

  Widget _buildMainContent(
    List<TicketModel> tickets,
    bool isLoading,
    String viewType,
    String? defaultRaiserName,
  ) {
    List<TicketModel> filteredTickets = tickets.where((t) {
      bool matchesStatus = false;
      if (_selectedStatus == "Pending")
        matchesStatus = t.status == 'Open';
      else if (_selectedStatus == "In Progress")
        matchesStatus = t.status == 'InProgress';
      else if (_selectedStatus == "Closed")
        matchesStatus = (t.status == 'Resolved' || t.status == 'Closed');

      bool matchesSearch =
          _searchQuery.isEmpty ||
          t.title.toLowerCase().contains(_searchQuery.toLowerCase());

      return matchesStatus && matchesSearch;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Hello ${defaultRaiserName?.split(' ')[0] ?? 'User'}, How can I help you today?",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 30),

          // Title & Raise Ticket Button Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text(
                  "Support Tickets",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const RaiseTicketScreen(),
                    );
                  },
                  icon: const Icon(Icons.add, size: 18, color: Colors.white),
                  label: const Text(
                    "Raise a Ticket",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003366),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Search Box
          Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.search, size: 20, color: Colors.black54),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: "Search",
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(fontSize: 15),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Filters Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterTab("Pending"),
                const SizedBox(width: 8),
                _filterTab("In Progress"),
                const SizedBox(width: 8),
                _filterTab("Closed"),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF1E2124), // Dark header from screenshot
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    "Subject",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "Created On",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "Status",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    "Action",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Table Body / List
          Expanded(
            child: Container(
              color: Colors.white.withOpacity(0.3),
              child: _buildTicketsList(
                filteredTickets,
                isLoading,
                defaultRaiserName,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterTab(String label) {
    bool isSelected = _selectedStatus == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatus = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF003366) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? null : Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            if (isSelected)
              const Icon(Icons.check, size: 16, color: Colors.white),
            if (isSelected) const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketsList(
    List<TicketModel> tickets,
    bool isLoading,
    String? defaultRaiserName,
  ) {
    if (isLoading && tickets.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (tickets.isEmpty) {
      return Container(
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 50),
            Center(
              child: Text(
                "No items found",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            SizedBox(height: 8),
            Text(
              "The list is currently empty.",
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        _loadTickets();
      },
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: tickets.length,
        separatorBuilder: (context, index) =>
            const Divider(height: 1, color: Colors.black12),
        itemBuilder: (context, index) {
          final ticket = tickets[index];
          String raiser =
              ticket.raisedByName ?? defaultRaiserName ?? 'Unknown User';

          return InkWell(
            onTap: () {
              _showTicketDetails(context, ticket, raiser);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ticket.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ticket.type,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      ticket.createdAt.split('T')[0],
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _statusText(ticket.status),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: IconButton(
                      icon: const Icon(
                        Icons.remove_red_eye,
                        color: Colors.black54,
                        size: 20,
                      ),
                      onPressed: () =>
                          _showTicketDetails(context, ticket, raiser),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _statusText(String status) {
    Color color = Colors.black87;
    if (status == 'Open') color = Colors.blue;
    if (status == 'InProgress') color = Colors.orange;
    if (status == 'Resolved' || status == 'Closed') color = Colors.green;

    return Text(
      status,
      style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13),
    );
  }

  Widget _statusChip(String status) {
    Color bg = Colors.grey;
    if (status == 'Open') bg = Colors.blue;
    if (status == 'InProgress') bg = Colors.orange;
    if (status == 'Resolved' || status == 'Closed') bg = Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bg),
      ),
      child: Text(
        status,
        style: TextStyle(color: bg, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  void _showTicketDetails(
    BuildContext context,
    TicketModel ticket,
    String raiser,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
                String currentStatus = ticket.status;
                bool isUpdating = false;

                void _updateStatus(String newStatus) async {
                  if (newStatus == currentStatus) return;
                  setModalState(() => isUpdating = true);
                  final provider = context.read<TicketProvider>();
                  bool success = await provider.updateTicketStatus(
                    ticket.id,
                    newStatus,
                  );
                  setModalState(() {
                    isUpdating = false;
                    if (success) currentStatus = newStatus;
                  });
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Status updated!',
                          style: TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }

                return SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 50,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              ticket.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _statusChip(currentStatus),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(),
                      _detailRow("Ticket ID", ticket.id),
                      _detailRow("Raised By", raiser),
                      _detailRow("Date", ticket.createdAt.split('T')[0]),
                      _detailRow("Type", ticket.type),
                      _detailRow("Priority", ticket.priority),
                      const SizedBox(height: 10),
                      const Text(
                        "Description:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          ticket.description ?? "No description provided.",
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      if (ticket.screenshotUrls != null &&
                          ticket.screenshotUrls!.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Text(
                          "Attachments:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: ticket.screenshotUrls!.length,
                            itemBuilder: (context, idx) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    ticket.screenshotUrls![idx],
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => Container(
                                      width: 100,
                                      height: 100,
                                      color: Colors.grey[300],
                                      child: const Icon(
                                        Icons.image_not_supported,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      if (context.read<AuthProvider>().isAdmin) ...[
                        const SizedBox(height: 20),
                        const Text(
                          "Update Status:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: AppDropdown<String>(
                                isCompact: false,
                                value: currentStatus,
                                items: const [
                                  'Open',
                                  'InProgress',
                                  'Resolved',
                                  'Closed',
                                ],
                                labelBuilder: (s) => s,
                                label: 'TICKET STATUS',
                                onChanged: isUpdating
                                    ? (_) {}
                                    : (val) {
                                        if (val != null) _updateStatus(val);
                                      },
                              ),
                            ),
                            if (isUpdating)
                              const Padding(
                                padding: EdgeInsets.only(left: 16),
                                child: CircularProgressIndicator(),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 40),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
