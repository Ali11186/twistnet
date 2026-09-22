class TaskModel {
  final String id;
  final String title;
  final int coins;
  final bool rewarded;
  final String? description;
  final String? iconUrl;

  TaskModel({
    required this.id,
    required this.title,
    required this.coins,
    required this.rewarded,
    this.description,
    this.iconUrl,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'مهمة',
      coins: json['coins'] ?? 0,
      rewarded: json['rewarded'] ?? false,
      description: json['description'],
      iconUrl: json['iconUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'coins': coins,
      'rewarded': rewarded,
      'description': description,
      'iconUrl': iconUrl,
    };
  }
}

class TaskCategory {
  final String id;
  final String title;
  final List<TaskModel> tasks;

  TaskCategory({
    required this.id,
    required this.title,
    required this.tasks,
  });

  factory TaskCategory.fromJson(Map<String, dynamic> json) {
    List<TaskModel> tasksList = [];
    if (json['badges'] != null) {
      for (var task in json['badges']) {
        tasksList.add(TaskModel.fromJson(task));
      }
    }
    return TaskCategory(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'فئة',
      tasks: tasksList,
    );
  }
}
