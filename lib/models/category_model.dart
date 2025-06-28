import 'package:json_annotation/json_annotation.dart';

part 'category_model.g.dart';

@JsonSerializable()
class CategoryModel {
  final int? id;
  final String name;
  final String description;
  final String? icon;
  final String? color;
  final String type; // 'expense' or 'income' or 'both'
  @JsonKey(name: 'is_default')
  final bool isDefault;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  const CategoryModel({
    this.id,
    required this.name,
    required this.description,
    this.icon,
    this.color,
    required this.type,
    this.isDefault = false,
    this.createdAt,
    this.updatedAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) =>
      _$CategoryModelFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryModelToJson(this);

  bool get isExpenseCategory => type == 'expense' || type == 'both';
  bool get isIncomeCategory => type == 'income' || type == 'both';

  CategoryModel copyWith({
    int? id,
    String? name,
    String? description,
    String? icon,
    String? color,
    String? type,
    bool? isDefault,
    String? createdAt,
    String? updatedAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      type: type ?? this.type,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper method to create a new category
  static CategoryModel create({
    required String name,
    required String description,
    String? icon,
    String? color,
    required String type,
    bool isDefault = false,
  }) {
    return CategoryModel(
      name: name,
      description: description,
      icon: icon,
      color: color,
      type: type,
      isDefault: isDefault,
    );
  }

  // Default categories
  static List<CategoryModel> getDefaultExpenseCategories() {
    return [
      CategoryModel.create(
        name: 'Food & Dining',
        description: 'Restaurants, groceries, and food expenses',
        icon: '🍽️',
        color: '#FF9800',
        type: 'expense',
        isDefault: true,
      ),
      CategoryModel.create(
        name: 'Transportation',
        description: 'Gas, public transport, car maintenance',
        icon: '🚗',
        color: '#2196F3',
        type: 'expense',
        isDefault: true,
      ),
      CategoryModel.create(
        name: 'Shopping',
        description: 'Clothes, electronics, and other purchases',
        icon: '🛍️',
        color: '#E91E63',
        type: 'expense',
        isDefault: true,
      ),
      CategoryModel.create(
        name: 'Entertainment',
        description: 'Movies, games, and recreational activities',
        icon: '🎬',
        color: '#9C27B0',
        type: 'expense',
        isDefault: true,
      ),
      CategoryModel.create(
        name: 'Bills & Utilities',
        description: 'Electricity, water, internet, phone bills',
        icon: '📄',
        color: '#607D8B',
        type: 'expense',
        isDefault: true,
      ),
      CategoryModel.create(
        name: 'Healthcare',
        description: 'Medical expenses, pharmacy, insurance',
        icon: '🏥',
        color: '#F44336',
        type: 'expense',
        isDefault: true,
      ),
    ];
  }

  static List<CategoryModel> getDefaultIncomeCategories() {
    return [
      CategoryModel.create(
        name: 'Salary',
        description: 'Regular job income',
        icon: '💼',
        color: '#4CAF50',
        type: 'income',
        isDefault: true,
      ),
      CategoryModel.create(
        name: 'Freelance',
        description: 'Freelance work and projects',
        icon: '💻',
        color: '#00BCD4',
        type: 'income',
        isDefault: true,
      ),
      CategoryModel.create(
        name: 'Investment',
        description: 'Returns from investments and stocks',
        icon: '📈',
        color: '#8BC34A',
        type: 'income',
        isDefault: true,
      ),
      CategoryModel.create(
        name: 'Gift',
        description: 'Money received as gifts',
        icon: '🎁',
        color: '#FF5722',
        type: 'income',
        isDefault: true,
      ),
      CategoryModel.create(
        name: 'Other',
        description: 'Other sources of income',
        icon: '💰',
        color: '#795548',
        type: 'income',
        isDefault: true,
      ),
    ];
  }
} 