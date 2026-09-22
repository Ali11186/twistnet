import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/tasks_provider.dart';
import '../theme/app_theme.dart';
import 'tasks_screen.dart';
import 'balance_screen.dart';
import 'redeem_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const BalanceScreen(),
    const TasksScreen(),
    const RedeemScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TasksProvider>().loadBalance();
      context.read<TasksProvider>().loadTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'الرصيد',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task_alt),
            label: 'المهام',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard),
            label: 'السحب',
          ),
        ],
      ),
    );
  }
}

// ============ BALANCE SCREEN ============
class BalanceScreen extends StatelessWidget {
  const BalanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TasksProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('TWIST NET'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              auth.logout();
              tasks.clear();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await tasks.loadBalance();
          await tasks.loadTransactions();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Balance Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        'رصيدك الحالي',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${tasks.balance.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} كوينز',
                        style: GoogleFonts.cairo(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.successColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Monthly Stats Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'السحوبات الشهرية',
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: tasks.monthlyStats.percentage / 100,
                          minHeight: 12,
                          backgroundColor: Colors.grey.shade800,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            tasks.monthlyStats.isLimitReached
                                ? AppTheme.errorColor
                                : tasks.monthlyStats.isLow
                                    ? AppTheme.warningColor
                                    : AppTheme.successColor,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatItem('الحد الشهري', '${tasks.monthlyStats.limit}', AppTheme.secondaryColor),
                          _buildStatItem('تم السحب', '${tasks.monthlyStats.totalUnits}', AppTheme.errorColor),
                          _buildStatItem('المتبقي', '${tasks.monthlyStats.remaining}', AppTheme.successColor),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Status
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: tasks.monthlyStats.isLimitReached
                              ? AppTheme.errorColor.withOpacity(0.2)
                              : tasks.monthlyStats.isLow
                                  ? AppTheme.warningColor.withOpacity(0.2)
                                  : AppTheme.successColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              tasks.monthlyStats.isLimitReached
                                  ? Icons.error
                                  : tasks.monthlyStats.isLow
                                      ? Icons.warning
                                      : Icons.check_circle,
                              color: tasks.monthlyStats.isLimitReached
                                  ? AppTheme.errorColor
                                  : tasks.monthlyStats.isLow
                                      ? AppTheme.warningColor
                                      : AppTheme.successColor,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                tasks.monthlyStats.isLimitReached
                                    ? 'لقد وصلت للحد الشهري!'
                                    : tasks.monthlyStats.isLow
                                        ? 'تبقى أقل من 500 وحدة!'
                                        : 'تبقى ${tasks.monthlyStats.remaining} وحدة متاحة',
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Quick Actions
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      context,
                      'جمع النقاط',
                      Icons.task_alt,
                      AppTheme.successColor,
                      () {
                        DefaultTabController.of(context)?.animateTo(1);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionCard(
                      context,
                      'سحب الوحدات',
                      Icons.card_giftcard,
                      AppTheme.accentColor,
                      () {
                        DefaultTabController.of(context)?.animateTo(2);
                      },
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

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 10),
              Text(
                title,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
