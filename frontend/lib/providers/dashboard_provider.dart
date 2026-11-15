import 'package:flutter/material.dart';
import '../models/report_models.dart';
import '../services/report_service.dart';

class DashboardProvider extends ChangeNotifier {
  final ReportService _reportService = ReportService();

  DashboardStatsModel? _stats;
  bool _isLoading = false;
  String? _errorMessage;

  DashboardStatsModel? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadDashboard({bool refresh = false}) async {
    if (_isLoading && !refresh) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _stats = await _reportService.getDashboardStats();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
