import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const String serviceKey = '08255e4a7faa9ff0a64db77d7c15f7b661f78ade570c59806690af625c023496';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyA7sieL4pBpcNP3tLoWMCwZZbdoF3wE2-w",
      authDomain: "holiday-memo-4d955.firebaseapp.com",
      projectId: "holiday-memo-4d955",
      storageBucket: "holiday-memo-4d955.firebasestorage.app",
      messagingSenderId: "615818058223",
      appId: "1:615818058223:web:ca592a0394f84c46d83e1a",
    ),
  );

  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: AuthGate(),
  ));
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          return const HolidayMemoPage();
        }
        return const LoginPage();
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoginMode = true;
  bool isLoading = false;
  String? errorMsg;

  Future<void> submitAuth() async {
    setState(() {
      isLoading = true;
      errorMsg = null;
    });
    try {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();

      if (isLoginMode) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMsg = e.message ?? '인증 오류가 발생했습니다.';
      });
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('한국 공휴일 메모장 - 로그인'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_month, size: 56, color: Colors.indigo),
                  const SizedBox(height: 12),
                  Text(
                    isLoginMode ? '로그인' : '회원가입',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: '이메일 (예: test@test.com)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: '비밀번호 (6자리 이상)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (errorMsg != null) ...[
                    const SizedBox(height: 12),
                    Text(errorMsg!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: isLoading ? null : submitAuth,
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(isLoginMode ? '로그인' : '회원가입 완료'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        isLoginMode = !isLoginMode;
                        errorMsg = null;
                      });
                    },
                    child: Text(isLoginMode
                        ? '계정이 없으신가요? 회원가입'
                        : '이미 계정이 있으신가요? 로그인'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HolidayMemoPage extends StatefulWidget {
  const HolidayMemoPage({super.key});

  @override
  State<HolidayMemoPage> createState() => _HolidayMemoPageState();
}

class _HolidayMemoPageState extends State<HolidayMemoPage> {
  String selectedYear = '2026';
  String selectedMonth = '05';
  List holidays = [];
  bool isLoading = false;
  String? errorMessage;

  final List<String> years = ['2024', '2025', '2026', '2027'];
  final List<String> months = [
    '01', '02', '03', '04', '05', '06',
    '07', '08', '09', '10', '11', '12'
  ];

  @override
  void initState() {
    super.initState();
    fetchHolidays();
  }

  Future<void> fetchHolidays() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final url = Uri.parse(
        'https://apis.data.go.kr/B090041/openapi/service/SpcdeInfoService/getRestDeInfo'
        '?serviceKey=$serviceKey&solYear=$selectedYear&solMonth=$selectedMonth&_type=json',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final items = decoded['response']['body']['items'];

        if (items == '' || items == null || items['item'] == null) {
          setState(() {
            holidays = [];
            isLoading = false;
          });
          return;
        }

        final rawItem = items['item'];
        final List itemList = rawItem is List ? rawItem : [rawItem];

        setState(() {
          holidays = itemList;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'API 호출 실패 (상태코드: ${response.statusCode})';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = '오류 발생: $e';
        isLoading = false;
      });
    }
  }

  void showAddMemoDialog(String dateStr, String holidayName) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$holidayName ($dateStr) 한 줄 메모'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '일정이나 메모를 입력하세요'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('memos')
                    .add({
                  'date': dateStr,
                  'holidayName': holidayName,
                  'memo': text,
                  'createdAt': FieldValue.serverTimestamp(),
                });
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? 'guest';

    return Scaffold(
      appBar: AppBar(
        title: const Text('한국 공휴일 달력 & 나만의 한 줄 메모장'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Text(user?.email ?? '', style: const TextStyle(fontSize: 13)),
            ),
          ),
          IconButton(
            tooltip: '로그아웃',
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DropdownButton<String>(
                  value: selectedYear,
                  items: years
                      .map((y) => DropdownMenuItem(value: y, child: Text('$y년')))
                      .toList(),
                  onChanged: (val) => setState(() => selectedYear = val!),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: selectedMonth,
                  items: months
                      .map((m) => DropdownMenuItem(value: m, child: Text('$m월')))
                      .toList(),
                  onChanged: (val) => setState(() => selectedMonth = val!),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: fetchHolidays,
                  icon: const Icon(Icons.search),
                  label: const Text('공휴일 조회'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '공휴일을 클릭하면 한 줄 메모를 저장할 수 있습니다.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Expanded(
              flex: 1,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : errorMessage != null
                      ? Center(child: Text(errorMessage!, style: const TextStyle(color: Colors.red)))
                      : holidays.isEmpty
                          ? const Center(child: Text('해당 월에는 공휴일이 없습니다.'))
                          : ListView.builder(
                              itemCount: holidays.length,
                              itemBuilder: (context, index) {
                                final h = holidays[index];
                                final date = h['locdate'].toString();
                                final name = h['dateName'].toString();
                                return Card(
                                  child: ListTile(
                                    leading: const Icon(Icons.event, color: Colors.red),
                                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text('날짜: $date'),
                                    trailing: const Icon(Icons.edit_note),
                                    onTap: () => showAddMemoDialog(date, name),
                                  ),
                                );
                              },
                            ),
            ),
            const Divider(thickness: 2),
            const Text(
              '내 저장된 메모 목록 (Firestore)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              flex: 1,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('memos')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(child: Text('저장된 메모가 없습니다.'));
                  }
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      return ListTile(
                        leading: const Icon(Icons.bookmark, color: Colors.indigo),
                        title: Text(data['memo'] ?? ''),
                        subtitle: Text('${data['holidayName']} (${data['date']})'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.grey),
                          onPressed: () => doc.reference.delete(),
                        ),
                      );
                    },
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