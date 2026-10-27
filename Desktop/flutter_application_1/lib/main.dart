import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const ServiceDeskApp());
}

class ServiceDeskApp extends StatelessWidget {
  const ServiceDeskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Service Desk IT-колледжа',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

// ==========================================
// 1. МОДЕЛИ ДАННЫХ И ХРАНИЛИЩЕ
// ==========================================
class UserModel {
  final String fullName;
  final String email;
  final String role; // 'teacher' или 'tech'

  UserModel({required this.fullName, required this.email, required this.role});
}

class TicketModel {
  final String id;
  final String title;
  final String room;
  final String description;
  final String authorName;
  final String? imagePath;
  String status; // 'Новая', 'В работе', 'Решена'
  final DateTime createdAt;

  TicketModel({
    required this.id,
    required this.title,
    required this.room,
    required this.description,
    required this.authorName,
    this.imagePath,
    this.status = 'Новая',
    required this.createdAt,
  });
}

class MockDataService {
  static final List<UserModel> _users = [
    UserModel(fullName: 'Иван Преподаватель', email: 'teacher@college.kz', role: 'teacher'),
    UserModel(fullName: 'Даниэль Техник', email: 'tech@college.kz', role: 'tech'),
  ];

  static UserModel? currentUser;

  static final List<TicketModel> tickets = [
    TicketModel(
      id: '1',
      title: 'Сломан стул',
      room: 'Кабинет 304',
      description: 'У парного стула отвалилась ножка. Сидеть невозможно.',
      authorName: 'Иван Преподаватель',
      imagePath: null,
      status: 'Новая',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  static Future<String?> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      currentUser = _users.firstWhere((u) => u.email == email);
      return null;
    } catch (e) {
      return 'Пользователь не найден!';
    }
  }

  static Future<String?> register(String fullName, String email, String password, String role) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (_users.any((u) => u.email == email)) {
      return 'Пользователь уже существует!';
    }
    final newUser = UserModel(fullName: fullName, email: email, role: role);
    _users.add(newUser);
    currentUser = newUser;
    return null;
  }

  static void addTicket(String title, String room, String description, String? imagePath) {
    final nextId = (tickets.length + 1).toString();
    tickets.insert(
      0,
      TicketModel(
        id: nextId,
        title: title,
        room: room,
        description: description,
        authorName: currentUser?.fullName ?? 'Аноним',
        imagePath: imagePath,
        createdAt: DateTime.now(),
      ),
    );
  }

  static void updateTicketStatus(String id, String newStatus) {
    final ticket = tickets.firstWhere((t) => t.id == id);
    ticket.status = newStatus;
  }
}

// ==========================================
// 2. ЭКРАН ВХОДА (LOGIN)
// ==========================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'teacher@college.kz');
  final _passwordController = TextEditingController(text: '123456');
  bool _isLoading = false;

  void _submitLogin() async {
    setState(() => _isLoading = true);
    final error = await MockDataService.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );
    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    final role = MockDataService.currentUser?.role;
    Widget nextScreen = (role == 'tech') ? const TechHomeScreen() : const UserHomeScreen();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.build_circle, size: 80, color: Colors.deepPurple),
              const SizedBox(height: 12),
              const Text(
                'Service Desk',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text('IT-Колледжа', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email / Логин', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Пароль', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitLogin,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Войти', style: TextStyle(fontSize: 18)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
                },
                child: const Text('Ещё нет аккаунта? Зарегистрироваться'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 3. ЭКРАН РЕГИСТРАЦИИ (REGISTER)
// ==========================================
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'teacher';
  bool _isLoading = false;

  void _submitRegister() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Заполните все поля!')));
      return;
    }

    setState(() => _isLoading = true);
    final error = await MockDataService.register(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text.trim(),
      _selectedRole,
    );
    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      final nextScreen = (_selectedRole == 'tech') ? const TechHomeScreen() : const UserHomeScreen();
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => nextScreen), (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Регистрация')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'ФИО', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person))),
            const SizedBox(height: 16),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email))),
            const SizedBox(height: 16),
            TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Пароль', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock))),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: const InputDecoration(labelText: 'Роль', border: OutlineInputBorder(), prefixIcon: Icon(Icons.badge)),
              items: const [
                DropdownMenuItem(value: 'teacher', child: Text('Преподаватель / Студент')),
                DropdownMenuItem(value: 'tech', child: Text('IT-Техник / Специалист')),
              ],
              onChanged: (val) => setState(() => _selectedRole = val!),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitRegister,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Зарегистрироваться', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 4. ЭКРАН СТУДЕНТА / ПРЕПОДАВАТЕЛЯ (USER)
// ==========================================
class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final _titleController = TextEditingController();
  final _roomController = TextEditingController();
  final _descriptionController = TextEditingController();
  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  void _createTicket() {
    if (_titleController.text.isEmpty || _roomController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Укажите тему и кабинет!')));
      return;
    }

    setState(() {
      MockDataService.addTicket(
        _titleController.text.trim(),
        _roomController.text.trim(),
        _descriptionController.text.trim(),
        _selectedImage?.path,
      );
      _titleController.clear();
      _roomController.clear();
      _descriptionController.clear();
      _selectedImage = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Заявка успешно отправлена!')));
  }

  void _logout() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final myTickets = MockDataService.tickets
        .where((t) => t.authorName == MockDataService.currentUser?.fullName)
        .toList();

    final currentUser = MockDataService.currentUser;
    String roleName = 'Преподаватель / Студент';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(currentUser?.fullName ?? 'Пользователь', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            Text(roleName, style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.exit_to_app), onPressed: _logout, tooltip: 'Выйти'),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Подать заявку на ремонт', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Тема (например, Сломан стул)', border: OutlineInputBorder(), isDense: true)),
                    const SizedBox(height: 10),
                    TextField(controller: _roomController, decoration: const InputDecoration(labelText: 'Кабинет (например, 304)', border: OutlineInputBorder(), isDense: true)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Подробное описание проблемы', border: OutlineInputBorder(), isDense: true),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.add_a_photo),
                      label: Text(_selectedImage == null ? 'Прикрепить фото поломки' : 'Фото прикреплено ✓'),
                    ),
                    if (_selectedImage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(File(_selectedImage!.path), height: 120, fit: BoxFit.cover),
                        ),
                      ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _createTicket,
                      icon: const Icon(Icons.send),
                      label: const Text('Отправить заявку'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Мои отправленные заявки:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            myTickets.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(child: Text('У вас пока нет отправленных заявок.', style: TextStyle(color: Colors.grey))),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: myTickets.length,
                    itemBuilder: (context, index) {
                      final ticket = myTickets[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => TicketDetailScreen(ticket: ticket, isTech: false)),
                            ).then((_) => setState(() {}));
                          },
                          title: Text(ticket.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${ticket.room}\n${ticket.description}'),
                          isThreeLine: true,
                          trailing: _buildStatusChip(ticket.status),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 5. ЭКРАН IT-ТЕХНИКА / СПЕЦИАЛИСТА (TECH)
// ==========================================
class TechHomeScreen extends StatefulWidget {
  const TechHomeScreen({super.key});

  @override
  State<TechHomeScreen> createState() => _TechHomeScreenState();
}

class _TechHomeScreenState extends State<TechHomeScreen> {
  void _logout() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final allTickets = MockDataService.tickets;
    final currentUser = MockDataService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(currentUser?.fullName ?? 'Техник', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const Text('IT-Специалист', style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.exit_to_app), onPressed: _logout, tooltip: 'Выйти'),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Text('Все входящие заявки (${allTickets.length}):', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: allTickets.length,
                itemBuilder: (context, index) {
                  final ticket = allTickets[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => TicketDetailScreen(ticket: ticket, isTech: true)),
                        ).then((_) => setState(() {}));
                      },
                      title: Text(ticket.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Место: ${ticket.room}', style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text('От: ${ticket.authorName}'),
                        ],
                      ),
                      trailing: _buildStatusChip(ticket.status),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 6. ЭКРАН ПОДРОБНОГО ОПИСАНИЯ ЗАЯВКИ
// ==========================================
class TicketDetailScreen extends StatefulWidget {
  final TicketModel ticket;
  final bool isTech;

  const TicketDetailScreen({super.key, required this.ticket, required this.isTech});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Заявка №${widget.ticket.id}'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.ticket.title,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                _buildStatusChip(widget.ticket.status),
              ],
            ),
            const Divider(height: 30),
            _buildDetailRow(Icons.location_on, 'Кабинет:', widget.ticket.room),
            const SizedBox(height: 8),
            _buildDetailRow(Icons.person, 'Автор:', widget.ticket.authorName),
            const SizedBox(height: 8),
            _buildDetailRow(Icons.access_time, 'Время:', '${widget.ticket.createdAt.day}.${widget.ticket.createdAt.month}.${widget.ticket.createdAt.year} ${widget.ticket.createdAt.hour}:${widget.ticket.createdAt.minute.toString().padLeft(2, '0')}'),
            const SizedBox(height: 20),
            const Text('Полное описание неисправности:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                widget.ticket.description.isEmpty ? 'Описание отсутствует.' : widget.ticket.description,
                style: const TextStyle(fontSize: 15, height: 1.4),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Фотография поломки:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (widget.ticket.imagePath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(widget.ticket.imagePath!),
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 150,
                    color: Colors.grey.shade200,
                    child: const Center(child: Text('Ошибка загрузки фото')),
                  ),
                ),
              )
            else
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                    SizedBox(height: 4),
                    Text('Фотография не прикреплена', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            if (widget.isTech) ...[
              const SizedBox(height: 30),
              const Text('Управление статусом (для техника):', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() => MockDataService.updateTicketStatus(widget.ticket.id, 'Новая'));
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                    child: const Text('Новая'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() => MockDataService.updateTicketStatus(widget.ticket.id, 'В работе'));
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                    child: const Text('В работе'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() => MockDataService.updateTicketStatus(widget.ticket.id, 'Решена'));
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    child: const Text('Решена'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.deepPurple),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 6),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 15))),
      ],
    );
  }
}

Widget _buildStatusChip(String status) {
  Color color;
  switch (status) {
    case 'Новая':
      color = Colors.orange;
      break;
    case 'В работе':
      color = Colors.blue;
      break;
    case 'Решена':
      color = Colors.green;
      break;
    default:
      color = Colors.grey;
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color),
    ),
    child: Text(
      status,
      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
    ),
  );
}

