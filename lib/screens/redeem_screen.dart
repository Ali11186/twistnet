import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/tasks_provider.dart';
import '../theme/app_theme.dart';

class RedeemScreen extends StatefulWidget {
  const RedeemScreen({super.key});

  @override
  State<RedeemScreen> createState() => _RedeemScreenState();
}

class _RedeemScreenState extends State<RedeemScreen> {
  List<Map<String, dynamic>> _options = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    final tasks = context.read<TasksProvider>();
    await tasks.loadBalance();
    await tasks.loadTransactions();
    
    final options = await tasks.getRedeemOptions();
    
    setState(() {
      _options = options;
      _isLoading = false;
    });
  }

  Future<void> _redeem(Map<String, dynamic> option) async {
    final cost = option['cost'] as int;
    final units = option['units'] as int;
    final code = option['code'] as String;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'تأكيد السحب',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'هل تريد سحب $units وحدة مقابل $cost كوينز؟',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('تأكيد', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final tasks = context.read<TasksProvider>();
    final result = await tasks.redeem(code, units);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success']
              ? AppTheme.successColor
              : AppTheme.errorColor,
        ),
      );
      
      if (result['success']) {
        _loadOptions();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TasksProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('سحب الوحدات'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadOptions,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Info Card
                    Card(
                      color: AppTheme.secondaryColor.withOpacity(0.2),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: AppTheme.secondaryColor,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'رصيدك: ${tasks.balance} كوينز | المتبقي: ${tasks.monthlyStats.remaining} وحدة',
                                style: GoogleFonts.cairo(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    if (tasks.monthlyStats.isLimitReached)
                      Card(
                        color: AppTheme.errorColor.withOpacity(0.2),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 50,
                                color: AppTheme.errorColor,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'لقد وصلت للحد الشهري!',
                                style: GoogleFonts.cairo(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.errorColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'لا يمكنك سحب المزيد حتى الشهر القادم',
                                style: GoogleFonts.cairo(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (_options.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Icon(
                                Icons.card_giftcard,
                                size: 50,
                                color: Colors.grey.shade700,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'لا توجد باقات متاحة',
                                style: GoogleFonts.cairo(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'الرصيد غير كافي أو الحد المتبقي منخفض',
                                style: GoogleFonts.cairo(
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._options.map((option) {
                        final cost = option['cost'] as int;
                        final units = option['units'] as int;
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppTheme.accentColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  '$units',
                                  style: GoogleFonts.cairo(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.accentColor,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              '$units وحدة',
                              style: GoogleFonts.cairo(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '$cost كوينز',
                              style: GoogleFonts.cairo(
                                color: AppTheme.successColor,
                              ),
                            ),
                            trailing: ElevatedButton(
                              onPressed: () => _redeem(option),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.successColor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                              ),
                              child: Text(
                                'سحب',
                                style: GoogleFonts.cairo(),
                              ),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
    );
  }
}
