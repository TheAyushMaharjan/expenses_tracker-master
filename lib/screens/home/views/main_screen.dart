import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expenses_tracker/screens/home/views/SettingPage.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedTab = 0; // 0: ALL, 1: Income, 2: Expenses

  Future<Map<String, dynamic>> getUserData() async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) {
      throw Exception('User not authenticated');
    }
    DocumentSnapshot userDoc =
    await FirebaseFirestore.instance.collection('Users').doc(userId).get();
    return userDoc.data() as Map<String, dynamic>;
  }

  Future<double> getTotalAmount(String collection) async {
    double total = 0.0;
    QuerySnapshot snapshot =
    await FirebaseFirestore.instance.collection(collection).get();
    for (var doc in snapshot.docs) {
      total += doc['amount'];
    }
    return total;
  }

  Future<List<Map<String, dynamic>>> getTransactionDetails(
      String collection) async {
    QuerySnapshot snapshot =
    await FirebaseFirestore.instance.collection(collection).get();

    List<Map<String, dynamic>> transactions = snapshot.docs
        .map((doc) => {
      'id': doc.id, // Store the document ID for deletion
      'category': doc['category'],
      'note': doc['note'], // Assuming a 'note' field exists
      'date': doc['createdAt'], // Use createdAt for sorting
      'amount': doc['amount'],
      'type': collection, // Add 'income' or 'expense' for ALL tab
    })
        .toList();

    // Sort transactions by createdAt in descending order
    transactions.sort((a, b) {
      DateTime dateA = (a['date'] as Timestamp).toDate();
      DateTime dateB = (b['date'] as Timestamp).toDate();
      return dateB.compareTo(dateA); // Recent date first
    });

    return transactions;
  }

  Future<void> deleteTransaction(String collection, String docId) async {
    try {
      await FirebaseFirestore.instance.collection(collection).doc(docId).delete();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction deleted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete transaction: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 24.0),
        child: FutureBuilder(
          future: Future.wait([
            getUserData(),
            getTotalAmount('income'),
            getTotalAmount('expenses'),
            getTransactionDetails('income'),
            getTransactionDetails('expenses')
          ]),
          builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (snapshot.hasData) {
              var userData = snapshot.data![0] as Map<String, dynamic>;
              double incomeTotal = snapshot.data![1] as double;
              double expenseTotal = snapshot.data![2] as double;
              List<Map<String, dynamic>> incomeDetails =
              snapshot.data![3] as List<Map<String, dynamic>>;
              List<Map<String, dynamic>> expenseDetails =
              snapshot.data![4] as List<Map<String, dynamic>>;

              // Combine Income and Expense for "ALL" Tab
              List<Map<String, dynamic>> allDetails = [
                ...incomeDetails,
                ...expenseDetails
              ];

              // Determine which data to show based on the selected tab
              List<Map<String, dynamic>> selectedDetails;
              if (_selectedTab == 0) {
                selectedDetails = allDetails;
              } else if (_selectedTab == 1) {
                selectedDetails = incomeDetails;
              } else {
                selectedDetails = expenseDetails;
              }

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header and Balance Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                    Theme.of(context).colorScheme.secondary,
                                  ),
                                ),
                                const Icon(Icons.person, color: Colors.white),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome,',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                Text(
                                  userData['username'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SettingsPage()),
                            );
                          },
                          icon: const Icon(Icons.settings, color: Colors.grey),
                        ),

                      ],
                    ),
                    const SizedBox(height: 24),
                    // Balance Card
                    Container(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.width / 2,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Balance',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                Icon(
                                  Icons.credit_card,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                            Text(
                              'Rs.${(incomeTotal - expenseTotal).toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Income',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      'Rs.${incomeTotal.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Expenses',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      'Rs.${expenseTotal.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Tab Section
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          _buildTabButton(0, 'ALL'),
                          _buildTabButton(1, 'Income'),
                          _buildTabButton(2, 'Expenses'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space between the items
                    children: [
                      const Text(
                        'Particular',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                        ),
                      ),
                      const Text(
                        'Debit/Credit',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),


                    // Transaction List with Swipe-to-Delete
                    ...selectedDetails.map(
                          (transaction) => Dismissible(
                        key: Key(transaction['id']),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Transaction'),
                              content: const Text(
                                  'Are you sure you want to delete this transaction?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (direction) {
                          deleteTransaction(
                              transaction['type'], transaction['id']);
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.shade200,
                                blurRadius: 4.0,
                                spreadRadius: 1.0,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${transaction['note']} (${transaction['category']})',
                                  style: const TextStyle(
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Center(
                                  child: Text(
                                    (transaction['date'] as Timestamp).toDate().toString().split(' ')[0],
                                    style: TextStyle(
                                      fontSize: 12.0,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    'Rs.${transaction['amount'].toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.bold,
                                      color: transaction['type'] == 'income'
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            } else {
              return const Center(child: Text('No data available.'));
            }
          },
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String label) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: _selectedTab == index
              ? Theme.of(context).primaryColor
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: _selectedTab == index ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
