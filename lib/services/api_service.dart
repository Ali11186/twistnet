import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/task_model.dart';
import '../models/transaction_model.dart';

class ApiService {
  static const String baseUrl = 'https://api.twistmena.com/music';
  static const int monthlyLimit = 2000;

  String? _authToken;
  String? _accessToken;
  String? _tgToken;
  String? _tgRefreshToken;
  String _sessionId = '';

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String get sessionId => _sessionId;
  bool get isLoggedIn => _authToken != null;

  void setTokens({
    String? authToken,
    String? accessToken,
    String? tgToken,
    String? tgRefreshToken,
  }) {
    _authToken = authToken;
    _accessToken = accessToken;
    _tgToken = tgToken;
    _tgRefreshToken = tgRefreshToken;
    _sessionId = const Uuid().v4();
  }

  void clearTokens() {
    _authToken = null;
    _accessToken = null;
    _tgToken = null;
    _tgRefreshToken = null;
  }

  Map<String, String> _getHeaders({bool needAuth = true}) {
    final headers = {
      'user-agent': 'Twist-Mobile/9999 (Android; 12; SM-A217F; music; ar-AE)',
      'app_version': '9999',
      'appversion': '9999',
      'channel': 'mobileapp',
      'content-type': 'application/json',
      'platform': 'android',
      'accept': 'application/json',
      'accept-language': 'ar',
      'host': 'api.twistmena.com',
      'device_id': 'SP1A.210812.016',
      'tgdeviceid': '26284330',
      'device_token': '',
      'sessionid': _sessionId.isEmpty ? const Uuid().v4() : _sessionId,
      'accept-encoding': 'gzip',
      'connection': 'keep-alive',
    };

    if (needAuth && _authToken != null) {
      headers['authorization'] = 'Bearer $_authToken';
    }
    if (_accessToken != null) {
      headers['access-token'] = _accessToken!;
    }
    if (_tgToken != null) {
      headers['tg-token'] = _tgToken!;
    }
    if (_tgRefreshToken != null) {
      headers['tg-refresh-token'] = _tgRefreshToken!;
    }

    return headers;
  }

  // ============ AUTH ============

  Future<Map<String, dynamic>> sendOtp(String phone) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Dlogin/sendCode'),
        headers: _getHeaders(needAuth: false),
        body: jsonEncode({'dial': phone}),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'تم إرسال رمز التحقق'};
      } else {
        return {'success': false, 'message': 'فشل إرسال الرمز: ${response.body}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ: $e'};
    }
  }

  Future<Map<String, dynamic>> verifyOtp(String phone, String code) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Dlogin/verify'),
        headers: _getHeaders(needAuth: false),
        body: jsonEncode({
          'dial': phone,
          'verifyCode': code,
          'socialServiceName': '',
          'socialServiceToken': '',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String? token = data['token'] ?? data['authorization'];
        
        final authHeader = response.headers['authorization'];
        if (token == null && authHeader != null) {
          token = authHeader.replaceAll('Bearer ', '');
        }

        if (token != null) {
          setTokens(
            authToken: token.replaceAll('Bearer ', ''),
            accessToken: data['accessToken'],
            tgToken: data['tgToken'] ?? data['tg_token'],
            tgRefreshToken: data['tgRefreshToken'] ?? data['tg_refresh_token'],
          );
          return {'success': true, 'data': data};
        } else {
          return {'success': false, 'message': 'لم يتم استلام رمز التوثيق'};
        }
      } else {
        return {'success': false, 'message': 'رمز غير صحيح'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ: $e'};
    }
  }

  // ============ BALANCE ============

  Future<int> getBalance() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/loyalty/balance/details'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['balance'] ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // ============ TASKS ============

  Future<List<TaskCategory>> getTasks() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/loyalty/achievements/v2'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<TaskCategory> categories = [];
        
        if (data['badges'] != null) {
          for (var category in data['badges']) {
            categories.add(TaskCategory.fromJson(category));
          }
        }
        return categories;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> collectTask(String taskId, int coins) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/loyalty/action/$taskId'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'coins': coins};
      } else if (response.statusCode == 400) {
        return {'success': false, 'message': 'مكتمل بالفعل'};
      } else if (response.statusCode == 403) {
        return {'success': false, 'message': 'ممنوع', 'stop': true};
      } else {
        return {'success': false, 'message': 'فشل (${response.statusCode})'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ: $e', 'stop': true};
    }
  }

  // ============ TRANSACTIONS ============

  Future<List<TransactionModel>> getAllTransactions() async {
    List<TransactionModel> allTransactions = [];
    String? paginationToken;

    try {
      while (true) {
        String url = '$baseUrl/user/loyalty/history';
        if (paginationToken != null) {
          url += '?paginationToken=$paginationToken';
        }

        final response = await http.get(
          Uri.parse(url),
          headers: _getHeaders(),
        );

        if (response.statusCode != 200) break;

        final data = jsonDecode(response.body);
        final transactions = data['data'] as List?;
        
        if (transactions == null || transactions.isEmpty) break;

        for (var tx in transactions) {
          allTransactions.add(TransactionModel.fromJson(tx));
        }

        paginationToken = data['paginationTokens'];
        if (paginationToken == null || paginationToken.isEmpty) break;
      }
    } catch (e) {
      // Return what we have
    }

    return allTransactions;
  }

  MonthlyStats calculateMonthlyStats(List<TransactionModel> transactions) {
    final now = DateTime.now();
    int totalUnits = 0;

    for (var tx in transactions) {
      if (tx.date == 0) continue;
      
      final txDate = tx.dateTime;
      if (txDate.year == now.year && txDate.month == now.month) {
        if (tx.isDebit && tx.amount > 0) {
          final units = _extractUnitsFromDescription(tx.description);
          if (units > 0) {
            totalUnits += units;
          }
        }
      }
    }

    final remaining = monthlyLimit - totalUnits;
    final percentage = (totalUnits / monthlyLimit) * 100;

    return MonthlyStats(
      totalUnits: totalUnits,
      limit: monthlyLimit,
      remaining: remaining > 0 ? remaining : 0,
      percentage: percentage > 100 ? 100 : percentage,
    );
  }

  int _extractUnitsFromDescription(String description) {
    final patterns = [
      RegExp(r'(\d+)\s*وحدة\s*e&'),
      RegExp(r'(\d+)\s*وحده\s*e&'),
      RegExp(r'(\d+)\s*وحدة'),
      RegExp(r'(\d+)\s*وحده'),
      RegExp(r'(\d+)\s*Units?'),
      RegExp(r'(\d+)\s*وحدات'),
      RegExp(r'(\d+)\s*EAND'),
    ];

    for (var pattern in patterns) {
      final match = pattern.firstMatch(description);
      if (match != null) {
        return int.tryParse(match.group(1)!) ?? 0;
      }
    }

    if (description.contains('خصم') || 
        description.toLowerCase().contains('discount')) {
      return 0;
    }

    final numbers = RegExp(r'\d+').allMatches(description);
    if (numbers.isNotEmpty) {
      final num = int.tryParse(numbers.first.group(0)!) ?? 0;
      if (num >= 50) return num;
    }

    return 0;
  }

  // ============ PACKAGES & REDEEM ============

  Future<List<Map<String, dynamic>>> getPackages() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/loyalty/packages'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<Map<String, dynamic>> options = [];
        
        final eAndPackages = data['packages']?['E_AND'] as List?;
        if (eAndPackages != null) {
          for (var pkg in eAndPackages) {
            if (pkg['available'] == true) {
              options.add({
                'cost': pkg['cost'] ?? 0,
                'units': pkg['value'] ?? 0,
                'code': pkg['id'] ?? '',
              });
            }
          }
        }
        return options;
      }
    } catch (e) {
      // Use fallback
    }

    // Fallback packages
    return [
      {'cost': 100, 'units': 50, 'code': 'EAND_50_UNITS_ID_9'},
      {'cost': 200, 'units': 100, 'code': 'EAND_100_UNITS_ID_10'},
      {'cost': 300, 'units': 150, 'code': 'EAND_150_UNITS_ID_11'},
      {'cost': 600, 'units': 300, 'code': 'EAND_300_UNITS_ID_12'},
      {'cost': 1000, 'units': 500, 'code': 'EAND_500_UNITS_ID_13'},
      {'cost': 2000, 'units': 1000, 'code': 'EAND_1000_UNITS_ID_15'},
    ];
  }

  Future<Map<String, dynamic>> redeemUnits(String code, int units) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/loyalty/redeem/$code'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'تم السحب بنجاح! (+$units وحدة)'};
      } else {
        return {'success': false, 'message': 'فشل السحب (HTTP: ${response.statusCode})'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ: $e'};
    }
  }

  // ============ SESSION VALIDATION ============

  Future<bool> isSessionValid() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/loyalty/balance/details'),
        headers: _getHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
