import 'package:flutter/material.dart';
import '../../models/transaction_model.dart';

class EditTransactionScreen extends StatelessWidget {
  final TransactionModel transaction;
  
  const EditTransactionScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Transaction')),
      body: const Center(child: Text('Edit Transaction - Coming Soon')),
    );
  }
} 