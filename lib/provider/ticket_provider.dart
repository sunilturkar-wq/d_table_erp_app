import 'package:flutter/material.dart';
import '../model/ticket_model.dart';
import '../services/ticket_service.dart';

class TicketProvider extends ChangeNotifier {
  final TicketService _service = TicketService();
  
  bool _isLoading = false;
  String? _errorMessage;
  List<TicketModel> _myTickets = [];
  List<TicketModel> _allTickets = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<TicketModel> get myTickets => _myTickets;
  List<TicketModel> get allTickets => _allTickets;

  Future<void> fetchMyTickets() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final rawData = await _service.getMyTickets();
      _myTickets = rawData.map((json) => TicketModel.fromJson(json)).toList();
    } catch (e) {
      _errorMessage = e is UnsupportedError
          ? TicketService.unsupportedMessage
          : e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> raiseTicket(String title, String description, String category, String subCategory, String priority, List<String> screenshotUrls) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.raiseTicket({
        "title": title,
        "description": description,
        "category": category,
        "subCategory": subCategory,
        "priority": priority,
        "screenshotUrls": screenshotUrls
      });
      await fetchMyTickets();
      return true;
    } catch (e) {
      _errorMessage = e is UnsupportedError
          ? TicketService.unsupportedMessage
          : e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTicketStatus(String id, String newStatus) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.updateTicket(id, {"status": newStatus});
      // Refresh both lists after successful update
      await fetchMyTickets();
      if (_allTickets.isNotEmpty) {
        await fetchAllTickets();
      }
      return true;
    } catch (e) {
      _errorMessage = e is UnsupportedError
          ? TicketService.unsupportedMessage
          : e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchAllTickets() async {
    _isLoading = true;
    notifyListeners();
    try {
      final rawData = await _service.getAllTickets();
      _allTickets = rawData.map((json) => TicketModel.fromJson(json)).toList();
    } catch (e) {
      _errorMessage = e is UnsupportedError
          ? TicketService.unsupportedMessage
          : e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
