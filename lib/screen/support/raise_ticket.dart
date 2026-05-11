import 'dart:io';
import 'dart:convert';
import 'package:d_table_erp_app/provider/ticket_provider.dart';
import 'package:d_table_erp_app/widget/app_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class RaiseTicketScreen extends StatefulWidget {
  const RaiseTicketScreen({Key? key}) : super(key: key);

  @override
  State<RaiseTicketScreen> createState() => _RaiseTicketScreenState();
}

class _RaiseTicketScreenState extends State<RaiseTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String? _selectedCategory;
  String? _selectedSubCategory;

  File? _selectedMedia;
  String? _base64Media;
  final ImagePicker _picker = ImagePicker();

  final List<String> _categories = [
    'Report An Error',
    'Give Feedback',
    'Billing/Subscription Issue',
    'Delete My Account',
  ];

  final List<String> _subCategories = [
    'Tasks Delegation',
    'My Team',
    'Intranet',
    'Leaves',
    'Attendance',
    'Other',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _selectedMedia = File(pickedFile.path);
        });
        final bytes = await _selectedMedia!.readAsBytes();
        final String base64Image = base64Encode(bytes);
        _base64Media = "data:image/png;base64,$base64Image";
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  void _showUnavailableMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _submitTicket() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a Category')),
        );
        return;
      }
      final provider = Provider.of<TicketProvider>(context, listen: false);

      List<String> screenshots = [];
      if (_base64Media != null) {
        screenshots.add(_base64Media!);
      }

      final success = await provider.raiseTicket(
        _titleController.text.trim(),
        _descController.text.trim(),
        _selectedCategory ?? 'General',
        _selectedSubCategory ?? 'Other',
        'Medium', // Default priority for now
        screenshots,
      );

      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ticket raised successfully!',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              provider.errorMessage ?? 'Failed to raise ticket',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<TicketProvider>().isLoading;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500, // Fixed width for desktop/tablet style look
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Raise a Ticket",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.black54),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Title Field
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'Ticket Title',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Title is required' : null,
                ),
                const SizedBox(height: 16),

                // Category Dropdown
                AppDropdown<String>(
                  isCompact: false,
                  value: _selectedCategory ?? _categories.first,
                  items: _categories,
                  labelBuilder: (c) => c,
                  label: 'CATEGORY',
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCategory = val);
                  },
                ),
                const SizedBox(height: 16),

                // Sub Category Dropdown
                AppDropdown<String>(
                  isCompact: false,
                  value: _selectedSubCategory ?? _subCategories.first,
                  items: _subCategories,
                  labelBuilder: (s) => s,
                  label: 'SUB CATEGORY',
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedSubCategory = val);
                  },
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Description',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (val) => val == null || val.isEmpty
                      ? 'Description is required'
                      : null,
                ),
                const SizedBox(height: 16),

                // Mic and Upload row
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.mic, color: Colors.black54),
                      onPressed: () {
                        _showUnavailableMessage(
                          'Voice notes are not available for support tickets in the current backend.',
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Expanded(
                      child: Text(
                        "Upload Image/Videos showing your Issue",
                        style: TextStyle(fontSize: 13, color: Colors.black87),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      child: Icon(
                        Icons.image,
                        size: 20,
                        color: Colors.grey.shade600,
                      ),
                      onTap: () => _pickMedia(ImageSource.gallery),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      child: Icon(
                        Icons.camera_alt,
                        size: 20,
                        color: Colors.grey.shade600,
                      ),
                      onTap: () => _pickMedia(ImageSource.camera),
                    ),
                  ],
                ),
                if (_selectedMedia != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Attached: ${_selectedMedia!.path.split('/').last}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.red,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => setState(() {
                          _selectedMedia = null;
                          _base64Media = null;
                        }),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _submitTicket,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003366),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Submit',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
