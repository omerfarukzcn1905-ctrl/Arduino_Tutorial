import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:universal_html/html.dart' as html;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'design_system.dart';

// API User Data Manager - communicates with Node.js backend
class UserDataManager {
  static final UserDataManager _instance = UserDataManager._internal();

  /// Default API URL used when no override is provided.
  static const String _defaultApiUrl = 'http://localhost:3000/api';

  /// Use this to override the API URL at build-time.
  ///
  /// Example: `flutter run --dart-define=API_URL=http://192.168.0.5:3000/api`
  static const String _envApiUrl = String.fromEnvironment('API_URL');

  bool _isInitialized = false;

  String get _apiUrl {
    // Explicit override (set via --dart-define=API_URL=...)
    if (_envApiUrl.isNotEmpty) {
      return _envApiUrl;
    }

    // On web, prefer a relative path so the app works when hosted on the same origin.
    // This makes deployment much easier (no need to hardcode backend host).
    if (kIsWeb) {
      return '/api';
    }

    // Use emulator-friendly addresses when running on mobile emulators.
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Android emulator maps 10.0.2.2 to host machine's localhost.
      return 'http://10.0.2.2:3000/api';
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // iOS simulator can reach host machine on localhost.
      return 'http://localhost:3000/api';
    }

    // For other platforms (desktop), assume backend runs locally on port 3000.
    return _defaultApiUrl;
  }

  factory UserDataManager() {
    return _instance;
  }

  UserDataManager._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Test connection to backend
      final response = await http.get(
        Uri.parse('$_apiUrl/health'),
      ).timeout(Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        print('✅ Connected to backend API at $_apiUrl');
      } else {
        print('⚠️ Backend responded with status ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error connecting to backend: $e');
      print('Make sure the Node.js server is running on port 3000');
    }
    
    _isInitialized = true;
  }

  /// Returns `null` when successful, otherwise returns an error message.
  Future<String?> registerUser(String username, String password) async {
    try {
      print('📝 Registering user: $username');
      
      final response = await http.post(
        Uri.parse('$_apiUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      ).timeout(Duration(seconds: 10));

      // Try to parse response body (may not always be JSON)
      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = null;
      }

      if (response.statusCode == 201) {
        print('✅ Registration successful');
        return null;
      }

      final message = (data is Map && data['message'] is String)
          ? data['message']
          : 'Registration failed with status ${response.statusCode}';

      print('❌ Registration failed: $message');
      return message;
    } catch (e) {
      print('❌ Error during registration: $e');
      return 'Unable to reach server. Please check your connection.';
    }
  }

  /// Returns `null` when successful, otherwise returns an error message.
  Future<String?> loginUser(String username, String password) async {
    try {
      print('🔐 Logging in user: $username');
      
      final response = await http.post(
        Uri.parse('$_apiUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      ).timeout(Duration(seconds: 10));

      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = null;
      }

      if (response.statusCode == 200 && data is Map && data['success'] == true) {
        print('✅ Login successful');
        return null;
      }

      final message = (data is Map && data['message'] is String)
          ? data['message']
          : 'Login failed with status ${response.statusCode}';

      print('❌ Login failed: $message');
      return message;
    } catch (e) {
      print('❌ Error during login: $e');
      return 'Unable to reach server. Please check your connection.';
    }
  }

  Future<bool> userExists(String username) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiUrl/user/$username'),
      ).timeout(Duration(seconds: 5));

      final data = jsonDecode(response.body);
      return data['exists'] ?? false;
    } catch (e) {
      print('Error checking if user exists: $e');
      return false;
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await UserDataManager().initialize();
  runApp(MyApp());
}
class MyApp extends StatefulWidget {
  const MyApp({super.key});


  @override
  State<MyApp> createState() => _MyAppState();
}
class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;
  
  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arduino & ESP 32 Tutorials',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      home: LoginPage(onToogleTheme: _toggleTheme),
    );
  }
}

class LoginPage extends StatefulWidget {
  final VoidCallback onToogleTheme;
  const LoginPage({super.key, required this.onToogleTheme});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final UserDataManager _userManager = UserDataManager();
  String _errorMessage = '';

  void _login() async {
    String username = _usernameController.text.trim();
    String password = _passwordController.text;

    // Simple validation
    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter both username and password';
      });
      return;
    }

    // Check if user exists and password matches
    final loginError = await _userManager.loginUser(username, password);
    if (loginError == null) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Welcome back, $username!')),
      );
      // Navigate to home page
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => CustomBlockPage(onToogleTheme: widget.onToogleTheme),
        ),
      );
    } else {
      if (!mounted) return;
      setState(() {
        _errorMessage = loginError;
      });
    }
  }

  void _navigateToRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RegisterPage(onToogleTheme: widget.onToogleTheme),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login', style: AppTypography.heading3.copyWith(color: AppColors.white)),
        actions: [
          IconButton(
            icon: Icon(Icons.brightness_6),
            tooltip: 'Thema wechseln',
            onPressed: widget.onToogleTheme,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Arduino & ESP 32 Tutorials',
              style: AppTypography.heading2.copyWith(color: AppColors.primaryCyan),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.xxl),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
              ),
              obscureText: true,
            ),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.lg),
                child: Text(
                  _errorMessage,
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.accentRed),
                ),
              ),
            SizedBox(height: AppSpacing.xxl),
            GradientButton(
              label: 'Login',
              onPressed: _login,
            ),
            SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Don\'t have an account? ', style: AppTypography.bodyMedium),
                TextButton(
                  onPressed: _navigateToRegister,
                  child: Text('Register here', style: AppTypography.bodyMedium.copyWith(color: AppColors.primaryCyan)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class RegisterPage extends StatefulWidget {
  final VoidCallback onToogleTheme;
  const RegisterPage({super.key, required this.onToogleTheme});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final UserDataManager _userManager = UserDataManager();
  String _errorMessage = '';
  String _successMessage = '';

  void _register() async {
    String username = _usernameController.text.trim();
    String password = _passwordController.text;
    String confirmPassword = _confirmPasswordController.text;

    // Validation
    if (username.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill all fields';
        _successMessage = '';
      });
      return;
    }

    if (password.length < 4) {
      setState(() {
        _errorMessage = 'Password must be at least 4 characters long';
        _successMessage = '';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _errorMessage = 'Passwords do not match';
        _successMessage = '';
      });
      return;
    }

    // Check if user exists
    final exists = await _userManager.userExists(username);
    if (exists) {
      setState(() {
        _errorMessage = 'Username already exists';
        _successMessage = '';
      });
      return;
    }

    // Register user
    print('Registering user: $username');
    final registerError = await _userManager.registerUser(username, password);
    print('Registration error: $registerError');
    
    if (registerError == null) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '';
        _successMessage = 'Registration successful! You can now log in.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration successful!')),
      );
      
      // Navigate back to login after 2 seconds
      Future.delayed(Duration(seconds: 2), () {
        if (!mounted) return;
        Navigator.of(context).pop();
      });
    } else {
      if (!mounted) return;
      setState(() {
        _errorMessage = registerError;
        _successMessage = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register'),
        actions: [
          IconButton(
            icon: Icon(Icons.brightness_6),
            tooltip: 'Thema wechseln',
            onPressed: widget.onToogleTheme,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Create New Account',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            if (_successMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  _successMessage,
                  style: TextStyle(color: Colors.green),
                ),
              ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: _register,
              child: Text('Register'),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Already have an account? '),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Log in'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}

class CustomBlockPage extends StatefulWidget {
  final VoidCallback onToogleTheme;
  const CustomBlockPage({super.key, required this.onToogleTheme});
  @override
  _CustomBlockPageState createState() => _CustomBlockPageState();
}

class _CustomBlockPageState extends State<CustomBlockPage> {
  bool isSidebarVisible = true;
  List<BlockModel> setupBlocks = [];
  List<BlockModel> loopBlocks = [];
  List<PinDefinition> pinDefinitions = [];
  String generatedCode = '';
  List<String> includes = [];
  bool servosDefined = false;

  final List<BlockTypeModel> availableBlocks = [
    // Definition Blocks
    BlockTypeModel('Define Input Pin', 'define_input', Icons.input, Colors.orange),
    BlockTypeModel('Define Output Pin', 'define_output', Icons.output, Colors.orange),


    // Setup Blocks
    BlockTypeModel('Setup Serial', 'setup_serial', Icons.settings_input_component, Colors.blue),
    BlockTypeModel('Setup Pin Mode', 'setup_pinmode', Icons.toys, Colors.blue),
    BlockTypeModel('Braccio Begin', 'braccio_begin', Icons.play_arrow, Colors.blue),

    // Loop Blocks
    BlockTypeModel('If Schleife', 'if', Icons.loop, Colors.green),
    BlockTypeModel('While Schleife', 'while', Icons.sync, Colors.green),
    BlockTypeModel('For Schleife', 'for', Icons.repeat, Colors.green),
    BlockTypeModel('Digital Write', 'digital_write', Icons.toggle_on, Colors.purple),
    BlockTypeModel('Analog Write', 'analog_write', Icons.tune, Colors.purple),
    BlockTypeModel('Braccio Movement', 'braccio_movement', Icons.directions_run, Colors.red),
    BlockTypeModel('Set Red LED', 'red', Icons.color_lens, Colors.red),
    BlockTypeModel('Set Green LED', 'green', Icons.color_lens, Colors.green),
    BlockTypeModel('Set Blue LED', 'blue', Icons.color_lens, Colors.blue),
    BlockTypeModel('Delay(ms)', 'delay', Icons.timer, Colors.amber),
    BlockTypeModel('Print Message', 'print', Icons.print, Colors.cyan),
    BlockTypeModel('End Block', 'end_block', Icons.stop, Colors.grey),    
  ];

  void addInclude(String type) {
    setState(() {
      if (!includes.contains(type)) {
        includes.add(type);
      }
    });
    generateCode();
  }

  void addBlock(BlockTypeModel blockType, {String? customValue, bool isSetup = true}) {
    setState(() {
      if (isSetup) {
        setupBlocks.add(BlockModel(
          type: blockType.type, 
          name : blockType.name,
          icon: blockType.icon, 
          color: blockType.color,
          customValue: customValue
        ));
      } else {
        loopBlocks.add(BlockModel(
          type: blockType.type,
          name : blockType.name,
          icon: blockType.icon, 
          color: blockType.color,
          customValue: customValue
        ));
      }
    });
    generateCode(); 
  }

  void addPinDefinition(String type, String name, int pinNumber) {
    setState(() {
      pinDefinitions.add(PinDefinition(type, name, pinNumber));
    });
    generateCode();
  }

  void _showPinModeDialog() {
    final pinController = TextEditingController();
    String selectedMode = 'INPUT';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Configure Pin Mode'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: pinController,
                decoration: InputDecoration(labelText: 'Custom Pin Name (e.g., button1Pin)'),
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedMode,
                decoration: InputDecoration(labelText: 'Select Mode'),
                items: ['INPUT', 'OUTPUT', 'INPUT_PULLUP'].map((mode) {
                  return DropdownMenuItem<String>(
                    value: mode,
                    child: Text(mode),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedMode = value!;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final pinName = pinController.text.isNotEmpty ? pinController.text : 'defaultPin';
                addBlock(
                  availableBlocks.firstWhere((b) => b.type == 'setup_pinmode'),
                  customValue: '$pinName,$selectedMode',
                  isSetup: true,
                );
                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showPrintDialog({required bool isSetup}) {
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Print Message'),
          content: TextField(
            controller: messageController,
            decoration: InputDecoration(hintText: 'Enter your message', border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (messageController.text.isNotEmpty) {
                  addBlock(
                    availableBlocks.firstWhere((b) => b.type == 'print'),
                    customValue: messageController.text,
                    isSetup: isSetup,
                  );
                }
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );  
  }

  void _showIfDialog({required String blockType, required bool isSetup}) {
    final conditionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('If Bediungung'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Bedingung eingeben z.B. digitalRead(buttonPin) == HIGH',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: conditionController,
                  decoration: InputDecoration(
                    labelText: 'Bedingung Eingeben',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 8),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (conditionController.text.isNotEmpty) {
                  addBlock(
                    availableBlocks.firstWhere((b) => b.type == blockType),
                    customValue: conditionController.text,
                    isSetup: isSetup,
                  );
                  Navigator.pop(context);
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showForDialog({required bool isSetup}) {
    final initializationController = TextEditingController();
    final conditionController = TextEditingController();
    final incrementController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('For Loop'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: initializationController,
                  decoration: InputDecoration(labelText: 'Initialisierung (z.B., int i = 0)'),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: conditionController,
                  decoration: InputDecoration(labelText: 'Bedingung (z.B., i < 10)'),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: incrementController,
                  decoration: InputDecoration(labelText: 'Inkrement (z.B., i++)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (initializationController.text.isNotEmpty &&
                    conditionController.text.isNotEmpty &&
                    incrementController.text.isNotEmpty) {
                  String forLoopValue =
                      '${initializationController.text}; ${conditionController.text}; ${incrementController.text}';
                  addBlock(
                    availableBlocks.firstWhere((b) => b.type == 'for'),
                    customValue: forLoopValue,
                    isSetup: isSetup,
                  );
                  Navigator.pop(context);
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showWhileDialog({required bool isSetup}) {
    final conditionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('While Schleife'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Bedingung eingeben z.B. digitalRead(buttonPin) == HIGH',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: conditionController,
                  decoration: InputDecoration(
                    labelText: 'Bedingung Eingeben',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 8),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (conditionController.text.isNotEmpty) {
                  addBlock(
                    availableBlocks.firstWhere((b) => b.type == 'while'),
                    customValue: conditionController.text,
                    isSetup: isSetup,
                  );
                  Navigator.pop(context);
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showDelayDialog({required bool isSetup}) {
    int selectedDelay = 100;

    List<int> delayOptions = [
      for (int i = 100; i <= 10000; i += 100) i
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delay'),
          content: DropdownButtonFormField<int>(
            initialValue: selectedDelay,
            decoration: InputDecoration(labelText: 'Delay (ms)'),
            items: delayOptions.map((value) {
              return DropdownMenuItem<int>(
                value: value,
                child: Text('$value ms'),
              );
            }).toList(),
            onChanged: (value) {
              selectedDelay = value!;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                addBlock(
                  availableBlocks.firstWhere((b) => b.type == 'delay'),
                  customValue: selectedDelay.toString(),
                  isSetup: isSetup,
                );
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showDigitalWriteDialog({required bool isSetup}) {
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Digital Write'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Code eingeben z.B. digitalWrite(ledPin, HIGH)',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: codeController,
                  decoration: InputDecoration(
                    labelText: 'Code eingeben',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 8),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (codeController.text.isNotEmpty) {
                  addBlock(
                    availableBlocks.firstWhere((b) => b.type == 'digital_write'),
                    customValue: codeController.text,
                    isSetup: isSetup,
                  );
                  Navigator.pop(context);
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showAnalogWriteDialog({required bool isSetup}) {
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Analog Write'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Code eingeben z.B. analogWrite(ledPin, 128)',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: codeController,
                  decoration: InputDecoration(
                    labelText: 'Code eingeben',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 8),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (codeController.text.isNotEmpty) {
                  addBlock(
                    availableBlocks.firstWhere((b) => b.type == 'analog_write'),
                    customValue: codeController.text,
                    isSetup: isSetup,
                  );
                  Navigator.pop(context);
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void generateCode() {
    String code = '';

    for (var inc in includes) {
      if (inc == 'include_braccio') {
        code += '#include <Braccio.h>\n';
      }
      if (inc == 'include_servo') {
        code += '#include <Servo.h>\n';
      }
      if (inc == 'include_arduino') {
        code += '#include <Arduino.h>\n';
      }
    }
    code += '\n';

    // Servos Definition
    if (servosDefined) {
      code += 'Servo base;\n';
      code += 'Servo shoulder;\n';
      code += 'Servo elbow;\n';
      code += 'Servo wrist_ver;\n';
      code += 'Servo wrist_rot;\n';
      code += 'Servo gripper;\n';
    }

    // Pin Definitions
    for (var pin in pinDefinitions) {
      code += 'const int ${pin.name} = ${pin.pinNumber};\n';
    }

    // Setup Function
    code += '\nvoid setup() {\n';
    code += _generateCodeForBlocks(setupBlocks);
    code += '}\n\n';

    // Loop Function
    code += 'void loop() {\n';
    code += _generateCodeForBlocks(loopBlocks);
    code += '}\n';

    setState(() {
      generatedCode = code;
    });
  }

  String _generateCodeForBlocks(List<BlockModel> blocks) {
    String code = '';
    bool inConditionalBlock = false;

    for (var block in blocks) {
      if (block.type == 'end_block') {
        inConditionalBlock = false;
        code += '}\n';
        continue;
      }

      if (block.type.startsWith('if') ||
          block.type.startsWith('while') ||
          block.type.startsWith('for')) {
        inConditionalBlock = true;
        code += '${_getBlockCode(block)} {\n';
        continue;
      }

      code += '  ';
      if (inConditionalBlock) code += '  ';
      code += '${_getBlockCode(block)}\n';
    }
    return code;
  }

  void _removeBlock(bool isSetup, int index) {
    setState(() {
      if (isSetup) {
        setupBlocks.removeAt(index);
      } else {
        loopBlocks.removeAt(index);
      }
    });
    generateCode();
  }

  String _getBlockCode(BlockModel block) {
    switch (block.type) {
      case 'if':
        final condition = block.customValue ?? 'digitalRead(pin) == HIGH';
        return 'if ($condition)';
      case 'setup_serial':
        return 'Serial.begin(9600);';
      case 'setup_pinmode':
        final parts = block.customValue?.split(',') ?? ['<pin>', 'INPUT'];
        return 'pinMode(${parts[0]}, ${parts[1]});';
      case 'braccio_begin':
        return 'Braccio.begin();';
      case 'end_block':
        return '}';
      case 'while':
        return 'while (${block.customValue})';
      case 'for':
        return 'for (${block.customValue})';
      case 'digital_write':
        final cmd = block.customValue ?? 'digitalWrite(pin, HIGH);';
        return cmd;
      case 'analog_write':
         final cmd = block.customValue ?? 'analogWrite(pin, 128);';
        return cmd;
      case 'braccio_movement':
        return 'Braccio.ServoMovement(${block.customValue});';
      case 'include_braccio':
        return '#include <Braccio.h>';
      case 'include_servo':
        return '#include <Servo.h>';
      case 'red':
        return 'analogWrite(redPin, 255);';
      case 'green':
        return 'analogWrite(greenPin, 255);';
      case 'blue':
        return 'analogWrite(bluePin, 255);';
      case 'delay':
        final delayValue = block.customValue ?? '1000';
        return 'delay($delayValue);';
      case 'print':
        final message = block.customValue ?? 'Hello, World!';
        return 'Serial.println("$message");';
      default:
        return '//Action not defined';
    }
  }

  void _showPinDefinitionDialog(bool isInput) {
    final nameController = TextEditingController();
    final pinController = TextEditingController();

    showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        title: Text('Define ${isInput ? 'Input' : 'Output'} Pin'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Pin Name (e.g., button1Pin)'),
              ),
              SizedBox(height: 8),
              TextField(
                controller: pinController,
                decoration: InputDecoration(labelText: 'Pin Number (e.g., 13)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && pinController.text.isNotEmpty) {
                addPinDefinition(
                  isInput ? 'INPUT' : 'OUTPUT',
                  nameController.text,
                  int.tryParse(pinController.text) ?? 2
                );
                Navigator.pop(context);
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showServoMotors() {
    setState(() {
      servosDefined = true;
    });
    generateCode();
  }

  void _showServoMovementDialog({required bool isSetup}) {
    final baseController = TextEditingController();
    final shoulderController = TextEditingController();
    final elbowController = TextEditingController();
    final wristVerController = TextEditingController();
    final wristRotController = TextEditingController();
    final gripperController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Braccio ServoMovement'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: baseController,
                decoration: InputDecoration(labelText: 'Base Angle (0-180)'),
              ),
              SizedBox(height: 8),
              TextField(
                controller: shoulderController,
                decoration: InputDecoration(labelText: 'Shoulder Angle (0-180)'),
              ),
              SizedBox(height: 8),
              TextField(
                controller: elbowController,
                decoration: InputDecoration(labelText: 'Elbow Angle (0-180)'),
              ),
              SizedBox(height: 8),
              TextField(
                controller: wristVerController,
                decoration: InputDecoration(labelText: 'Wrist Vertical Angle (0-180)'),
              ),
              SizedBox(height: 8),
              TextField(
                controller: wristRotController,
                decoration: InputDecoration(labelText: 'Wrist Rotation Angle (0-180)'),
              ),
              SizedBox(height: 8),
              TextField(
                controller: gripperController,
                decoration: InputDecoration(labelText: 'Gripper Angle (0-180)'),
              ),
            ],          ),
        ),        
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final values = [
                baseController.text,
                shoulderController.text,
                elbowController.text,
                wristVerController.text,
                wristRotController.text,
                gripperController.text, 
              ];
              if (values.every((v) => v.isNotEmpty)) {
                addBlock(
                  availableBlocks.firstWhere((b) => b.type == 'braccio_movement'),
                  customValue: values.join(', '),
                  isSetup: isSetup,
                );
                Navigator.pop(context);
              }
            },
            child: Text('Save'),
          ),
        ],
      ), 
    );
  }

  void _downloadCode(BuildContext context, String code) async {
    final controller = TextEditingController(text: "sketch.ino");
    String? fileName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Dateiname eingeben'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'Dateiname'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text('Herunterladen'), 
          ),
        ],
      ),
    );
    if (fileName != null && fileName.isNotEmpty) {
      final bytes = utf8.encode(code);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
      
      html.Url.revokeObjectUrl(url);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Arduino & ESP32 Programmierung Tutorials'),
        actions: [
          IconButton(
            icon: Icon(Icons.brightness_6),
            tooltip: 'Thema wechseln',
            onPressed: widget.onToogleTheme,
          ),
          IconButton(
            icon: Icon(isSidebarVisible ? Icons.arrow_back : Icons.arrow_forward),
            tooltip: isSidebarVisible ? 'Seitenleiste schließen' : 'Seitenleiste öffnen',
            onPressed: () {
              setState(() {
                isSidebarVisible = !isSidebarVisible;
              });
            },
          ),
          // Beispiel Seite
          IconButton(
            icon: Icon(Icons.code),
            tooltip: 'Beispiel Codes Anzeigen',
            onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => ExampleCodesPage()),
              );
            },
          ),
          // Delete für Blocks-Button
          IconButton(
            icon: Icon(Icons.delete),
            tooltip: 'Alle Blöcke löschen',
            onPressed: () {
              setState(() {
                setupBlocks.clear();
                loopBlocks.clear();
                pinDefinitions.clear();
                includes.clear();
                servosDefined = false;
                generatedCode = '';
              });
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // Block Palette
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: isSidebarVisible ? 220 : 0,
            child: isSidebarVisible ? _buildBlockPalette() : null,
          ),

          // Setup Workspace
          Expanded(
            child: DragTarget<BlockTypeModel>(
              onAcceptWithDetails: (details) {
                final block = details.data;
                if (block.type == 'setup_pinmode') {
                  _showPinModeDialog();
                } else if (block.type == 'if') {
                  _showIfDialog(blockType: block.type, isSetup: true);
                } else if (block.type == 'for') {
                  _showForDialog(isSetup: true);
                } else if (block.type == 'while') {
                  _showWhileDialog(isSetup: true);
                } else if (block.type == 'print') {
                  _showPrintDialog(isSetup: true);
                } else if (block.type == 'digital_write') {
                  _showDigitalWriteDialog(isSetup: true);
                } else if (block.type == 'analog_write') {
                  _showAnalogWriteDialog(isSetup: true);
                } else if (block.type == 'delay') {
                  _showDelayDialog(isSetup: true);
                } else if (block.type == 'braccio_movement') {
                  _showServoMovementDialog(isSetup: true);
                } else if (!block.type.startsWith('define_')) {
                  addBlock(block, isSetup: true);
                }
              },
              builder: (context, candidateData, rejectedData) {
                return Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Setup Blocks',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Expanded(
                        child: setupBlocks.isEmpty
                            ? _buildEmptyState('Ziehen Sie Setup Blöcke hierher')
                            : ReorderableListView(
                              onReorder: (oldIndex, newIndex) {
                                setState(() {
                                  if (newIndex > oldIndex) newIndex--;
                                  final BlockModel item = setupBlocks.removeAt(oldIndex);
                                  setupBlocks.insert(newIndex, item);
                                });
                                generateCode();
                              },
                              children: [
                                for (int i = 0; i < setupBlocks.length; i++)
                                  _buildWorkspaceBlock(setupBlocks[i], i, true),
                              ],
                            ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Loop Workspace
          Expanded(
            child: DragTarget<BlockTypeModel>(
              onAcceptWithDetails: (details) {
                final block = details.data;
                if (block.type == 'print') {
                  _showPrintDialog(isSetup: false);
                } else if (block.type == 'if') {
                  _showIfDialog(blockType: block.type, isSetup: false);
                } else if (block.type == 'for') {
                  _showForDialog(isSetup: false);
                } else if (block.type == 'while') {
                  _showWhileDialog(isSetup: false);
                } else if (block.type == 'digital_write') {
                  _showDigitalWriteDialog(isSetup: false);
                } else if (block.type == 'analog_write') {
                  _showAnalogWriteDialog(isSetup: false);
                } else if (block.type == 'delay') {
                  _showDelayDialog(isSetup: false);
                } else if (block.type == 'braccio_movement') {
                  _showServoMovementDialog(isSetup: false);
                } else {
                  addBlock(block, isSetup: false);
                }
              },
              builder: (context, candidateData, rejectedData) {
                return Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Loop Blocks',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Expanded(
                        child: loopBlocks.isEmpty
                            ? _buildEmptyState('Ziehen Sie Loop Blöcke hierher')
                            : ReorderableListView(
                              onReorder: (oldIndex, newIndex) {
                                setState(() {
                                  if (newIndex > oldIndex) newIndex--;
                                  final BlockModel item = loopBlocks.removeAt(oldIndex);
                                  loopBlocks.insert(newIndex, item);
                                });
                                generateCode();
                              },
                              children: [
                                for (int i = 0; i < loopBlocks.length; i++)
                                  _buildWorkspaceBlock(loopBlocks[i], i, false),
                              ],
                            ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Code Preview
          Container(
            width: 350,
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Generierter Code',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          
                          // Copy Button
                          IconButton(
                            icon: Icon(Icons.copy),
                            tooltip: 'Code kopieren',
                            onPressed: () {
                              if (generatedCode.isNotEmpty) {
                                Clipboard.setData(ClipboardData(text: generatedCode));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Code in die Zwischenablage kopiert')),
                                );
                              }
                            },
                          ),

                          // Delete Button
                          IconButton(
                            icon: Icon(Icons.delete),
                            tooltip: 'Code löschen',
                            onPressed: () {
                              setState(() {
                                generatedCode = '';
                                pinDefinitions.clear();
                                includes.clear();
                                servosDefined = false;
                              });
                            },
                          ),

                          // Download Button
                          IconButton(
                            icon: Icon(Icons.download),
                            tooltip: 'Code herunterladen',
                            onPressed: () {
                              final code = generatedCode.isNotEmpty ? generatedCode : '// Ihr Code wird hier generiert';
                              _downloadCode(context, code);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: SelectableText(
                      generatedCode.isNotEmpty ? generatedCode : '// Ihr Code wird hier generiert',
                      style: TextStyle(fontFamily: 'Roboto Mono', fontSize: 14),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'So verwendest du den generierten Code:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '1. Klicke auf "Kopieren".\n'
                        '2. Öffne den Arduino IDE.\n'
                        '3. Füge den Code mit STRG+V ein.\n'
                        '4. Wähle das richtige Board und den Port aus.\n'
                        '5. Lade das Programm auf dein Arduino/ESP32 hoch.'
                      ),                      
                    ],                    
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspaceBlock(BlockModel block, int index, bool isSetup)  {
    return Dismissible(
      key: Key('${block.type}-$index-${block.customValue}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.error,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        _removeBlock(isSetup, index);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${block.name} gelöscht")),
        );
      },
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 4),
        color: block.color,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: ListTile(
            leading: Icon(block.icon, color: Theme.of(context).colorScheme.onPrimary),
            title: Text(block.name, style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
            trailing: block.customValue != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        block.customValue!,
                        style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                      ),
                      IconButton(
                        icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.onPrimary),
                        onPressed: () {
                        // Open the appropriate dialog based on block type
                        },
                      ),
                    ],
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.drag_handle, size: 48, color: Colors.grey),
          SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockPalette() {
    return Container(
      width: 220,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ListView(
        padding: EdgeInsets.all(8),
        children: [
          // Bibliotheken
          _buildCategoryTitle('Bibliotheken'),
          _buildIncludeItem(
            BlockTypeModel('Arduino Bibliothek', 'include_arduino', Icons.memory, Colors.teal)
          ),
          _buildIncludeItem(
            BlockTypeModel('Servo Bibliothek', 'include_servo', Icons.memory, Colors.teal)
          ),
          _buildIncludeItem(
            BlockTypeModel('Braccio Bibliothek', 'include_braccio', Icons.memory, Colors.teal)
          ),

          // Definitionen
          _buildCategoryTitle('Definitionen'),
          _buildPinDefinitionItem(
            BlockTypeModel('Eingangs-Pin', 'define_input', Icons.input, Colors.orange)
          ),
          _buildPinDefinitionItem(
            BlockTypeModel('Ausgangs-Pin', 'define_output', Icons.output, Colors.orange)
          ),
          _buildPinDefinitionItem(
            BlockTypeModel('Servomotoren', 'define_servos', Icons.settings_remote, Colors.orange)
          ),

          // Setup Blöcke
          _buildCategoryTitle('Blöcke'),
          _buildPinDefinitionItem(
            BlockTypeModel('Pin-Modus setzen', 'setup_pinmode', Icons.pin_drop, Colors.blue),
          ),
          _buildBlockItem(
            BlockTypeModel('Serielle-Kommunikation', 'setup_serial', Icons.usb, Colors.blue),
          ),
          ...availableBlocks.where((b) => 
              !b.type.startsWith('define_') && 
              !b.type.startsWith('setup_'))
              .map((block) => _buildBlockItem(block)),
        ],
      ),
    );
  }

  Widget _buildIncludeItem(BlockTypeModel block) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        color: block.color,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            addInclude(block.type);
          },
          child: Container(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(block.icon, color: Theme.of(context).colorScheme.onPrimary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    block.name,
                    style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPinDefinitionItem(BlockTypeModel block) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        color: block.color,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            if (block.type == 'define_input') {
              _showPinDefinitionDialog(true);
            } else if (block.type == 'define_output') {
              _showPinDefinitionDialog(false);
            } else if (block.type == 'define_servos') {
              _showServoMotors();
            } else if (block.type == 'setup_pinmode') {
              _showPinModeDialog();
            }
          },
          child: Container(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(block.icon, color: Theme.of(context).colorScheme.onPrimary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    block.name,
                    style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTitle(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Text(
        title,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildBlockItem(BlockTypeModel block) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        color: block.color,
        borderRadius: BorderRadius.circular(8),
        child: Draggable<BlockTypeModel>(
          data: block,
          feedback: Material(
            child: Container(
              width: 200,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: block.color,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(block.icon, color: Theme.of(context).colorScheme.onPrimary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      block.name,
                      style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          childWhenDragging: Container(),
          child: Container(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(block.icon, color: Theme.of(context).colorScheme.onPrimary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    block.name,
                    style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

class BlockTypeModel {
  final String name;
  final String type;
  final IconData icon;
  final Color color;
  final bool isScopeBlock;

  BlockTypeModel(this.name, this.type, this.icon, [this.color = const Color(0xFF9C27B0), this.isScopeBlock = false]);
}

class BlockModel {
  final String name;
  final String type;
  final IconData icon;
  final Color color;
  final String? customValue;

  BlockModel({
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
    this.customValue
  });

  BlockModel copyWith({String? customValue}) {
    return BlockModel(
      name: name,
      type: type,
      icon: icon,
      color: color,
      customValue: customValue ?? this.customValue,
    );
  }
}

class PinDefinition {
  final String type; // 'INPUT' or 'OUTPUT'
  final String name;
  final int pinNumber;

  PinDefinition(this.type, this.name, this.pinNumber);
}
class ExampleCodesPage extends StatelessWidget {
  final Map<String, IconData> iconMap = {
    'LED': Icons.lightbulb,
    'Button': Icons.radio_button_checked,
    'Servo Motor': Icons.settings_remote,
    'Braccio Robotic Arm': Icons.precision_manufacturing,
    'Ultrasonic Sensor': Icons.sensors,
  };

  final List<Map<String, String>> examples = [
    {
      'category': 'Default',
      'title': 'LED Blinken',
      'description': 'Ein einfaches Programm, um eine LED blinken zu lassen.',
      'code': '''
void setup() {
  Serial.begin(9600);
  pinMode(ledPin, OUTPUT);
}
void loop() {
  digitalWrite(ledPin, HIGH);
  delay(1000);
  digitalWrite(ledPin, LOW);
  delay(1000);
}
''',
    },
    {
      'category': 'Default',
      'title': 'Button Steuerung',
      'description': 'Steuere eine LED mit einem Taster.',
      'code': '''
void setup() {
  pinMode(buttonPin, INPUT);
  pinMode(ledPin, OUTPUT);
  Serial.begin(9600);
}
void loop() {
  if (digitalRead(buttonPin) == HIGH) {
    digitalWrite(ledPin, HIGH);
    Serial.println("LED AN");
  } else {
    digitalWrite(ledPin, LOW);
    Serial.println("LED AUS");
  }
  delay(200);
}
''',
    },
    {
      'category': 'Digital Write',
      'title': 'Digital Write - LED mit Verzögerung',
      'description': 'Schreibe digitale Werte und steuere LEDs mit verschiedenen Verzögerungen.',
      'code': '''
int redPin = 2;
int greenPin = 3;
int bluePin = 4;

void setup() {
  pinMode(redPin, OUTPUT);
  pinMode(greenPin, OUTPUT);
  pinMode(bluePin, OUTPUT);
  Serial.begin(9600);
}

void loop() {
  // Rote LED
  digitalWrite(redPin, HIGH);
  Serial.println("Rot: AN");
  delay(1000);
  digitalWrite(redPin, LOW);
  delay(500);
  
  // Grüne LED
  digitalWrite(greenPin, HIGH);
  Serial.println("Grün: AN");
  delay(1000);
  digitalWrite(greenPin, LOW);
  delay(500);
  
  // Blaue LED
  digitalWrite(bluePin, HIGH);
  Serial.println("Blau: AN");
  delay(1000);
  digitalWrite(bluePin, LOW);
  delay(500);
}
''',
    },
    {
      'category': 'Advanced',
      'title': 'Button mit If-Bedingung und Counter',
      'description': 'Zähle Button-Drücke und kontrolliere mehrere LEDs.',
      'code': '''
int buttonPin = 5;
int ledPin1 = 6;
int ledPin2 = 7;
int counter = 0;

void setup() {
  pinMode(buttonPin, INPUT);
  pinMode(ledPin1, OUTPUT);
  pinMode(ledPin2, OUTPUT);
  Serial.begin(9600);
}

void loop() {
  if (digitalRead(buttonPin) == HIGH) {
    counter++;
    Serial.print("Button Presses: ");
    Serial.println(counter);
    delay(500);
    
    if (counter % 2 == 0) {
      digitalWrite(ledPin1, HIGH);
      digitalWrite(ledPin2, LOW);
    } else {
      digitalWrite(ledPin1, LOW);
      digitalWrite(ledPin2, HIGH);
    }
  }
}
''',
    },
    {
      'category': 'Advanced',
      'title': 'For Schleife mit Pulsweitenmodulation',
      'description': 'Nutze For-Schleifen um LEDs mit PWM zu dimmen.',
      'code': '''
int ledPin = 9;
int buttonPin = 5;

void setup() {
  pinMode(ledPin, OUTPUT);
  pinMode(buttonPin, INPUT);
  Serial.begin(9600);
}

void loop() {
  if (digitalRead(buttonPin) == HIGH) {
    // Helligkeit erhöhen
    for (int brightness = 0; brightness <= 255; brightness += 5) {
      analogWrite(ledPin, brightness);
      delay(50);
      Serial.print("Helligkeit: ");
      Serial.println(brightness);
    }
    
    delay(500);
    
    // Helligkeit senken
    for (int brightness = 255; brightness >= 0; brightness -= 5) {
      analogWrite(ledPin, brightness);
      delay(50);
    }
    
    delay(1000);
  }
}
''',
    },
    {
      'category': 'Advanced',
      'title': 'Mehrere Sensoren mit Analog Write',
      'description': 'Lese mehrere Sensoren und steuere LEDs mit Analog Write.',
      'code': '''
int potPin = A0;
int ledPin = 9;
int buttonPin = 5;
int sensorValue = 0;
int ledBrightness = 0;

void setup() {
  pinMode(ledPin, OUTPUT);
  pinMode(buttonPin, INPUT);
  Serial.begin(9600);
}

void loop() {
  sensorValue = analogRead(potPin);
  ledBrightness = map(sensorValue, 0, 1023, 0, 255);
  
  Serial.print("Sensor: ");
  Serial.print(sensorValue);
  Serial.print(" -> LED: ");
  Serial.println(ledBrightness);
  
  if (digitalRead(buttonPin) == HIGH) {
    analogWrite(ledPin, ledBrightness);
  } else {
    analogWrite(ledPin, 0);
  }
  
  delay(100);
}
''',
    },
  ];

  ExampleCodesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Beispiel Codes', style: AppTypography.heading3.copyWith(color: AppColors.white)),
        elevation: 0,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(AppSpacing.md),
        itemCount: examples.length,
        itemBuilder: (context, index) {
          final example = examples[index];
          final categoryColor = _getCategoryColor(example['category']!);
          
          return Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: GlassCard(
              gradientStart: categoryColor,
              gradientEnd: AppColors.darkGrey,
              padding: EdgeInsets.zero,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (context) => ExampleDetailPage(
                        title: example['title']!,
                        code: example['code']!,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: Icon(
                          _getCategoryIcon(example['category']!),
                          color: categoryColor,
                          size: AppSpacing.iconLg,
                        ),
                      ),
                      SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedBadge(
                              label: example['category']!,
                              color: categoryColor,
                            ),
                            SizedBox(height: AppSpacing.sm),
                            Text(
                              example['title']!,
                              style: AppTypography.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.white,
                              ),
                            ),
                            SizedBox(height: AppSpacing.xs),
                            Text(
                              example['description']!,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.mediumGrey,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward, color: AppColors.primaryCyan),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Digital Write':
        return AppColors.accentGreen;
      case 'Advanced':
        return AppColors.accentOrange;
      case 'Expert':
        return AppColors.accentRed;
      default:
        return AppColors.primaryCyan;
    }
  }
  
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Digital Write':
        return Icons.electric_bolt;
      case 'Advanced':
        return Icons.settings;
      case 'Expert':
        return Icons.science;
      default:
        return Icons.code;
    }
  }
}

// Example Detail Page with Copy Button
class ExampleDetailPage extends StatefulWidget {
  final String title;
  final String code;

  const ExampleDetailPage({
    super.key,
    required this.title,
    required this.code,
  });

  @override
  State<ExampleDetailPage> createState() => _ExampleDetailPageState();
}

class _ExampleDetailPageState extends State<ExampleDetailPage> {
  bool _copied = false;

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: widget.code));
    setState(() {
      _copied = true;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Code kopiert!', style: AppTypography.bodyMedium.copyWith(color: AppColors.white)),
        backgroundColor: AppColors.accentGreen,
        duration: Duration(seconds: 2),
      ),
    );
    
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _copied = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: AppTypography.heading3.copyWith(color: AppColors.white)),
        elevation: 0,
        actions: [
          GestureDetector(
            onTap: _copyCode,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: _copied ? AppColors.accentGreen : AppColors.primaryCyan,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _copied ? Icons.check : Icons.content_copy,
                    color: AppColors.primaryDark,
                    size: AppSpacing.iconMd,
                  ),
                  SizedBox(width: AppSpacing.xs),
                  Text(
                    _copied ? 'Kopiert!' : 'Kopieren',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: GlassCard(
          gradientStart: AppColors.primaryBlue,
          gradientEnd: AppColors.primaryPurple,
          padding: EdgeInsets.all(AppSpacing.lg),
          child: SelectableText(
            widget.code,
            style: AppTypography.codeMono.copyWith(
              color: AppColors.primaryCyan,
              height: 1.6,
            ),
          ),
        ),
      ),
    );
  }
}

