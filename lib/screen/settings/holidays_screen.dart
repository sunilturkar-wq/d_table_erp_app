import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../provider/auth_provider.dart';
import '../../provider/holiday_provider.dart';

class HolidaysScreen extends StatefulWidget {
  const HolidaysScreen({super.key});

  @override
  State<HolidaysScreen> createState() => _HolidaysScreenState();
}

class _HolidaysScreenState extends State<HolidaysScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HolidayProvider>().fetchHolidays();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'HOLIDAYS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: const Color(0xFF003366),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: _showAddHolidayDialog,
              backgroundColor: const Color(0xFF003366),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Add Holiday',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      body: Consumer<HolidayProvider>(
        builder: (context, provider, child) {
          final filteredHolidays = provider.holidays.where((holiday) {
            final name = (holiday['name'] ?? '').toString().toLowerCase();
            final formattedDate = _holidayDateLabel(holiday).toLowerCase();
            final query = _searchQuery.trim().toLowerCase();
            return query.isEmpty ||
                name.contains(query) ||
                formattedDate.contains(query);
          }).toList();

          return Column(
            children: [
              _buildTopStats(provider.holidays),
              _buildToolbar(filteredHolidays.length, isAdmin),
              if (provider.error != null && provider.holidays.isNotEmpty)
                _buildErrorBanner(provider.error!),
              Expanded(
                child: RefreshIndicator(
                  color: const Color(0xFF003366),
                  onRefresh: () =>
                      context.read<HolidayProvider>().fetchHolidays(),
                  child: provider.isLoading && provider.holidays.isEmpty
                      ? _buildLoadingState()
                      : filteredHolidays.isEmpty
                      ? _buildEmptyState(
                          isSearchMode: _searchQuery.trim().isNotEmpty,
                          isAdmin: isAdmin,
                        )
                      : _buildHolidayList(filteredHolidays, isAdmin),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopStats(List<dynamic> holidays) {
    final upcoming = _upcomingHolidays(holidays);
    final nextHoliday = upcoming.isNotEmpty
        ? (upcoming.first['name'] ?? 'Upcoming').toString()
        : 'None';
    final currentYear = DateTime.now().year;
    final currentYearCount = holidays.where((holiday) {
      final date = _parseHolidayDate(holiday['date']);
      return date?.year == currentYear;
    }).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _statCard(
              'Total Holidays',
              holidays.length.toString(),
              const Color(0xFF003366),
              Icons.event_available_rounded,
            ),
            const SizedBox(width: 12),
            _statCard(
              'Next Holiday',
              nextHoliday,
              Colors.blue,
              Icons.upcoming_rounded,
            ),
            const SizedBox(width: 12),
            _statCard(
              'This Year',
              currentYearCount.toString(),
              const Color(0xFFF59E0B),
              Icons.calendar_month_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, Color color, IconData icon) {
    return SizedBox(
      width: 150,
      height: 110,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          value,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: value.length > 10 ? 16 : 20,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF111827),
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          title.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(height: 4, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar(int filteredCount, bool isAdmin) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search holidays...',
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E293B),
                    ),
                    children: [
                      const TextSpan(text: 'Holiday List '),
                      TextSpan(
                        text: '($filteredCount)',
                        style: const TextStyle(color: Color(0xFF003366)),
                      ),
                    ],
                  ),
                ),
              ),
              if (isAdmin)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6E4F2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'ADMIN',
                    style: TextStyle(
                      color: Color(0xFF003366),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFDC2626)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Color(0xFF991B1B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFF003366)),
    );
  }

  Widget _buildHolidayList(List<dynamic> holidays, bool isAdmin) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: holidays.length,
      itemBuilder: (context, index) {
        final holiday = holidays[index];
        final date = _parseHolidayDate(holiday['date']);
        final isUpcoming =
            date != null &&
            !date.isBefore(
              DateTime(
                DateTime.now().year,
                DateTime.now().month,
                DateTime.now().day,
              ),
            );

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF003366).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.event_rounded,
                  color: Color(0xFF003366),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (holiday['name'] ?? '').toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _holidayDateLabel(holiday),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isUpcoming
                            ? const Color(0xFFD6E4F2)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        isUpcoming ? 'Upcoming' : 'Past',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isUpcoming
                              ? const Color(0xFF003366)
                              : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isAdmin)
                IconButton(
                  onPressed: () => _confirmDelete(
                    holiday['id'].toString(),
                    (holiday['name'] ?? 'this holiday').toString(),
                  ),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({required bool isSearchMode, required bool isAdmin}) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Column(
          children: [
            Icon(
              Icons.event_busy_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              isSearchMode ? 'No Holidays Found' : 'Empty List',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isSearchMode
                  ? 'Try a different holiday name or date.'
                  : isAdmin
                  ? 'Add one or more holidays to get started.'
                  : 'No holidays have been added yet.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      ],
    );
  }

  List<dynamic> _upcomingHolidays(List<dynamic> holidays) {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final upcoming = holidays.where((holiday) {
      final date = _parseHolidayDate(holiday['date']);
      return date != null && !date.isBefore(today);
    }).toList();

    upcoming.sort((a, b) {
      final first = _parseHolidayDate(a['date']) ?? DateTime(2100);
      final second = _parseHolidayDate(b['date']) ?? DateTime(2100);
      return first.compareTo(second);
    });
    return upcoming;
  }

  DateTime? _parseHolidayDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  String _holidayDateLabel(dynamic holiday) {
    final date = _parseHolidayDate(holiday['date']);
    if (date == null) return 'No date';
    return DateFormat('dd MMM yyyy').format(date.toLocal());
  }

  Future<void> _showAddHolidayDialog() async {
    final added = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _AddHolidayDialog(),
    );

    if (!mounted || added != true) return;
    _showSnack('Holidays added successfully', false);
  }

  void _confirmDelete(String id, String name) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Holiday'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final provider = context.read<HolidayProvider>();
              final success = await provider.deleteHoliday(id);
              if (!mounted) return;
              _showSnack(
                success
                    ? 'Holiday deleted successfully'
                    : (provider.error ?? 'Failed to delete holiday'),
                !success,
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF003366),
      ),
    );
  }
}

class _AddHolidayDialog extends StatefulWidget {
  const _AddHolidayDialog();

  @override
  State<_AddHolidayDialog> createState() => _AddHolidayDialogState();
}

class _AddHolidayDialogState extends State<_AddHolidayDialog> {
  final List<_HolidayDraft> _entries = [_HolidayDraft()];
  bool _isSubmitting = false;

  @override
  void dispose() {
    for (final entry in _entries) {
      entry.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 460,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Add New Holiday',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.pop(context, false),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  children: [
                    ..._entries.asMap().entries.map((entry) {
                      final index = entry.key;
                      final draft = entry.value;
                      return _buildEntryCard(index, draft);
                    }),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _isSubmitting ? null : _addEntry,
                      icon: const Icon(Icons.add),
                      label: const Text('Add More Holiday'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003366),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Add Holidays',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEntryCard(int index, _HolidayDraft draft) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Holiday ${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              if (_entries.length > 1)
                IconButton(
                  onPressed: _isSubmitting ? null : () => _removeEntry(index),
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: Colors.redAccent,
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: draft.nameController,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: 'Holiday Name',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _isSubmitting ? null : () => _pickDate(index),
            borderRadius: BorderRadius.circular(14),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    color: Color(0xFF003366),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      draft.selectedDate == null
                          ? 'Select Date'
                          : DateFormat(
                              'dd MMM yyyy',
                            ).format(draft.selectedDate!),
                      style: TextStyle(
                        color: draft.selectedDate == null
                            ? Colors.grey
                            : const Color(0xFF0F172A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addEntry() {
    setState(() {
      _entries.add(_HolidayDraft());
    });
  }

  void _removeEntry(int index) {
    if (_entries.length == 1) return;
    setState(() {
      final removed = _entries.removeAt(index);
      removed.dispose();
    });
  }

  Future<void> _pickDate(int index) async {
    final current = _entries[index].selectedDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (!mounted || picked == null) return;
    setState(() {
      _entries[index].selectedDate = picked;
    });
  }

  Future<void> _submit() async {
    final payload = _entries
        .where(
          (entry) =>
              entry.nameController.text.trim().isNotEmpty &&
              entry.selectedDate != null,
        )
        .map(
          (entry) => {
            'name': entry.nameController.text.trim(),
            'date': DateFormat('yyyy-MM-dd').format(entry.selectedDate!),
          },
        )
        .toList();

    if (payload.isEmpty) {
      _showSnack('Please add at least one valid holiday', true);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final provider = context.read<HolidayProvider>();
    final success = await provider.addHolidays(payload);
    if (!mounted) return;

    if (success) {
      Navigator.pop(context, true);
      return;
    }

    setState(() {
      _isSubmitting = false;
    });
    _showSnack(provider.error ?? 'Failed to add holidays', true);
  }

  void _showSnack(String message, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF003366),
      ),
    );
  }
}

class _HolidayDraft {
  _HolidayDraft() : nameController = TextEditingController();

  final TextEditingController nameController;
  DateTime? selectedDate;

  void dispose() {
    nameController.dispose();
  }
}
