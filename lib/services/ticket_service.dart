// Tickets are not available in the current backend.
class TicketService {
  static const String unsupportedMessage =
      'Support tickets are not available in the current backend.';

  Future<List<dynamic>> getMyTickets() async {
    throw UnsupportedError(unsupportedMessage);
  }

  Future<Map<String, dynamic>> raiseTicket(Map<String, dynamic> data) async {
    throw UnsupportedError(unsupportedMessage);
  }

  Future<List<dynamic>> getAllTickets() async {
    throw UnsupportedError(unsupportedMessage);
  }

  Future<void> updateTicket(String id, Map<String, dynamic> data) async {
    throw UnsupportedError(unsupportedMessage);
  }
}
