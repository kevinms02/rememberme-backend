import 'package:flutter/material.dart';
import 'dart:io';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const RememberMEApp());
}

class RememberMEApp extends StatelessWidget {
  const RememberMEApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RememberME',
      theme: ThemeData(
        primaryColor: const Color(0xFF00BFFF),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

// Ganti semua URL API ke IP lokal
const String apiBaseUrl = 'http://192.168.100.193:3000';

// Models
class Memory {
  final String id;
  final String title;
  final List<String> photos;
  final String date;
  final String notes;
  final DateTime createdAt;

  Memory({
    required this.id,
    required this.title,
    required this.photos,
    required this.date,
    required this.notes,
    required this.createdAt,
  });
}

class User {
  final String name;
  final String email;
  final String username;
  String? profilePic;

  User({
    required this.name,
    required this.email,
    required this.username,
    this.profilePic,
  });
}

// Global state management (simplified)
class AppState {
  static User? currentUser;
  static List<Memory> memories = [];
  static int selectedNavIndex = 0;
  static String? userId; // simpan userId MongoDB
}

// Login Page
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _loginError;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00BFFF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'RememberME',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Login',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 60),
              _buildTextField('Insert your username here', _emailController),
              const SizedBox(height: 16),
              _buildTextField('Insert your password here', _passwordController, isPassword: true),
              if (_loginError != null) ...[
                const SizedBox(height: 8),
                Text(_loginError!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF00BFFF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BFFF)),
                        )
                      : const Text(
                          'Login',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignUpPage()),
                  );
                },
                child: const Text(
                  'Sign up',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller, {bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Future<void> _login() async {
    setState(() {
      _loginError = null;
      _loading = true;
    });
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _loginError = 'Username dan password wajib diisi!';
        _loading = false;
      });
      return;
    }
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _emailController.text,
          'password': _passwordController.text,
        }),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = data['user'];
        AppState.currentUser = User(
          name: user['name'],
          email: user['email'],
          username: user['username'],
          profilePic: user['profilePic'],
        );
        AppState.userId = user['_id']; // simpan userId
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
      } else {
        setState(() {
          _loginError = 'Login gagal: ${jsonDecode(response.body)['message'] ?? ''}';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loginError = 'Tidak dapat terhubung ke server: $e';
      });
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
    });
  }
}

// Sign Up Page
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _signUpError;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00BFFF)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Text(
                'RememberME',
                style: TextStyle(
                  color: Color(0xFF00BFFF),
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Sign up',
                style: TextStyle(
                  color: Color(0xFF00BFFF),
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 40),
              _buildTextField('Insert your name here', _nameController),
              const SizedBox(height: 16),
              _buildTextField('Insert your email here', _emailController),
              const SizedBox(height: 16),
              _buildTextField('Insert your password here', _passwordController, isPassword: true),
              const SizedBox(height: 16),
              _buildTextField('Confirm your password here', _confirmPasswordController, isPassword: true),
              if (_signUpError != null) ...[
                const SizedBox(height: 8),
                Text(_signUpError!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BFFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : const Text(
                          'Sign up',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller, {bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF00BFFF)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Future<void> _signUp() async {
    setState(() {
      _signUpError = null;
      _loading = true;
    });
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty || _confirmPasswordController.text.isEmpty) {
      setState(() {
        _signUpError = 'Semua field wajib diisi!';
        _loading = false;
      });
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _signUpError = 'Password dan konfirmasi tidak sama!';
        _loading = false;
      });
      return;
    }
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _nameController.text,
          'email': _emailController.text,
          'username': _emailController.text,
          'password': _passwordController.text,
        }),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sign up berhasil! Silakan login.')));
      } else {
        setState(() {
          _signUpError = jsonDecode(response.body)['message'] ?? 'Sign up gagal';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _signUpError = 'Tidak dapat terhubung ke server: $e';
      });
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
    });
  }
}

// Main Navigation
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const MemoriesVaultPage(),
    const CreateMemoriesPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF00BFFF),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(Icons.folder, 0),
            _buildNavItem(Icons.add_circle, 1),
            _buildNavItem(Icons.person, 2),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    return GestureDetector(
      onTap: () async {
        if (index == 1) {
          // NFC scan sebelum ke form
          NdefMessage? ndefMessage;
          await NfcManager.instance.startSession(onDiscovered: (tag) async {
            final ndef = Ndef.from(tag);
            if (ndef == null) {
              NfcManager.instance.stopSession(errorMessage: 'Tag tidak mendukung NDEF');
              return;
            }
            ndefMessage = ndef.cachedMessage;
            NfcManager.instance.stopSession();
          });
          if (!mounted) return;
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateMemoriesPage(
                ndefMessage: ndefMessage,
              ),
            ),
          );
        } else {
          setState(() => _selectedIndex = index);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Icon(
          icon,
          color: _selectedIndex == index ? Colors.white : Colors.white70,
          size: 28,
        ),
      ),
    );
  }
}

// Memories Vault Page
class MemoriesVaultPage extends StatefulWidget {
  const MemoriesVaultPage({super.key});

  @override
  State<MemoriesVaultPage> createState() => _MemoriesVaultPageState();
}

class _MemoriesVaultPageState extends State<MemoriesVaultPage> {
  final _searchController = TextEditingController();
  String _sortBy = 'Date';
  bool _loading = false;
  List<Memory> _memories = [];

  @override
  void initState() {
    super.initState();
    _fetchMemories();
  }

  Future<void> _fetchMemories() async {
    setState(() => _loading = true);
    try {
      final user = AppState.currentUser;
      if (user == null) return;
      final response = await http.get(Uri.parse('$apiBaseUrl/api/memories/${AppState.userId!}'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _memories = (data['memories'] as List).map((m) => Memory(
          id: m['_id'],
          title: m['title'],
          photos: List<String>.from(m['photos'] ?? []),
          date: m['date'] ?? '',
          notes: m['notes'] ?? '',
          createdAt: DateTime.parse(m['createdAt']),
        )).toList();
        setState(() {});
      }
    } catch (e) {
      // ignore error
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00BFFF),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'RememberME',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Search your memories',
                              prefixIcon: Icon(Icons.search, color: Color(0xFF00BFFF)),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.sort, color: Color(0xFF00BFFF)),
                          onPressed: _showSortOptions,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _memories.isEmpty
                        ? const Center(
                            child: Text(
                              'No memories yet.\nCreate your first memory!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _getSortedMemories().length,
                            itemBuilder: (context, index) {
                              final memory = _getSortedMemories()[index];
                              return GestureDetector(
                                onTap: () => _showFullMemoryDialog(memory),
                                child: _buildMemoryCard(memory),
                              );
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. Tampilkan foto user pada card jika ada
  Widget _buildMemoryCard(Memory memory) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(128, 128, 128, 0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (memory.photos.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.file(
                File(memory.photos[0]),
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 150,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, size: 50, color: Colors.grey),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  memory.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  memory.date,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                if (memory.notes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    memory.notes,
                    style: const TextStyle(fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFullMemoryDialog(Memory memory) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Back button di kiri atas
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                ],
              ),
              // Isi card
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      memory.title,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(memory.date, style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    if (memory.photos.isNotEmpty)
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: memory.photos.length,
                          itemBuilder: (context, idx) {
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: 100,
                              child: Image.file(
                                File(memory.photos[idx]),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image, size: 50, color: Colors.grey),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(memory.notes),
                  ],
                ),
              ),
              // Tombol di bawah
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () async {
                      await _deleteMemory(memory.id);
                      Navigator.pop(context);
                    },
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text('Update'),
                    onPressed: () async {
                      Navigator.pop(context);
                      if (!mounted) return;
                      final updated = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateMemoriesPage(
                            memory: memory,
                          ),
                        ),
                      );
                      if (!mounted) return;
                      if (updated != null && updated is Memory) {
                        await _updateMemory(updated);
                        _fetchMemories();
                        _showMessage('Memory updated!');
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteMemory(String id) async {
    await http.delete(Uri.parse('$apiBaseUrl/api/memories/$id'));
    _fetchMemories();
  }

  Future<void> _updateMemory(Memory memory) async {
    await http.put(
      Uri.parse('$apiBaseUrl/api/memories/${memory.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': memory.title,
        'photos': memory.photos,
        'date': memory.date,
        'notes': memory.notes,
      }),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Sort by',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Title (A-Z)'),
                onTap: () => _setSortBy('Title A-Z'),
              ),
              ListTile(
                title: const Text('Title (Z-A)'),
                onTap: () => _setSortBy('Title Z-A'),
              ),
              ListTile(
                title: const Text('Date (Newest)'),
                onTap: () => _setSortBy('Date Newest'),
              ),
              ListTile(
                title: const Text('Date (Oldest)'),
                onTap: () => _setSortBy('Date Oldest'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _setSortBy(String sortBy) {
    setState(() => _sortBy = sortBy);
    Navigator.pop(context);
  }

  List<Memory> _getSortedMemories() {
    List<Memory> memories = List.from(_memories);
    switch (_sortBy) {
      case 'Title A-Z':
        memories.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'Title Z-A':
        memories.sort((a, b) => b.title.compareTo(a.title));
        break;
      case 'Date Newest':
        memories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'Date Oldest':
        memories.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
    }
    return memories;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class CreateMemoriesPage extends StatefulWidget {
  final Memory? memory;
  final NdefMessage? ndefMessage;
  const CreateMemoriesPage({super.key, this.memory, this.ndefMessage});

  @override
  State<CreateMemoriesPage> createState() => _CreateMemoriesPageState();
}

class _CreateMemoriesPageState extends State<CreateMemoriesPage> {
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  late TextEditingController _dateController;
  List<String> _mediaPaths = [];
  final ImagePicker _picker = ImagePicker();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.memory?.title ?? '');
    _notesController = TextEditingController(text: widget.memory?.notes ?? '');
    _dateController = TextEditingController(text: widget.memory?.date ?? '');
    _mediaPaths = widget.memory?.photos ?? [];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.memory != null;
    final ndefMessage = widget.ndefMessage;
    bool tagKosong = ndefMessage == null || ndefMessage.records.isEmpty;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Memory' : 'Create Memory')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (!tagKosong)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.nfc, color: Colors.orange),
                          SizedBox(width: 8),
                          Expanded(child: Text('Tag NFC sudah ada isinya.')),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit NFC'),
                            onPressed: _writeToNfc,
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.delete),
                            label: const Text('Hapus NFC'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            onPressed: _clearNfc,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              if (tagKosong)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.yellow[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.nfc, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(child: Text('Tempelkan tag NFC kosong untuk menulis memori baru.')),
                    ],
                  ),
                ),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 16),
              // Placeholder upload foto/video
              Row(
                children: [
                  ..._mediaPaths.take(3).map((path) => Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey[200],
                            ),
                            child: path.endsWith('.mp4')
                                ? const Icon(Icons.videocam, size: 40, color: Colors.grey)
                                : Image.file(
                                    File(path),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, size: 40, color: Colors.grey),
                                  ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _mediaPaths.remove(path);
                              });
                            },
                            child: const CircleAvatar(
                              radius: 10,
                              backgroundColor: Colors.red,
                              child: Icon(Icons.close, size: 14, color: Colors.white),
                            ),
                          ),
                        ],
                      )),
                  if (_mediaPaths.length < 3)
                    GestureDetector(
                      onTap: _pickMedia,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[300],
                        ),
                        child: const Icon(Icons.add_a_photo, color: Colors.grey, size: 32),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _dateController,
                decoration: const InputDecoration(labelText: 'Date'),
                onTap: () async {
                  FocusScope.of(context).requestFocus(FocusNode());
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    _dateController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                  }
                },
                readOnly: true,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _loading ? null : () => _saveMemory(isEdit),
                child: _loading
                    ? const CircularProgressIndicator()
                    : Text(isEdit ? 'Update' : 'Create'),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.nfc),
                label: const Text('Tulis ke NFC Tag'),
                onPressed: _writeToNfc,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveMemory(bool isEdit) async {
    setState(() => _loading = true);
    final userId = AppState.userId;
    if (userId == null) return;
    if (isEdit) {
      await http.put(
        Uri.parse('$apiBaseUrl/api/memories/${widget.memory!.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': _titleController.text,
          'photos': _mediaPaths,
          'date': _dateController.text,
          'notes': _notesController.text,
        }),
      );
    } else {
      await http.post(
        Uri.parse('$apiBaseUrl/api/memories'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'title': _titleController.text,
          'photos': _mediaPaths,
          'date': _dateController.text,
          'notes': _notesController.text,
        }),
      );
    }
    setState(() => _loading = false);
    Navigator.pop(context, true);
  }

  Future<void> _writeToNfc() async {
    final url = 'https://rememberme.app/memory?title=${Uri.encodeComponent(_titleController.text)}&date=${Uri.encodeComponent(_dateController.text)}&notes=${Uri.encodeComponent(_notesController.text)}';
    try {
      await NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
        final ndef = Ndef.from(tag);
        if (ndef == null) {
          NfcManager.instance.stopSession(errorMessage: 'Tag tidak mendukung NDEF');
          return;
        }
        await ndef.write(NdefMessage([
          NdefRecord.createUri(Uri.parse(url)),
        ]));
        NfcManager.instance.stopSession();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Berhasil menulis ke NFC Tag!')),
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menulis ke NFC Tag: $e')),
        );
      }
    }
  }

  Future<void> _pickMedia() async {
    if (_mediaPaths.length >= 3) return;
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text('Pilih Foto'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
                  if (picked != null) {
                    setState(() {
                      _mediaPaths.add(picked.path);
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam),
                title: const Text('Pilih Video (max 10MB)'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? picked = await _picker.pickVideo(source: ImageSource.gallery);
                  if (picked != null) {
                    final file = File(picked.path);
                    final bytes = await file.length();
                    if (bytes > 10 * 1024 * 1024) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ukuran video melebihi 10MB!')),);
                      }
                      return;
                    }
                    setState(() {
                      _mediaPaths.add(picked.path);
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _clearNfc() async {
    try {
      await NfcManager.instance.startSession(onDiscovered: (tag) async {
        final ndef = Ndef.from(tag);
        if (ndef == null) {
          NfcManager.instance.stopSession(errorMessage: 'Tag tidak mendukung NDEF');
          return;
        }
        await ndef.write(NdefMessage([]));
        NfcManager.instance.stopSession();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Isi NFC berhasil dihapus!')),
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus isi NFC: $e')),
        );
      }
    }
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _usernameController;
  String? _profilePic;
  final ImagePicker _picker = ImagePicker();
  String? _profileError;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final user = AppState.currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _usernameController = TextEditingController(text: user?.username ?? '');
    _profilePic = user?.profilePic;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickProfilePic,
              child: CircleAvatar(
                radius: 48,
                backgroundImage: _profilePic != null ? FileImage(File(_profilePic!)) : null,
                child: _profilePic == null ? const Icon(Icons.person, size: 48, color: Colors.grey) : null,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            if (_profileError != null) ...[
              const SizedBox(height: 8),
              Text(_profileError!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _saveProfile,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Simpan Profile'),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Logout'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    setState(() {
      _profileError = null;
      _loading = true;
    });
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _usernameController.text.isEmpty) {
      setState(() {
        _profileError = 'Semua field wajib diisi!';
        _loading = false;
      });
      return;
    }
    try {
      final userId = AppState.userId;
      if (userId == null) throw Exception('User ID not found');
      final response = await http.put(
        Uri.parse('$apiBaseUrl/api/user/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _nameController.text,
          'email': _emailController.text,
          'username': _usernameController.text,
          'profilePic': _profilePic,
        }),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final user = jsonDecode(response.body)['user'];
        setState(() {
          AppState.currentUser = User(
            name: user['name'],
            email: user['email'],
            username: user['username'],
            profilePic: user['profilePic'],
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile disimpan!')));
      } else {
        setState(() {
          _profileError = 'Gagal update profile';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _profileError = 'Tidak dapat terhubung ke server: $e';
      });
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
    });
  }

  void _logout() {
    AppState.currentUser = null;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _pickProfilePic() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _profilePic = picked.path;
      });
    }
  }
}