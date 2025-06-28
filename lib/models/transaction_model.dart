import 'package:json_annotation/json_annotation.dart';

part 'transaction_model.g.dart';

@JsonSerializable()
class TransactionModel {
  final int? id;
  final String title;
  final String description;
  final double amount;
  final String type; // 'expense' or 'income'
  final String category;
  final String date;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;
  final String? receipt; // URL to receipt image
  final Map<String, dynamic>? metadata;

  const TransactionModel({
    this.id,
    required this.title,
    required this.description,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.createdAt,
    this.updatedAt,
    this.receipt,
    this.metadata,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      _$TransactionModelFromJson(json);

  Map<String, dynamic> toJson() => _$TransactionModelToJson(this);

  bool get isExpense => type == 'expense';
  bool get isIncome => type == 'income';

  TransactionModel copyWith({
    int? id,
    String? title,
    String? description,
    double? amount,
    String? type,
    String? category,
    String? date,
    String? createdAt,
    String? updatedAt,
    String? receipt,
    Map<String, dynamic>? metadata,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      receipt: receipt ?? this.receipt,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper method to create a new transaction
  static TransactionModel create({
    required String title,
    required String description,
    required double amount,
    required String type,
    required String category,
    required String date,
    String? receipt,
    Map<String, dynamic>? metadata,
  }) {
    return TransactionModel(
      title: title,
      description: description,
      amount: amount,
      type: type,
      category: category,
      date: date,
      receipt: receipt,
      metadata: metadata,
    );
  }
} 