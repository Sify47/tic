// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'add.dart';
import 'services/database_service.dart';
import 'models/football_item.dart';
import 'dart:math';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.initHive();
  runApp(const FootballClashApp());
}

class FootballClashApp extends StatelessWidget {
  const FootballClashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tic Tac Toc',
      theme: ThemeData(primarySwatch: Colors.green, fontFamily: 'Tajawal'),
      home: const FootballClashGame(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class FootballClashGame extends StatefulWidget {
  const FootballClashGame({super.key});

  @override
  FootballClashGameState createState() => FootballClashGameState();
}

class FootballClashGameState extends State<FootballClashGame>
    with TickerProviderStateMixin {
  late List<List<String>> board;
  String currentPlayer = 'الفريق الأحمر';
  String winner = '';
  bool gameOver = false;
  bool gameStarted = false;

  List<FootballItem> footballItems = [];
  List<String> rowLabels = [];
  List<String> colLabels = [];

  // نظام النقاط والإحصائيات
  Map<String, int> scores = {'الفريق الأحمر': 0, 'الفريق الأزرق': 0};
  int draws = 0;
  int totalGames = 0;
  Map<String, int> wins = {'الفريق الأحمر': 0, 'الفريق الأزرق': 0};
  Map<String, int> losses = {'الفريق الأحمر': 0, 'الفريق الأزرق': 0};
  Map<String, int> currentStreak = {'الفريق الأحمر': 0, 'الفريق الأزرق': 0};
  Map<String, int> bestStreak = {'الفريق الأحمر': 0, 'الفريق الأزرق': 0};

  List<String> teamLogos = ['⚽', '🏆', '🔴', '🔵', '⚫', '🟢'];
  Map<String, String> selectedLogos = {
    'الفريق الأحمر': '🔴',
    'الفريق الأزرق': '🔵',
  };
  Map<String, String> teamNames = {
    'الفريق الأحمر': 'الفريق الأحمر',
    'الفريق الأزرق': 'الفريق الأزرق',
  };

  late AnimationController _timerController;
  late Animation<double> _timerAnimation;
  final int _timeLimit = 15;
  // ignore: unused_field
  bool _isTimerRunning = false;

  // للتحكم في التأثيرات
  late AnimationController _effectController;
  List<Offset> _winningCells = [];

  @override
  void initState() {
    super.initState();
    loadData();
    board = List.generate(3, (_) => List.filled(3, ''));
    _initTimer();
    _initEffects();
  }

  void loadData() {
    setState(() {
      footballItems = DatabaseService.getFootballItems();
    });
  }

  void _initTimer() {
    _timerController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _timeLimit),
    );

    _timerAnimation = Tween(begin: 1.0, end: 0.0).animate(_timerController)
      ..addListener(() {
        if (mounted) setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          _handleTimeout();
        }
      });
  }

  void _initEffects() {
    _effectController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  void _startTimer() {
    if (!_timerController.isAnimating && gameStarted) {
      _timerController.reset();
      _timerController.forward();
      _isTimerRunning = true;
    }
  }

  void _stopTimer() {
    if (_timerController.isAnimating) {
      _timerController.stop();
      _isTimerRunning = false;
    }
  }

  void _resetTimer() {
    _stopTimer();
    _timerController.reset();
    if (gameStarted) {
      _startTimer();
    }
  }

  void _handleTimeout() {
    if (!gameOver && mounted) {
      setState(() {
        currentPlayer = currentPlayer == 'الفريق الأحمر'
            ? 'الفريق الأزرق'
            : 'الفريق الأحمر';
        _resetTimer();
      });
      _showTimeoutSnackbar();
    }
  }

  void _showTimeoutSnackbar() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'انتهى وقت ${currentPlayer == 'الفريق الأحمر' ? 'الفريق الأزرق' : 'الفريق الأحمر'}!',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _showWinEffect() {
    _effectController.reset();
    _effectController.forward();
  }

  void startGame() {
    setState(() {
      gameStarted = true;
      _startTimer();
    });
  }

  void resetGame() {
    if (mounted) {
      setState(() {
        final random = Random();
        rowLabels = [];
        colLabels = [];

        // مزج القائمة للحصول على عناصر عشوائية
        List<FootballItem> shuffledItems = List.from(footballItems);
        shuffledItems.shuffle(random);

        for (int i = 0; i < 3; i++) {
          if (i < shuffledItems.length) {
            rowLabels.add(shuffledItems[i].name);
          } else {
            rowLabels.add('Label ${i + 1}');
          }
        }

        // إعادة ترتيب القائمة للحصول على تسميات مختلفة للأعمدة
        shuffledItems.shuffle(random);
        for (int i = 0; i < 3; i++) {
          if (i < shuffledItems.length) {
            colLabels.add(shuffledItems[i].name);
          } else {
            colLabels.add('Label ${i + 1}');
          }
        }
        board = List.generate(3, (_) => List.filled(3, ''));
        currentPlayer = 'الفريق الأحمر';
        winner = '';
        gameOver = false;
        gameStarted = false;
        _winningCells.clear();
        _resetTimer();
      });
    }
  }

  void _updateStatistics() {
    setState(() {
      totalGames++;

      if (winner.isNotEmpty) {
        wins[winner] = wins[winner]! + 1;
        scores[winner] = scores[winner]! + 3; // 3 نقاط للفوز

        // تحديث السلسلة
        currentStreak[winner] = currentStreak[winner]! + 1;
        if (currentStreak[winner]! > bestStreak[winner]!) {
          bestStreak[winner] = currentStreak[winner]!;
        }

        // إعادة تعيين سلسلة الخصم
        String opponent = winner == 'الفريق الأحمر'
            ? 'الفريق الأزرق'
            : 'الفريق الأحمر';
        losses[opponent] = losses[opponent]! + 1;
        currentStreak[opponent] = 0;
      } else {
        // التعادل
        draws++;
        scores['الفريق الأحمر'] = scores['الفريق الأحمر']! + 1;
        scores['الفريق الأزرق'] = scores['الفريق الأزرق']! + 1;
      }
    });
  }

  void selectLogo(String team) {
    _stopTimer();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'اختر شعار لـ ${teamNames[team]}',
          textAlign: TextAlign.center,
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.0,
            ),
            itemCount: teamLogos.length,
            itemBuilder: (context, index) {
              final logo = teamLogos[index];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedLogos[team] = logo;
                  });
                  Navigator.pop(context);
                  if (gameStarted) _startTimer();
                },
                child: Center(
                  child: Text(logo, style: const TextStyle(fontSize: 30)),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void editTeamName(String team) {
    TextEditingController controller = TextEditingController(
      text: teamNames[team],
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تغيير اسم $team', textAlign: TextAlign.center),
        content: TextField(
          controller: controller,
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: 'أدخل اسم الفريق',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  teamNames[team] = controller.text.trim();
                });
                Navigator.pop(context);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void makeMove(int row, int col) {
    if (gameOver) return;

    if (!gameStarted) {
      startGame();
    }

    _stopTimer();

    setState(() {
      if (board[row][col].isEmpty) {
        board[row][col] = currentPlayer;
      } else if (board[row][col] != currentPlayer) {
        board[row][col] = currentPlayer;
      } else {
        _startTimer();
        return;
      }

      if (checkWinner(row, col)) {
        winner = currentPlayer;
        gameOver = true;
        _stopTimer();
        _updateStatistics();
        _showWinEffect();
      } else if (isBoardFull()) {
        gameOver = true;
        _stopTimer();
        _updateStatistics();
      } else {
        currentPlayer = currentPlayer == 'الفريق الأحمر'
            ? 'الفريق الأزرق'
            : 'الفريق الأحمر';
        _startTimer();
      }
    });
  }

  bool checkWinner(int row, int col) {
    // Check row
    if (board[row][0] == currentPlayer &&
        board[row][1] == currentPlayer &&
        board[row][2] == currentPlayer) {
      _winningCells = [
        Offset(row.toDouble(), 0),
        Offset(row.toDouble(), 1),
        Offset(row.toDouble(), 2),
      ];
      return true;
    }

    // Check column
    if (board[0][col] == currentPlayer &&
        board[1][col] == currentPlayer &&
        board[2][col] == currentPlayer) {
      _winningCells = [
        Offset(0, col.toDouble()),
        Offset(1, col.toDouble()),
        Offset(2, col.toDouble()),
      ];
      return true;
    }

    // Check diagonals
    if (row == col &&
        board[0][0] == currentPlayer &&
        board[1][1] == currentPlayer &&
        board[2][2] == currentPlayer) {
      _winningCells = [Offset(0, 0), Offset(1, 1), Offset(2, 2)];
      return true;
    }

    if (row + col == 2 &&
        board[0][2] == currentPlayer &&
        board[1][1] == currentPlayer &&
        board[2][0] == currentPlayer) {
      _winningCells = [Offset(0, 2), Offset(1, 1), Offset(2, 0)];
      return true;
    }

    return false;
  }

  bool isBoardFull() {
    for (var row in board) {
      for (var cell in row) {
        if (cell.isEmpty) {
          return false;
        }
      }
    }
    return true;
  }

  void showStatistics() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('الإحصائيات', textAlign: TextAlign.center),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildTeamStats('الفريق الأحمر'),
                const SizedBox(height: 20),
                _buildTeamStats('الفريق الأزرق'),
                const SizedBox(height: 20),
                Text(
                  'المباريات الإجمالية: $totalGames',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'التعادلات: $draws',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamStats(String team) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: team == 'الفريق الأحمر' ? Colors.red[100] : Colors.blue[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            teamNames[team]!,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: team == 'الفريق الأحمر'
                  ? Colors.red[800]
                  : Colors.blue[800],
            ),
          ),
          const SizedBox(height: 8),
          Text('النقاط: ${scores[team]}'),
          Text('الفوز: ${wins[team]}'),
          Text('الخسارة: ${losses[team]}'),
          Text('السلسلة الحالية: ${currentStreak[team]}'),
          Text('أفضل سلسلة: ${bestStreak[team]}'),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timerController.dispose();
    _effectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'مواجهة الكرة',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Add()),
            );
            loadData();
            resetGame();
          },
          icon: const Icon(Icons.add),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: showStatistics,
            tooltip: 'الإحصائيات',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: resetGame,
            tooltip: 'إعادة اللعبة',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green[800]!, Colors.green[400]!],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!gameStarted)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      'اضغط على أي مربع لبدء اللعبة',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                if (gameStarted) ...[
                  SizedBox(
                    height: 20,
                    width: MediaQuery.of(context).size.width * 0.8,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: _timerAnimation.value,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          currentPlayer == 'الفريق الأحمر'
                              ? Colors.red[800]!
                              : Colors.blue[800]!,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'الوقت المتبقي: ${(_timerAnimation.value * _timeLimit).toInt()} ثانية',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // عرض النقاط
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        '${teamNames['الفريق الأحمر']}: ${scores['الفريق الأحمر']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'التعادلات: $draws',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${teamNames['الفريق الأزرق']}: ${scores['الفريق الأزرق']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // تسميات الأعمدة (colLabels)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 80), // مساحة أكبر للتسميات الجانبية
                      ...List.generate(
                        3,
                        (col) => SizedBox(
                          width: 100, // عرض ثابت لكل عمود
                          child: Center(
                            child: Text(
                              colLabels.isNotEmpty && col < colLabels.length
                                  ? colLabels[col]
                                  : 'العمود ${col + 1}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2, // سطرين كحد أقصى
                              overflow: TextOverflow.visible, // لا يتم قص النص
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // لوحة اللعب مع التسميات الجانبية
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // تسميات الصفوف (rowLabels) - على الجانب الأيسر
                    Container(
                      width: 100, // عرض ثابت للتسميات الجانبية
                      margin: const EdgeInsets.only(
                        top: 20,
                      ), // محاذاة مع منتصف الصف الأول
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          3,
                          (row) => Container(
                            height: 90, // نفس ارتفاع خلية اللعبة
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Center(
                              child: Text(
                                rowLabels.isNotEmpty && row < rowLabels.length
                                    ? rowLabels[row]
                                    : 'الصف ${row + 1}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 3, // ثلاثة أسطر كحد أقصى
                                overflow:
                                    TextOverflow.visible, // لا يتم قص النص
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // لوحة اللعب
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 3),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: List.generate(3, (row) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(3, (col) {
                              bool isWinningCell = _winningCells.contains(
                                Offset(row.toDouble(), col.toDouble()),
                              );

                              return GestureDetector(
                                onTap: () => makeMove(row, col),
                                child: Container(
                                  width: 100, // زيادة العرض
                                  height: 100, // زيادة الارتفاع
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.white),
                                    color: board[row][col].isEmpty
                                        ? Colors.transparent
                                        : board[row][col] == 'الفريق الأحمر'
                                        ? Colors.red.withOpacity(
                                            isWinningCell ? 0.9 : 0.7,
                                          )
                                        : Colors.blue.withOpacity(
                                            isWinningCell ? 0.9 : 0.7,
                                          ),
                                    boxShadow: isWinningCell
                                        ? [
                                            BoxShadow(
                                              color:
                                                  board[row][col] ==
                                                      'الفريق الأحمر'
                                                  ? Colors.redAccent
                                                  : Colors.blueAccent,
                                              blurRadius: 10,
                                              spreadRadius: 2,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Center(
                                    child: AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      child: Text(
                                        board[row][col].isNotEmpty
                                            ? selectedLogos[board[row][col]]!
                                            : '',
                                        key: ValueKey(board[row][col]),
                                        style: TextStyle(
                                          fontSize: 40, // تقليل حجم الخط قليلاً
                                          shadows: [
                                            Shadow(
                                              blurRadius: 10,
                                              color: Colors.black.withOpacity(
                                                0.5,
                                              ),
                                              offset: const Offset(2, 2),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          );
                        }),
                      ),
                    ),
                  ],
                ),

                // معلومات الفريقين
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                teamNames['الفريق الأحمر']!,
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                onPressed: () => editTeamName('الفريق الأحمر'),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => selectLogo('الفريق الأحمر'),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: currentPlayer == 'الفريق الأحمر'
                                    ? Colors.red[800]
                                    : Colors.grey[700],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                selectedLogos['الفريق الأحمر']!,
                                style: const TextStyle(fontSize: 30),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                teamNames['الفريق الأزرق']!,
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                onPressed: () => editTeamName('الفريق الأزرق'),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => selectLogo('الفريق الأزرق'),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: currentPlayer == 'الفريق الأزرق'
                                    ? Colors.blue[800]
                                    : Colors.grey[700],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                selectedLogos['الفريق الأزرق']!,
                                style: const TextStyle(fontSize: 30),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (gameOver)
                  Column(
                    children: [
                      Text(
                        winner.isNotEmpty
                            ? '${selectedLogos[winner]} فاز ${teamNames[winner]}!'
                            : 'تعادل!',
                        style: const TextStyle(
                          fontSize: 28,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              blurRadius: 10,
                              color: Colors.black,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),

                ElevatedButton(
                  onPressed: resetGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[800],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'مباراة جديدة',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
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
