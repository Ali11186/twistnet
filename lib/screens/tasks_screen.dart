import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/tasks_provider.dart';
import '../theme/app_theme.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TasksProvider>().loadTasks();
    });
  }

  Future<void> _collectAll() async {
    final tasks = context.read<TasksProvider>();
    final result = await tasks.collectAllTasks();

    if (mounted) {
      if (result['hasError']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['errorMessage'] ?? 'حدث خطأ'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم جمع ${result['completed']} مهمة! +${result['totalEarned']} كوينز'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TasksProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('المهام'),
        actions: [
          if (tasks.pendingTasks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${tasks.pendingTasks.length} مهمة متاحة',
                  style: GoogleFonts.cairo(
                    color: AppTheme.accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: tasks.isLoading && tasks.categories.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Collect All Button
                if (tasks.pendingTasks.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton.icon(
                      onPressed: tasks.isLoading ? null : _collectAll,
                      icon: tasks.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(tasks.isLoading ? 'جاري الجمع...' : 'جمع الكل'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ),

                // Tasks List
                Expanded(
                  child: tasks.categories.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.task_alt,
                                size: 80,
                                color: Colors.grey.shade700,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'لا توجد مهام متاحة',
                                style: GoogleFonts.cairo(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => tasks.loadTasks(),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: tasks.categories.length,
                            itemBuilder: (context, catIndex) {
                              final category = tasks.categories[catIndex];
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (category.tasks.isNotEmpty) ...[
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Text(
                                        category.title,
                                        style: GoogleFonts.cairo(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.secondaryColor,
                                        ),
                                      ),
                                    ),
                                    ...category.tasks.map((task) {
                                      return Card(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: task.rewarded
                                                ? Colors.grey.shade700
                                                : AppTheme.successColor.withOpacity(0.2),
                                            child: Icon(
                                              task.rewarded
                                                  ? Icons.check
                                                  : Icons.star,
                                              color: task.rewarded
                                                  ? Colors.grey
                                                  : AppTheme.accentColor,
                                            ),
                                          ),
                                          title: Text(
                                            task.title,
                                            style: GoogleFonts.cairo(
                                              decoration: task.rewarded
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                              color: task.rewarded
                                                  ? Colors.grey
                                                  : Colors.white,
                                            ),
                                          ),
                                          subtitle: Text(
                                            '+${task.coins} كوينز',
                                            style: GoogleFonts.cairo(
                                              color: AppTheme.accentColor,
                                            ),
                                          ),
                                          trailing: task.rewarded
                                              ? const Icon(
                                                  Icons.check_circle,
                                                  color: AppTheme.successColor,
                                                )
                                              : const Icon(
                                                  Icons.arrow_forward_ios,
                                                  size: 16,
                                                ),
                                        ),
                                      ).animate().fadeIn(
                                            delay: Duration(
                                              milliseconds: 50 * catIndex,
                                            ),
                                          );
                                    }),
                                  ],
                                ],
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}
