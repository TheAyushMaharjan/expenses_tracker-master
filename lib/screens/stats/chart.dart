import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class PieChartScreen extends StatefulWidget {
  const PieChartScreen({super.key});

  @override
  _PieChartScreenState createState() => _PieChartScreenState();
}

class _PieChartScreenState extends State<PieChartScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? userId; // Current user ID
  double totalIncome = 0;
  double totalExpense = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserId();
  }

  void _fetchUserId() {
    final User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        userId = user.uid;
      });
      _fetchData();
    } else {
      debugPrint('No user is logged in.');
    }
  }

  Future<void> _fetchData() async {
    if (userId == null) return;

    try {
      final incomeQuery = await _firestore
          .collection('income')
          .where('userId', isEqualTo: userId)
          .get();
      final expenseQuery = await _firestore
          .collection('expenses')
          .where('userId', isEqualTo: userId)
          .get();

      double incomeSum = 0;
      for (var doc in incomeQuery.docs) {
        incomeSum += (doc['amount'] as num).toDouble();
      }

      double expenseSum = 0;
      for (var doc in expenseQuery.docs) {
        expenseSum += (doc['amount'] as num).toDouble();
      }

      setState(() {
        totalIncome = incomeSum;
        totalExpense = expenseSum;
      });
    } catch (e) {
      debugPrint('Error fetching data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Income vs Expense"),
      ),
      body: userId == null
          ? const Center(child: CircularProgressIndicator())
          : totalIncome == 0 && totalExpense == 0
          ? const Center(child: CircularProgressIndicator())
          : Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Income vs Expense",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            width: 300,
            child: PieChart(
              PieChartData(
                sections: _generatePieChartSections(),
                centerSpaceRadius: 50,
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Total Income: Rs. ${totalIncome.toStringAsFixed(2)}",
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            "Total Expense: Rs. ${totalExpense.toStringAsFixed(2)}",
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: FutureBuilder(
              future: _fetchNotes(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                } else if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
                  return const Center(child: Text("No notes found."));
                }

                final notes = snapshot.data as List<Map<String, dynamic>>;
                return ListView.builder(
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    final isIncome = note['type'] == 'income';
                    return ListTile(
                      tileColor: isIncome ? Colors.green[50] : Colors.red[50],
                      title: Text(
                        note['note'],
                        style: TextStyle(color: isIncome ? Colors.green : Colors.red),
                      ),
                      subtitle: Text(
                          "Category: ${note['category']}\nAmount: Rs. ${note['amount'].toStringAsFixed(2)}"),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchNotes() async {
    if (userId == null) return [];

    List<Map<String, dynamic>> notes = [];

    try {
      final incomeQuery = await _firestore
          .collection('income')
          .where('userId', isEqualTo: userId)
          .get();
      final expenseQuery = await _firestore
          .collection('expenses')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in incomeQuery.docs) {
        notes.add({
          'note': doc['note'],
          'amount': (doc['amount'] as num).toDouble(),
          'category': doc['category'],
          'type': 'income',
        });
      }
      for (var doc in expenseQuery.docs) {
        notes.add({
          'note': doc['note'],
          'amount': (doc['amount'] as num).toDouble(),
          'category': doc['category'],
          'type': 'expense',
        });
      }
    } catch (e) {
      debugPrint('Error fetching notes: $e');
    }

    return notes;
  }

  List<PieChartSectionData> _generatePieChartSections() {
    final total = totalIncome + totalExpense;
    if (total == 0) return [];

    return [
      PieChartSectionData(
        color: Colors.green,
        value: totalIncome,
        title: "${((totalIncome / total) * 100).toStringAsFixed(1)}%",
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        color: Colors.red,
        value: totalExpense,
        title: "${((totalExpense / total) * 100).toStringAsFixed(1)}%",
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ];
  }
}
