class Meal {
  final String id;
  final String name;
  final String category;
  final String area;
  final String instructions;
  final String thumbnail;
  final String? youtubeUrl;
  final List<MealIngredient> ingredients;
  final String? tags;

  Meal({
    required this.id,
    required this.name,
    required this.category,
    required this.area,
    required this.instructions,
    required this.thumbnail,
    this.youtubeUrl,
    required this.ingredients,
    this.tags,
  });

  // MÉTODO CLAVE: Permite crear una nueva instancia con datos cambiados
  Meal copyWith({
    String? name,
    String? instructions,
    List<MealIngredient>? ingredients,
  }) {
    return Meal(
      id: id,
      name: name ?? this.name,
      category: category,
      area: area,
      instructions: instructions ?? this.instructions,
      thumbnail: thumbnail,
      youtubeUrl: youtubeUrl,
      ingredients: ingredients ?? this.ingredients,
      tags: tags,
    );
  }

  factory Meal.fromJson(Map<String, dynamic> json) {
    final List<MealIngredient> ingredients = [];

    for (int i = 1; i <= 20; i++) {
      final ingredient = json['strIngredient$i'];
      final measure = json['strMeasure$i'];
      if (ingredient != null && ingredient.toString().trim().isNotEmpty) {
        ingredients.add(
          MealIngredient(
            name: ingredient.toString().trim(),
            measure: (measure ?? '').toString().trim(),
          ),
        );
      }
    }

    return Meal(
      id: json['idMeal'] ?? '',
      name: json['strMeal'] ?? '',
      category: json['strCategory'] ?? '',
      area: json['strArea'] ?? '',
      instructions: json['strInstructions'] ?? '',
      thumbnail: json['strMealThumb'] ?? '',
      youtubeUrl: json['strYoutube'],
      ingredients: ingredients,
      tags: json['strTags'],
    );
  }
}

class MealIngredient {
  final String name;
  final String measure;

  MealIngredient({required this.name, required this.measure});

  // MÉTODO CLAVE: Para traducir el ingrediente individual
  MealIngredient copyWith({String? name, String? measure}) {
    return MealIngredient(
      name: name ?? this.name,
      measure: measure ?? this.measure,
    );
  }
}

class MealSummary {
  final String id;
  final String name;
  final String thumbnail;

  MealSummary({required this.id, required this.name, required this.thumbnail});

  factory MealSummary.fromJson(Map<String, dynamic> json) {
    return MealSummary(
      id: json['idMeal'] ?? '',
      name: json['strMeal'] ?? '',
      thumbnail: json['strMealThumb'] ?? '',
    );
  }
}

class MealCategory {
  final String name;
  final String thumbnail;
  final String description;

  MealCategory({
    required this.name,
    required this.thumbnail,
    required this.description,
  });

  factory MealCategory.fromJson(Map<String, dynamic> json) {
    return MealCategory(
      name: json['strCategory'] ?? '',
      thumbnail: json['strCategoryThumb'] ?? '',
      description: json['strCategoryDescription'] ?? '',
    );
  }
}
