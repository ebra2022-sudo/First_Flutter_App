import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // For JSON encoding/decoding

void main() {
  runApp(const TimeTrackingApp());
}

class TimeTrackingApp extends StatelessWidget {
  const TimeTrackingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const TimeTrackingScreen(),
    );
  }
}

// Model for Time Entry
class TimeEntry {
  final String project;
  final String task;
  final DateTime date;
  final double hours;
  final String description;

  TimeEntry({
    required this.project,
    required this.task,
    required this.date,
    required this.hours,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
        'project': project,
        'task': task,
        'date': date.toIso8601String(),
        'hours': hours,
        'description': description,
      };

  factory TimeEntry.fromJson(Map<String, dynamic> json) => TimeEntry(
        project: json['project'],
        task: json['task'],
        date: DateTime.parse(json['date']),
        hours: json['hours'],
        description: json['description'] ?? json['note'],
      );
}

// Main Time Tracking Screen
class TimeTrackingScreen extends StatefulWidget {
  const TimeTrackingScreen({super.key});

  @override
  _TimeTrackingScreenState createState() => _TimeTrackingScreenState();
}

class _TimeTrackingScreenState extends State<TimeTrackingScreen> {
  bool isAllEntriesSelected = true; // Track which tab is selected
  List<TimeEntry> timeEntries = [];
  List<String> projects = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Load time entries and projects from shared_preferences
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final timeEntriesJson = prefs.getStringList('timeEntries') ?? [];
      timeEntries = timeEntriesJson
          .map((json) => TimeEntry.fromJson(jsonDecode(json)))
          .toList();
      projects = prefs.getStringList('projects') ?? [];
    });
  }

  // Save time entries to shared_preferences after deletion
  Future<void> _saveTimeEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final timeEntriesJson = timeEntries.map((entry) => jsonEncode(entry.toJson())).toList();
    await prefs.setStringList('timeEntries', timeEntriesJson);
  }

  // Delete a time entry
  void _deleteTimeEntry(int index) {
    setState(() {
      timeEntries.removeAt(index);
      _saveTimeEntries();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Time entry deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A8C7B), // Teal color for the header
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              // Open the drawer when the menu button is pressed
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: const Text(
          'Time Tracking',
          style: TextStyle(color: Colors.white),
        ),
      ),
      // Drawer (Sidebar)
      drawer: Drawer(
        child: Column(
          children: [
            // Drawer Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              color: const Color(0xFF4A8C7B), // Teal color for the header
              child: const Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Drawer Items
            ListTile(
              leading: const Icon(Icons.folder, color: Colors.black),
              title: const Text('Projects'),
              onTap: () {
                // Close the drawer and navigate to Manage Projects screen
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ManageProjectsScreen()),
                ).then((_) => _loadData()); // Reload data after returning
              },
            ),
            ListTile(
              leading: const Icon(Icons.list, color: Colors.black),
              title: const Text('Tasks'),
              onTap: () {
                // Close the drawer and navigate to Manage Tasks screen
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ManageTasksScreen()),
                ).then((_) => _loadData()); // Reload data after returning
              },
            ),
            ListTile(
              leading: const Icon(Icons.report, color: Colors.black),
              title: const Text('Local Storage Report'),
              onTap: () {
                // Close the drawer and navigate to Local Storage Report screen
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LocalStorageReportScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Tabs
          Container(
            color: const Color(0xFF4A8C7B), // Same teal color for the tab bar
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTab("All Entries", isAllEntriesSelected, () {
                  setState(() {
                    isAllEntriesSelected = true;
                  });
                }),
                _buildTab("Grouped by Projects", !isAllEntriesSelected, () {
                  setState(() {
                    isAllEntriesSelected = false;
                  });
                }),
              ],
            ),
          ),
          // Main content
          Expanded(
            child: isAllEntriesSelected
                ? _buildAllEntriesView()
                : _buildGroupedByProjectsView(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to Manage Tasks screen when FAB is pressed
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ManageTasksScreen()),
          ).then((_) => _loadData()); // Reload data after returning
        },
        backgroundColor: Colors.orange, // Orange color for the FAB
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // Helper method to build tabs
  Widget _buildTab(String title, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                height: 2,
                width: 50,
                color: Colors.orange, // Orange underline for the selected tab
              ),
          ],
        ),
      ),
    );
  }

  // View for "All Entries" tab with swipe-to-delete
  Widget _buildAllEntriesView() {
    if (timeEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.hourglass_empty, // Hourglass icon
              size: 50,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              "No time entries yet!",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Tap the + button to add your first entry.",
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: timeEntries.length,
      itemBuilder: (context, index) {
        final entry = timeEntries[index];
        return Dismissible(
          key: Key(entry.hashCode.toString()), // Unique key for each entry
          direction: DismissDirection.endToStart, // Swipe from right to left
          onDismissed: (direction) {
            _deleteTimeEntry(index); // Delete the entry when dismissed
          },
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: const Icon(
              Icons.delete,
              color: Colors.white,
              size: 30,
            ),
          ),
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: ListTile(
              title: Text('Project: ${entry.project}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Task: ${entry.task}'),
                  Text('Date: ${DateFormat('yyyy-MM-dd').format(entry.date)}'),
                  Text('Hours: ${entry.hours}'),
                  Text('Description: ${entry.description.isEmpty ? "No description" : entry.description}'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // View for "Grouped by Projects" tab
  Widget _buildGroupedByProjectsView() {
    if (projects.isEmpty) {
      return const Center(
        child: Text(
          "No projects found.",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        return ListTile(
          title: Text(project),
          onTap: () {
            // Navigate to Add Time Entry screen when a project is clicked
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddTimeEntryScreen(selectedProject: project),
              ),
            ).then((_) => _loadData()); // Reload data after returning
          },
        );
      },
    );
  }
}

// Manage Tasks Screen
class ManageTasksScreen extends StatefulWidget {
  const ManageTasksScreen({super.key});

  @override
  _ManageTasksScreenState createState() => _ManageTasksScreenState();
}

class _ManageTasksScreenState extends State<ManageTasksScreen> {
  // List of tasks (loaded from shared_preferences)
  static List<String> tasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  // Load tasks from shared_preferences
  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      tasks = prefs.getStringList('tasks') ?? ['Task A', 'Task B', 'Task C'];
    });
  }

  // Save tasks to shared_preferences
  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('tasks', tasks);
  }

  // Function to show the Add Task dialog
  void _showAddTaskDialog() {
    final TextEditingController taskController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          title: const Text('Add Task'),
          content: TextField(
            controller: taskController,
            decoration: const InputDecoration(
              labelText: 'Task Name',
              border: UnderlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Close the dialog without adding the task
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Add the task to the list and save to shared_preferences
                if (taskController.text.isNotEmpty) {
                  setState(() {
                    tasks.add(taskController.text);
                    _saveTasks();
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  // Function to delete a task
  void _deleteTask(int index) {
    setState(() {
      tasks.removeAt(index);
      _saveTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A3C8C), // Purple color for the header
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Navigate back to the previous screen
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Manage Tasks',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: tasks.isEmpty
          ? const Center(
              child: Text(
                "No tasks found.",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            )
          : ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(tasks[index]),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteTask(index),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog, // Show the dialog when FAB is pressed
        backgroundColor: Colors.orange, // Orange color for the FAB
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// Manage Projects Screen
class ManageProjectsScreen extends StatefulWidget {
  const ManageProjectsScreen({super.key});

  @override
  _ManageProjectsScreenState createState() => _ManageProjectsScreenState();
}

class _ManageProjectsScreenState extends State<ManageProjectsScreen> {
  // List of projects (loaded from shared_preferences)
  static List<String> projects = [];

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  // Load projects from shared_preferences
  Future<void> _loadProjects() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      projects = prefs.getStringList('projects') ?? ['Project X', 'Project Y', 'Project Z'];
    });
  }

  // Save projects to shared_preferences
  Future<void> _saveProjects() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('projects', projects);
  }

  // Function to show the Add Project dialog
  void _showAddProjectDialog() {
    final TextEditingController projectController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          title: const Text('Add Project'),
          content: TextField(
            controller: projectController,
            decoration: const InputDecoration(
              labelText: 'Project Name',
              border: UnderlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Close the dialog without adding the project
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Add the project to the list and save to shared_preferences
                if (projectController.text.isNotEmpty) {
                  setState(() {
                    projects.add(projectController.text);
                    _saveProjects();
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  // Function to delete a project
  void _deleteProject(int index) {
    setState(() {
      projects.removeAt(index);
      _saveProjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A3C8C), // Purple color for the header
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Navigate back to the previous screen
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Manage Projects',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: projects.isEmpty
          ? const Center(
              child: Text(
                "No projects found.",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            )
          : ListView.builder(
              itemCount: projects.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(projects[index]),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteProject(index),
                  ),
                  onTap: () {
                    // Navigate to Add Time Entry screen when a project is clicked
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddTimeEntryScreen(selectedProject: projects[index]),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProjectDialog, // Show the dialog when FAB is pressed
        backgroundColor: Colors.orange, // Orange color for the FAB
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// Add Time Entry Screen
class AddTimeEntryScreen extends StatefulWidget {
  final String selectedProject;

  const AddTimeEntryScreen({super.key, required this.selectedProject});

  @override
  _AddTimeEntryScreenState createState() => _AddTimeEntryScreenState();
}

class _AddTimeEntryScreenState extends State<AddTimeEntryScreen> {
  String? selectedProject;
  String? selectedTask;
  DateTime selectedDate = DateTime.now();
  final TextEditingController timeController = TextEditingController(text: '1');
  final TextEditingController descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedProject = widget.selectedProject;
    selectedTask = _ManageTasksScreenState.tasks.isNotEmpty ? _ManageTasksScreenState.tasks[0] : null;
  }

  // Function to show the date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  // Save time entry to shared_preferences
  Future<void> _saveTimeEntry() async {
    if (selectedProject == null || selectedTask == null || timeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return; // Don't save if required fields are missing
    }

    final prefs = await SharedPreferences.getInstance();
    List<String> timeEntries = prefs.getStringList('timeEntries') ?? [];

    final timeEntry = TimeEntry(
      project: selectedProject!,
      task: selectedTask!,
      date: selectedDate,
      hours: double.parse(timeController.text),
      description: descriptionController.text,
    );

    timeEntries.add(jsonEncode(timeEntry.toJson()));
    await prefs.setStringList('timeEntries', timeEntries);

    // Show a confirmation message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Time entry saved successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A8C7B), // Teal color for the header
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Navigate back to the previous screen
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Add Time Entry',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project Dropdown
            const Text(
              'Project',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            DropdownButton<String>(
              value: selectedProject,
              isExpanded: true,
              items: _ManageProjectsScreenState.projects.map((String project) {
                return DropdownMenuItem<String>(
                  value: project,
                  child: Text(project),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedProject = newValue;
                });
              },
            ),
            const SizedBox(height: 16),

            // Task Dropdown
            const Text(
              'Task',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            DropdownButton<String>(
              value: selectedTask,
              isExpanded: true,
              items: _ManageTasksScreenState.tasks.map((String task) {
                return DropdownMenuItem<String>(
                  value: task,
                  child: Text(task),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedTask = newValue;
                });
              },
            ),
            const SizedBox(height: 16),

            // Date Picker
            const Text(
              'Date',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Text(
                  'Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: () => _selectDate(context),
                  child: const Text(
                    'Select Date',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Total Time
            const Text(
              'Total Time (in hours)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: timeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: UnderlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            const Text(
              'Description',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                border: UnderlineInputBorder(),
                hintText: 'Enter a description of the work',
              ),
            ),
            const SizedBox(height: 32),

            // Save Time Entry Button
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  await _saveTimeEntry();
                  Navigator.pop(context); // Navigate back to the home screen
                },
                child: const Text('Save Time Entry'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Local Storage Report Screen
class LocalStorageReportScreen extends StatefulWidget {
  const LocalStorageReportScreen({super.key});

  @override
  _LocalStorageReportScreenState createState() => _LocalStorageReportScreenState();
}

class _LocalStorageReportScreenState extends State<LocalStorageReportScreen> {
  List<String> projects = [];
  List<String> tasks = [];
  List<TimeEntry> timeEntries = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Load all data from shared_preferences
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      projects = prefs.getStringList('projects') ?? [];
      tasks = prefs.getStringList('tasks') ?? [];
      final timeEntriesJson = prefs.getStringList('timeEntries') ?? [];
      timeEntries = timeEntriesJson
          .map((json) => TimeEntry.fromJson(jsonDecode(json)))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A3C8C), // Purple color for the header
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Navigate back to the previous screen
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Local Storage Report',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Projects Section
            const Text(
              'Projects',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            projects.isEmpty
                ? const Text('No projects found.')
                : Column(
                    children: projects
                        .map((project) => Text(
                              '- $project',
                              style: const TextStyle(fontSize: 16),
                            ))
                        .toList(),
                  ),
            const SizedBox(height: 16),

            // Tasks Section
            const Text(
              'Tasks',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            tasks.isEmpty
                ? const Text('No tasks found.')
                : Column(
                    children: tasks
                        .map((task) => Text(
                              '- $task',
                              style: const TextStyle(fontSize: 16),
                            ))
                        .toList(),
                  ),
            const SizedBox(height: 16),

            // Time Entries Section
            const Text(
              'Time Entries',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            timeEntries.isEmpty
                ? const Text('No time entries found.')
                : Column(
                    children: timeEntries.asMap().entries.map((entry) {
                      final index = entry.key;
                      final timeEntry = entry.value;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Entry ${index + 1}',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text('Project: ${timeEntry.project}'),
                              Text('Task: ${timeEntry.task}'),
                              Text(
                                  'Date: ${DateFormat('yyyy-MM-dd').format(timeEntry.date)}'),
                              Text('Hours: ${timeEntry.hours}'),
                              Text('Description: ${timeEntry.description.isEmpty ? "No description" : timeEntry.description}'),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }
}