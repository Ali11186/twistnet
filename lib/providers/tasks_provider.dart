import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../models/transaction_model.dart';
import '../services/api_service.dart';

class TasksProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = false;
  String? _error;
  int _balance = 0;
  List<TaskCategory> _categories = [];
  List<TransactionModel> _transactions = [];
  MonthlyStats _monthlyStats = MonthlyStats.empty();
  bool _hasCollected = false;

  bool get isLoading => _isLoading;
  String? get error => _error;
  int get balance => _balance;
  List<TaskCategory> get categories => _categories;
  List<TaskModel> get allTasks {
    List<TaskModel> tasks = [];
    for (var cat in _categories) {
      tasks.addAll(cat.tasks);
    }
    return tasks;
  }
  List<TaskModel> get pendingTasks => allTasks.where((t) => !t.rewarded).toList();
  MonthlyStats get monthlyStats => _monthlyStats;
  bool get hasCollected => _hasCollected;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> loadBalance() async {
    _balance = await _api.getBalance();
    notifyListeners();
  }

  Future<void> loadTasks() async {
    setLoading(true);
    _categories = await _api.getTasks();
    setLoading(false);
  }

  Future<void> loadTransactions() async {
    _transactions = await _api.getAllTransactions();
    _monthlyStats = _api.calculateMonthlyStats(_transactions);
    notifyListeners();
  }

  Future<Map<String, dynamic>> collectAllTasks() async {
    setLoading(true);
    _hasCollected = false;
    
    int totalEarned = 0;
    int completed = 0;
    int failed = 0;
    bool hasError = false;
    String errorMessage = '';

    final tasks = pendingTasks;
    
    for (var task in tasks) {
      final result = await _api.collectTask(task.id, task.coins);
      
      if (result['success']) {
        totalEarned += task.coins;
        completed++;
      } else if (result['stop'] == true) {
        hasError = true;
        errorMessage = result['message'] ?? 'خطأ';
        failed++;
        break;
      } else {
        failed++;
      }
      
      // Small delay
      await Future.delayed(const Duration(milliseconds: 300));
    }

    // Reload balance
    await loadBalance();
    
    setLoading(false);
    _hasCollected = true;
    notifyListeners();

    return {
      'totalEarned': totalEarned,
      'completed': completed,
      'failed': failed,
      'hasError': hasError,
      'errorMessage': errorMessage,
    };
  }

  Future<List<Map<String, dynamic>>> getRedeemOptions() async {
    final packages = await _api.getPackages();
    final remaining = _monthlyStats.remaining;
    
    return packages.where((pkg) {
      final cost = pkg['cost'] as int;
      final units = pkg['units'] as int;
      return _balance >= cost && units <= remaining;
    }).toList();
  }

  Future<Map<String, dynamic>> redeem(String code, int units) async {
    final result = await _api.redeemUnits(code, units);
    
    if (result['success']) {
      await loadBalance();
      await loadTransactions();
    }
    
    return result;
  }

  void clear() {
    _balance = 0;
    _categories = [];
    _transactions = [];
    _monthlyStats = MonthlyStats.empty();
    _hasCollected = false;
    notifyListeners();
  }
}
