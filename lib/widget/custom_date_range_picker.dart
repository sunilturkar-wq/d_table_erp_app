import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

Future<DateTimeRange?> showStylishDateRangePicker(BuildContext context, Color primaryColor, {bool isDark = false}) async {
  DateTime? start;
  DateTime? end;
  
  return await showDialog<DateTimeRange>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
          final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
          final mutedColor = isDark ? Colors.grey[400] : Colors.grey[600];
          final borderColor = isDark ? const Color(0xFF334155) : Colors.grey.shade200;

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: bgColor,
            surfaceTintColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.date_range_rounded, color: primaryColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Custom Range",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Start Date
                  Text("START DATE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: mutedColor, letterSpacing: 1.0)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final pk = await showDatePicker(
                        context: context,
                        initialDate: start ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        builder: (ctx, child) => Theme(
                          data: Theme.of(ctx).copyWith(
                            colorScheme: ColorScheme.light(primary: primaryColor, onPrimary: Colors.white, surface: bgColor, onSurface: textColor),
                            dialogBackgroundColor: bgColor,
                          ),
                          child: child!,
                        ),
                      );
                      if (pk != null) {
                        setState(() { 
                          start = pk; 
                          if (end != null && end!.isBefore(start!)) end = null;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 16, color: primaryColor),
                          const SizedBox(width: 12),
                          Text(start != null ? DateFormat('MMM dd, yyyy').format(start!) : "Select Start Date", style: TextStyle(color: start != null ? textColor : mutedColor, fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // End Date
                  Text("END DATE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: mutedColor, letterSpacing: 1.0)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final pk = await showDatePicker(
                        context: context,
                        initialDate: end ?? start ?? DateTime.now(),
                        firstDate: start ?? DateTime(2000),
                        lastDate: DateTime(2100),
                        builder: (ctx, child) => Theme(
                          data: Theme.of(ctx).copyWith(
                            colorScheme: ColorScheme.light(primary: primaryColor, onPrimary: Colors.white, surface: bgColor, onSurface: textColor),
                            dialogBackgroundColor: bgColor,
                          ),
                          child: child!,
                        ),
                      );
                      if (pk != null) {
                        setState(() => end = pk);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.event_available_rounded, size: 16, color: primaryColor),
                          const SizedBox(width: 12),
                          Text(end != null ? DateFormat('MMM dd, yyyy').format(end!) : "Select End Date", style: TextStyle(color: end != null ? textColor : mutedColor, fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, null),
                        child: Text("Cancel", style: TextStyle(color: mutedColor, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: (start != null && end != null) ? () => Navigator.pop(ctx, DateTimeRange(start: start!, end: end!)) : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: primaryColor.withOpacity(0.3),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text("Apply", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
