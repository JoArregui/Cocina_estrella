# Cocina Estrella — Documentación Técnica

> App Flutter de recetas con TheMealDB + Spoonacular + Recetas locales + IA generativa, Chef IA (visión + texto) y Modo Cocinero paso a paso.

**Versión:** 1.0.0+1 | **Package:** `recipe_app` (`pubspec.yaml:1`) | **SDK:** `>=3.0.0 <4.0.0` (`pubspec.yaml:7`) | **Flutter:** Material 3 | **Recetario:** ~300 TheMealDB + 5k Spoonacular + ilimitado Local/IA

---

## Índice

1. [Resumen y Funcionalidades](#1-resumen-y-funcionalidades)
2. [Stack Tecnológico](#2-stack-tecnológico)
3. [Arquitectura](#3-arquitectura)
4. [Estructura de Carpetas](#4-estructura-de-carpetas)
5. [Configuración y Variables de Entorno](#5-configuración-y-variables-de-entorno)
6. [Proveedores de IA](#6-proveedores-de-ia)
7. [Persistencia y Cache Offline](#7-persistencia-y-cache-offline)
8. [Internacionalización (l10n)](#8-internacionalización-l10n)
9. [Tema y Diseño](#9-tema-y-diseño)
10. [Navegación y Pantallas](#10-navegación-y-pantallas)
11. [Modelos y Servicios](#11-modelos-y-servicios)
12. [Traducción](#12-traducción)
13. [Testing](#13-testing)
14. [Análisis Estático](#14-análisis-estático)
15. [CI/CD](#15-cicd)
16. [Ejecución, Build y Deploy](#16-ejecución-build-y-deploy)
17. [Seguridad](#17-seguridad)
18. [Roadmap](#18-roadmap)

---

## 1. Resumen y Funcionalidades

- **Exploración por categorías:** Grid de 14 categorías TheMealDB con imágenes y traducción `Translator.category()` (`lib/utils/translator.dart:36`).
- **Búsqueda con debounce:** 500 ms (`lib/screens/search_screen.dart:32`), estados loading/empty/results. Fallback Spoonacular (`lib/repositories/unified_recipe_repository.dart:1`) si TheMealDB no tiene resultados y `SPOONACULAR_API_KEY` está configurada.
- **Filtros ampliados:** Por **origen** (`getMealsByArea` `lib/services/meal_service.dart:146`, 27 áreas) y **ingrediente** (`getMealsByIngredient` `lib/services/meal_service.dart:160`, 200+ ingredientes) vía `ExploreFiltersScreen` (`lib/screens/explore_filters_screen.dart:1`) con chips y grid. Lista de ingredientes/áreas vía `list.php?a/i=list`.
- **Receta aleatoria:** `getRandomMeal()` (`lib/services/meal_service.dart:179`) con traducción + botón Aleatoria en Home (`lib/screens/home_screen.dart:27`).
- **Detalle de receta:** `TabBar` Ingredientes/Preparación, traducción automática (`lib/services/meal_service.dart:80`), pasos parseados (`lib/screens/recipe_detail_screen.dart:290`). Soporta `isLocal`/`user_` y `sp_`/`ai_` via `UnifiedRecipeRepository`.
- **Chef IA:** Dos modos — *Escribir lista* o *Foto ingredientes* (`lib/screens/ingredient_scan_screen.dart:96`). Detecta ingredientes y sugiere 5 platos con `match_percent`. Soporta Gemini y OpenRouter Muse Spark/Nemotron/Vision (`lib/services/openrouter_service.dart:14`), badge dinámico.
- **Generación IA completa:** `AiRecipeGenerator` (`lib/services/ai_recipe_generator.dart:1`) genera receta completa `Meal` JSON desde prompt o ingredientes, usado en formulario (`lib/screens/recipe_form_screen.dart:84` botón IA).
- **Recetario local:** CRUD 100% offline en `user_recipes` SQLite (`lib/data/app_database.dart:8` v3, `lib/services/local_recipe_service.dart:1`), pantallas `RecipeFormScreen` y `UserRecipesScreen` (`lib/screens/user_recipes_screen.dart:1`), sección horizontal en Home y navegación (`lib/screens/home_screen.dart:27`).
- **Modo Cocinero:** 2 fases, timers (`lib/utils/timer_parser.dart:1`), `wakelock_plus` (`lib/screens/cooking_mode_screen.dart:13`), progreso y celebración.
- **Favoritos:** Toggle corazón (`lib/screens/recipe_detail_screen.dart:46`), listado offline (`lib/screens/favorites_screen.dart:1`), persistencia dual Hive + SQLite.
- **Cache offline:** Categorías, platos por categoría/área/ingrediente y detalle cacheados.

---

## 2. Stack Tecnológico

| Capa | Librería | Uso |
|------|----------|-----|
| UI | `flutter`, `google_fonts: ^6.2.1`, `cached_network_image: ^3.3.1`, `shimmer: ^3.0.0` | Tipografía Playfair/Nunito, imágenes cacheadas, skeletons |
| Estado | `flutter_riverpod: ^2.6.1` | Providers, StateNotifier (`lib/providers/providers.dart:1`) |
| Red | `http: ^1.2.1` | TheMealDB, Gemini, OpenRouter |
| Media | `image_picker: ^1.2.1` | Cámara/galería |
| Persistencia | `hive_flutter: ^1.1.0`, `hive: ^2.2.3`, `sqflite: ^2.4.2+1`, `sqlite3_flutter_libs`, `shared_preferences: ^2.5.5`, `path_provider`, `path: ^1.9.1`, `uuid: ^4.5.3` | Cache, favoritos y recetas usuario |
| Util | `flutter_dotenv: ^6.0.0`, `wakelock_plus: ^1.7.0`, `intl: 0.20.2`, `flutter_localizations` (SDK), `translator: ^1.0.0` | Env, wakelock, i18n, traducción scraper |
| Dev | `flutter_lints: ^3.0.0`, `flutter_test`, `build_runner: ^2.15.1`, `flutter_launcher_icons: ^0.13.1` | Lints, tests, iconos |

---

## 3. Arquitectura

**Patrón:** Feature-first + Repository + Provider.

```
UI (ConsumerWidget/ConsumerStatefulWidget)
  → Providers (Riverpod FutureProvider/StateNotifierProvider)
    → Repositories (MealRepository, UnifiedRecipeRepository)
      → Services (MealService, SpoonacularService, AIService/GeminiService/OpenRouterService/AiRecipeGenerator, FavoritesService, LocalRecipeService)
        → Data Sources (TheMealDB API, Spoonacular API, Hive Box, AppDatabase SQLite v3)
```

- **Inyección:** `http.Client` inyectable en `MealService` (`lib/services/meal_service.dart:14`) y `OpenRouterService` para tests con `MockClient`.
- **Abstracción IA:** `AIService` (`lib/services/ai_service.dart:1`) permite cambiar `Gemini ↔ OpenRouter (Muse Spark/Nemotron/Vision)` sin tocar UI (`lib/providers/providers.dart:23` factory).
- **Repositorio con cache:** `MealRepository` (`lib/repositories/meal_repository.dart:1`) lee/escribe `Hive.box<String>('cache')` + `AppDatabase` (SQLite) antes de ir a red.
- **Theming centralizado:** `AppColors` (`lib/theme/app_colors.dart:1`) y `AppTheme.light` (`lib/theme/app_theme.dart:1`) eliminan duplicación de `Color(0xFFE8490F)`.

**Principios:** SRP (widgets extraídos a `lib/widgets/`), timeouts explícitos (10s TheMealDB, 20-25s IA), fallback graceful (traductor devuelve original si falla).

---

## 4. Estructura de Carpetas

```
lib/
├── main.dart                         # ProviderScope + Hive.init + AppLocalizations
├── l10n/
│   ├── app_es.arb / app_en.arb       # 45 keys cada uno
│   ├── app_localizations.dart        # generado por flutter gen-l10n
│   └── l10n.yaml                     # arb-dir, template, supportedLocales
├── theme/
│   ├── app_colors.dart               # paleta centralizada
│   └── app_theme.dart                # ThemeData + GoogleFonts.nunitoTextTheme
├── models/
│   └── meal.dart                     # Meal, MealIngredient, MealSummary, MealCategory (fromJson/copyWith)
├── services/
│   ├── ai_service.dart               # interfaz AIService
│   ├── gemini_service.dart           # Gemini 2.0 Flash + proxy
│   ├── openrouter_service.dart       # Muse Spark / Nemotron / Vision free
│   ├── ai_recipe_generator.dart      # generación receta completa IA (prompt→Meal)
│   ├── spoonacular_service.dart      # Spoonacular +5k recetas (fallback)
│   ├── meal_service.dart             # TheMealDB CRUD + getAreas/Ingredient/random
│   ├── favorites_service.dart        # Hive + AppDatabase dual
│   └── local_recipe_service.dart     # CRUD user_recipes (uuid)
├── repositories/
│   ├── meal_repository.dart          # cache Hive/JSON + SQLite
│   └── unified_recipe_repository.dart # agregador TheMealDB + Spoonacular + cache
├── providers/
│   └── providers.dart                # Riverpod: mealService, spoonacular, unified, localRecipe, aiRecipeGenerator, cacheBox, categories, mealsByCategory/Area/Ingredient, mealDetail/localMeal, search, favorites, chefIa, userRecipes, randomMeal, areas, ingredients
├── data/
│   └── app_database.dart             # sqflite v3: favorites, cached_meals, cached_categories, user_recipes, migración v1→v3
├── utils/
│   ├── api_key_service.dart          # GEMINI_API_KEY via dart-define > .env
│   ├── translator.dart               # cache LRU 500 + diccionario local ingredientes/medidas + Google scraper
│   └── timer_parser.dart             # detectTimerSeconds() + formatTime()
├── widgets/
│   ├── category_card.dart
│   ├── meal_card.dart
│   └── suggestion_card.dart          # SuggestionCard, MatchBadge, InfoChip, ToggleTab, ImageSourceButton
└── screens/
    ├── home_screen.dart              # categoriesProvider + quickActions (Aleatoria/Explorar/Mis recetas) + userRecipes horizontal
    ├── category_screen.dart          # mealsByCategoryProvider
    ├── search_screen.dart            # searchQueryProvider + searchResultsProvider (debounce 500ms)
    ├── recipe_detail_screen.dart     # mealDetailProvider/localMealProvider(isLocal, localMeal) + favorites/edit
    ├── ingredient_scan_screen.dart   # chefIaProvider + aiServiceProvider badge (Muse Spark/Nemotron/Proxy/Gemini)
    ├── cooking_mode_screen.dart      # WakelockPlus + timer_parser
    ├── favorites_screen.dart         # favoritesProvider
    ├── explore_filters_screen.dart   # areasProvider/ingredientsProvider + mealsByArea/Ingredient
    ├── recipe_form_screen.dart       # CRUD local + IA generateFromPrompt
    └── user_recipes_screen.dart      # userRecipesProvider + Dismissible delete

test/
├── widget_test.dart                  # smoke tests con ProviderScope.overrideWith
├── utils/timer_parser_test.dart      # detect/format
├── utils/translator_test.dart        # diccionario, cache
├── services/meal_service_test.dart   # MockClient categories/search/error
├── services/gemini_service_test.dart # RecipeSuggestion.fromJson
└── widgets/category_card_test.dart   # traducción, onTap

proxy/README.md                       # ejemplo Cloud Function proxy Gemini
.env.example                          # plantilla OPENROUTER_API_KEY, AI_PROVIDER, GEMINI_*
```

---

## 5. Configuración y Variables de Entorno

**Prioridad de API Keys** (`lib/utils/api_key_service.dart:4`, `lib/services/gemini_service.dart:54`):

1. `--dart-define` (recomendado, no se empaqueta)
2. `.env` local (solo dev, **no** en `flutter.assets` — `pubspec.yaml:48`)

| Variable | Fuente | Descripción |
|----------|--------|-------------|
| `OPENROUTER_API_KEY` | `String.fromEnvironment` (`lib/services/openrouter_service.dart:17`, `lib/services/ai_recipe_generator.dart:8`) | Key free OpenRouter (https://openrouter.ai/keys). Activa Muse Spark/Nemotron + generación IA. |
| `AI_PROVIDER` | `String.fromEnvironment` default `muse-spark` | `muse-spark` (default óptimo), `nemotron`, `auto` |
| `AI_MODEL` | `String.fromEnvironment` | Override modelo: `meta-llama/llama-3.2-3b-instruct:free`, `nvidia/llama-3.1-nemotron-70b-instruct:free`, `meta-llama/llama-3.2-11b-vision-instruct:free` |
| `GEMINI_API_KEY` | `ApiKeyService.getKey()` (`lib/utils/api_key_service.dart:7`) | Fallback Gemini si no hay OpenRouter |
| `GEMINI_PROXY_URL` | `String.fromEnvironment` (`lib/services/gemini_service.dart:54`) | Backend que custodia key: `POST $proxy/analyze` |
| `SPOONACULAR_API_KEY` | `String.fromEnvironment` (`lib/services/spoonacular_service.dart:16`) | Opcional +5k recetas Spoonacular (150 req/día free, fallback TheMealDB si ausente) |

**Ejemplos:**

```bash
# Óptimo FREE (Muse Spark + Vision) + Spoonacular
flutter run --dart-define=OPENROUTER_API_KEY=sk-or-... --dart-define=AI_PROVIDER=muse-spark --dart-define=SPOONACULAR_API_KEY=abc123

# Nemotron (más reasoning)
flutter run --dart-define=OPENROUTER_API_KEY=sk-or-... --dart-define=AI_PROVIDER=nemotron

# Solo TheMealDB + IA local (sin keys externas, recetas usuario + TheMealDB)
flutter run

# Gemini directo (dev)
flutter run --dart-define=GEMINI_API_KEY=AIza...

# Producción con proxy (key no en binario)
flutter build apk --dart-define=GEMINI_PROXY_URL=https://tu-proxy.com
flutter build apk --dart-define=OPENROUTER_API_KEY=sk-or-... --dart-define=SPOONACULAR_API_KEY=...

# .env local (solo dev, gitignore)
cp .env.example .env
# editar OPENROUTER_API_KEY / SPOONACULAR_API_KEY / GEMINI_API_KEY
```

**`l10n.yaml:1`** y `pubspec.yaml:50` `generate: true` habilitan `flutter gen-l10n`.

---

## 6. Proveedores de IA

### 6.1 Interfaz común (`lib/services/ai_service.dart:1`)

```dart
abstract class AIService {
  Future<GeminiResult> analyze({File? image, String? textIngredients});
  String get providerName;
  bool get isConfigured;
}
```

Retorna `GeminiResult` (`lib/services/gemini_service.dart:6`): `ingredients: List<String>` + `suggestions: List<RecipeSuggestion>`.

### 6.2 Gemini (`lib/services/gemini_service.dart:43`)

- Modelo: `gemini-2.0-flash`, timeout 20s, `http.Client` inyectable.
- Prompt estricto JSON sin markdown (`{ingredients, suggestions: [{name, name_es, description, difficulty, time, match_percent}]}`).
- Soporta `GEMINI_PROXY_URL`: si está definido, no requiere key y hace `POST $proxy/analyze` con `{parts, generationConfig}`; si proxy responde `{ingredients,suggestions}` directo lo parsea sin `candidates`.
- Fallback: si status 400/403 → `API Key inválida`.

### 6.3 OpenRouter — Muse Spark / Nemotron / Vision (`lib/services/openrouter_service.dart:14`)

**Selección óptima para Cocina Estrella:**

- **Texto (lista):** `meta-llama/llama-3.2-3b-instruct:free` (familia Muse Spark, rápido, español nativo, JSON fiable) — default `AI_PROVIDER=muse-spark`.
- **Visión (foto):** `meta-llama/llama-3.2-11b-vision-instruct:free` (soporta `image_url: data:image/jpeg;base64`, free).
- **Alternativa:** `nvidia/llama-3.1-nemotron-70b-instruct:free` si `AI_PROVIDER=nemotron` (70B, mejor reasoning, más lento/costoso).

Endpoint: `https://openrouter.ai/api/v1/chat/completions` con headers `Authorization: Bearer $OPENROUTER_API_KEY`, `HTTP-Referer`, `X-Title`. Limpia fences ```json y extrae `\{.*\}`.

**Factory** (`lib/providers/providers.dart:23`):

```dart
final aiServiceProvider = Provider<AIService>((ref) {
  const openRouterKey = String.fromEnvironment('OPENROUTER_API_KEY');
  if (openRouterKey.isNotEmpty) return OpenRouterService();
  return GeminiService(); // proxy-aware
});
```

UI muestra badge dinámico (`lib/screens/ingredient_scan_screen.dart:61`): `Muse Spark` / `Nemotron` / `Proxy` / `Gemini`.

### 6.4 Generación completa IA (`lib/services/ai_recipe_generator.dart:1`)

`generateFromIngredients(List<String>)` / `generateFromPrompt(String)` → `Meal(id: ai_...)` con `category/area/instructions/ingredients/tags` JSON estricto, via OpenRouter Muse Spark o Gemini. Usado en `RecipeFormScreen` botón IA (`lib/screens/recipe_form_screen.dart:84`) para autorelleno.

### 6.5 Proxy ejemplo (`proxy/README.md:1`)

Node.js Cloud Function que custodia `GEMINI_API_KEY` y reenvía a `generativelanguage.googleapis.com`. Build con `GEMINI_PROXY_URL` no expone key en APK.

---

## 7. Persistencia y Cache Offline

**Hive** (`lib/main.dart:21`): `Hive.initFlutter()`, boxes `cache` (String) y `favorites`.

**SQLite** (`lib/data/app_database.dart:1`): `sqflite` + `path` + `uuid`, DB `cocina_estrella.db` v3, tablas:

```sql
favorites(id TEXT PK, name TEXT, thumbnail TEXT, category TEXT, area TEXT, created_at INTEGER)
cached_meals(id TEXT PK, json TEXT, updated_at INTEGER)
cached_categories(id TEXT PK, json TEXT, updated_at INTEGER)
user_recipes(id TEXT PK, json TEXT, created_at INTEGER, updated_at INTEGER)
```

Migración `onCreate` + `onUpgrade v1→v2→v3`.

**MealRepository** (`lib/repositories/meal_repository.dart:1`): `getCategories()`, `getMealsByCategory()`, `getMealById()` con Hive `cache` JSON, `searchMeals()` sin cache.

**UnifiedRecipeRepository** (`lib/repositories/unified_recipe_repository.dart:1`): agregador. `search()` → TheMealDB primero, fallback `SpoonacularService.search()` si `isConfigured`. `getAreas()`/`getIngredientList()`/`getMealsByArea()`/`getMealsByIngredient()`/`getById()` (prefijos `sp_`, `user_`, `ai_`) y `getRandom()`.

**SpoonacularService** (`lib/services/spoonacular_service.dart:1`): `search()` (`complexSearch`) y `getById()` (`information`), mapeo a `MealSummary`/`Meal`, 402 límite, `isConfigured` si `SPOONACULAR_API_KEY` presente.

**LocalRecipeService** (`lib/services/local_recipe_service.dart:1`): CRUD `user_recipes` via `AppDatabase`, `create()` con `uuid` `user_`, `update()`/`delete()`/`getAll()`/`getById()`, serializa `Meal` a `strMeal/strIngredientN`.

**AiRecipeGenerator** ver §6.4.

**FavoritesService** (`lib/services/favorites_service.dart:1`): dual write SQLite+Hive.

**TheMealDB sin key**, pública; **Spoonacular** opcional con key.

---

## 8. Internacionalización (l10n)

- `l10n.yaml:1` (`arb-dir: lib/l10n`, `template-arb-file: app_es.arb`, `output-class: AppLocalizations`, `preferred-supported-locales: ["es"]`).
- `lib/l10n/app_es.arb:1` (45 keys, `@@locale: es`) y `app_en.arb:1` (ingles, escapes `What''s`/`Let''s`/`Time''s` para ICU).
- Generados `app_localizations.dart`/`_en.dart`/`_es.dart` vía `flutter gen-l10n`.
- `lib/main.dart:34` `localizationsDelegates: AppLocalizations.localizationsDelegates`, `supportedLocales`, `locale: Locale('es')`. `pubspec.yaml:50` `generate: true` + `flutter_localizations` SDK y `intl: 0.20.2`.

Listo para migrar `Text('¿Qué cocinamos')` → `l10n.whatToCookToday`.

---

## 9. Tema y Diseño

- `lib/theme/app_colors.dart:1` (`primary 0xFFE8490F`, `primaryLight 0xFFFF7A45`, `background 0xFFF8F4F0`, `textPrimary 0xFF1A1A1A`, etc., helpers `withValues(alpha:)`).
- `lib/theme/app_theme.dart:1` (`AppTheme.light`: `ColorScheme.fromSeed`, `GoogleFonts.nunitoTextTheme`, `AppBarTheme` transparente, `ElevatedButtonTheme`, `cardShadow`/`smallShadow` con `withValues`).
- `pubspec.yaml:50` `uses-material-design: true`, Material 3.

Reemplaza `withOpacity` deprecated por `withValues(alpha:)` en todos los screens (64 ocurrencias fix).

---

## 10. Navegación y Pantallas

| Pantalla | Tipo | Provider | Descripción |
|----------|------|----------|-------------|
| `HomeScreen` (`lib/screens/home_screen.dart:1`) | `ConsumerWidget` | `categoriesProvider` + `userRecipesProvider` | `CustomScrollView` con AppBar, header, searchButton, AiBanner, `_buildQuickActions` (Aleatoria → `randomMealProvider`, Explorar → `ExploreFiltersScreen`, Mis recetas → `UserRecipesScreen`), sección horizontal `userRecipesProvider` (120px), grid `CategoryCard` (2 cols). |
| `CategoryScreen` (`lib/screens/category_screen.dart:1`) | `ConsumerWidget` | `mealsByCategoryProvider` | `SliverAppBar` 220 con `Translator.category`, grid `MealCard` (`/medium`). |
| `SearchScreen` (`lib/screens/search_screen.dart:1`) | `ConsumerStatefulWidget` | `searchQueryProvider` + `searchResultsProvider` (usa `UnifiedRecipeRepository` fallback Spoonacular) | Debounce 500 ms, estados. |
| `ExploreFiltersScreen` (`lib/screens/explore_filters_screen.dart:1`) | `ConsumerStatefulWidget` | `areasProvider`/`ingredientsProvider` + `mealsByAreaProvider`/`mealsByIngredientProvider` | Chips `ChoiceChip` (20 áreas con `Translator.area`, 20 ingredientes), grid resultados `MealCard` → `RecipeDetailScreen`. |
| `RecipeDetailScreen` (`lib/screens/recipe_detail_screen.dart:1`) | `ConsumerStatefulWidget` | `mealDetailProvider` / `localMealProvider` (si `isLocal`/`user_`) | `SliverAppBar` 280, favoritos, FAB Modo Cocinero, soporte `localMeal` (IA efímera) y recetas `sp_`/`ai_`. |
| `RecipeFormScreen` (`lib/screens/recipe_form_screen.dart:1`) | `ConsumerStatefulWidget` | `localRecipeServiceProvider` + `aiRecipeGeneratorProvider` | Form `nombre/categoría/origen/imagen/ingredientes/instrucciones`, add ingrediente, botón IA `generateFromPrompt` (autorrelena), guardar `create`/`update` → `RecipeDetailScreen(isLocal:true)`. |
| `UserRecipesScreen` (`lib/screens/user_recipes_screen.dart:1`) | `ConsumerWidget` | `userRecipesProvider` | Grid `MealSummary` con `Dismissible` delete, FAB Nueva → `RecipeFormScreen`. |
| `IngredientScanScreen` (`lib/screens/ingredient_scan_screen.dart:1`) | `ConsumerStatefulWidget` | `chefIaProvider` + `aiServiceProvider` badge | Toggle, `_analyze` → `ChefIa`, `SuggestionCard` → `RecipeDetail` o `CookingMode`. |
| `CookingModeScreen` (`lib/screens/cooking_mode_screen.dart:1`) | `StatefulWidget` | — | 2 fases, `WakelockPlus`, timers, progreso. |
| `FavoritesScreen` (`lib/screens/favorites_screen.dart:1`) | `ConsumerWidget` | `favoritesProvider` | Grid 2 cols. |

**Widgets extraídos** (`lib/widgets/`): `CategoryCard` (Stack imagen + gradiente + `Translator.category`), `MealCard` (`/medium` con fallback), `SuggestionCard` + `MatchBadge`/`InfoChip`/`ToggleTab`/`ImageSourceButton`.

---

## 11. Modelos y Servicios

**Modelos** (`lib/models/meal.dart:1`):

```dart
Meal {id, name, category, area, instructions, thumbnail, youtubeUrl, ingredients: List<MealIngredient>, tags; copyWith, fromJson (strIngredient1..20)}
MealIngredient {name, measure; copyWith}
MealSummary {id, name, thumbnail; fromJson}
MealCategory {name, thumbnail, description; fromJson}
```

**MealService** (`lib/services/meal_service.dart:1`): `_baseUrl`, `_timeout 10s`, `_get()`. `getCategories`, `getMealsByCategory`, `searchMeals`, `getMealById` (traducción), `getAreas()`/`getMealsByArea()`/`getMealsByIngredient()`/`getIngredientList()` (`list.php`), `getRandomMeal()` ahora traducida, `dispose()`.

**SpoonacularService** / **LocalRecipeService** / **AiRecipeGenerator** ver §7 y §6.4.

**AIService** ver §6.

**FavoritesService** ver §7.

---

## 12. Traducción

**`Translator`** (`lib/utils/translator.dart:1`):

- Cache LRU `_cache` 500, `clearCache()`.
- Diccionario local `_ingredientDict` (25: chicken→pollo, olive oil→aceite de oliva…) + `_measureDict` (17: cup→taza, tbsp→cda.) → `_localLookup` antes de red, traduce medidas compuestas (`1 cup` → `1 taza`).
- `translate(text)`: cache → local → `GoogleTranslator.translate(en→es).timeout(8s)` → LRU → fallback original.
- `category`/`area` diccionarios estáticos (14 categorías, 27 áreas).

Usado en `MealService` y `CategoryCard`/`Translator.category`.

---

## 13. Testing

**Ejecución:** `flutter test` (24 tests), `flutter test --coverage`.

| Suite | Archivo | Tests |
|-------|---------|-------|
| Timer | `test/utils/timer_parser_test.dart:1` | `detect minutes/hours/Spanish/null/mixed`, `format mm:ss/hours` |
| Translator | `test/utils/translator_test.dart:1` | `category/area`, `ingredient local`, `measure`, `empty`, `cache` |
| MealService | `test/services/meal_service_test.dart:1` | `getCategories parse`, `search null empty`, `error 500`, `SocketException friendly` (MockClient) |
| Gemini | `test/services/gemini_service_test.dart:1` | `RecipeSuggestion.fromJson int/string match_percent` |
| Widgets | `test/widgets/category_card_test.dart:1` | `translated name Ternera`, `onTap fires` |
| App | `test/widget_test.dart:1` | `RecipeApp smoke`, `Chef IA banner`, `shimmer loading` con `ProviderScope.overrideWith(categoriesProvider → [])` |

Mocks vía `http/testing.dart` `MockClient`, Riverpod `overrideWith` evita Hive en tests.

---

## 14. Análisis Estático

`analysis_options.yaml:11`

```yaml
include: package:flutter_lints/flutter.yaml
analyzer: {errors: {invalid_annotation_target: ignore}}
linter:
  rules: [avoid_print, avoid_empty_else, avoid_type_to_string, cancel_subscriptions, close_sinks, prefer_const_constructors, prefer_const_declarations, use_key_in_widget_constructors, sort_child_properties_last, avoid_returning_null_for_future, avoid_slow_async_io, use_build_context_synchronously]
```

`flutter analyze --no-pub` → `No issues found!` (previo 66 → 0 tras migrar `withOpacity` → `withValues`, `const` fixes).

`flutter gen-l10n` genera localizations sin errores ICU.

---

## 15. CI/CD

**Workflow** `.github/workflows/ci.yml:1`:

```yaml
on: [push main/develop, PR]
jobs:
  analyze-test: [checkout, subosito/flutter-action, flutter pub get, flutter gen-l10n, flutter analyze --fatal-infos, flutter test --coverage, flutter build apk --debug --dart-define=GEMINI_API_KEY=dummy_test_key]
  security: [grep pubspec.yaml .env, grep lib/ AIza]
```

Checks: `.env` no en `assets`, key hardcodeada.

**Launcher Icons** `pubspec.yaml:40` `flutter_launcher_icons: ^0.13.1` con `assets/images/Escudo_sabor.png` (`adaptive_icon_background #F8F4F0`).

---

## 16. Ejecución, Build y Deploy

**Requisitos:** Flutter stable, Dart `>=3.0.0`, Android Studio/Xcode.

```bash
flutter pub get
flutter gen-l10n
cp .env.example .env  # solo dev

# Solo TheMealDB + local (sin keys)
flutter run

# Óptimo FREE +5k + IA (Muse Spark + Spoonacular)
flutter run --dart-define=OPENROUTER_API_KEY=sk-or-... --dart-define=AI_PROVIDER=muse-spark --dart-define=SPOONACULAR_API_KEY=abc123

# Explorar filtros (usa nuevas áreas/ingredientes)
# Home → Explorar / Aleatoria / Mis recetas

# Crear receta local o generada por IA
# Home → Mis recetas → Nueva → botón IA

# Prod con proxy
flutter build apk --release --dart-define=GEMINI_PROXY_URL=https://api.tuapp.com/gemini
flutter build apk --release --dart-define=OPENROUTER_API_KEY=sk-or-... --dart-define=SPOONACULAR_API_KEY=...

flutter analyze --no-pub  # 0 issues
flutter test --coverage   # 24 tests
```

**Proxy** (`proxy/README.md:1`): Express Cloud Function `POST /analyze` con `process.env.GEMINI_API_KEY`, reenvía a `generativelanguage.googleapis.com`.

---

## 17. Seguridad

- `.env` en `.gitignore:16`, **no** en `flutter.assets` (`pubspec.yaml:48` solo `assets/images/`). `ApiKeyService` (`lib/utils/api_key_service.dart:4`) prioriza `String.fromEnvironment`.
- `proxy/README.md` para custodiar key en backend.
- CI `security` job valida no exponer key.
- `GEMINI_API_KEY` actual en `.env` debe rotarse si fue commiteada.

---

## 18. Roadmap

**Quick Wins (completados):** `withValues`, `AppTheme`, `ApiKeyService` dart-define, `MealService` timeout, `Translator` cache, `widget_test` fix.

**Medio Plazo (completados):** Riverpod + `MealRepository` + `AIService` abstraction, `Favorites` dual Hive/SQLite, `GeminiService` modularizado → `OpenRouterService`, `wakelock_plus`, widgets extraídos, `timer_parser` util.

**Largo Plazo (completados):** `flutter_localizations` ARB ES/EN, `GEMINI_PROXY_URL`, SQLite `AppDatabase` v3, `Translator` local dict, suite 24 tests, `analysis_options` estricto, CI.

**Recetario Ampliado (completado):** TheMealDB exprimido (`getAreas`/`getMealsByIngredient`/`getRandom` + `ExploreFiltersScreen`), Spoonacular `+5k` fallback, `user_recipes` CRUD SQLite (`uuid`) + `UserRecipesScreen`/`RecipeFormScreen` con generación IA (`AiRecipeGenerator` Muse Spark/Nemotron), `UnifiedRecipeRepository`, Home con quickActions + sección horizontal, `DOCUMENTATION.md` actualizado.

**Futuro:** Migrar `Text` hardcodeado → `AppLocalizations` total, Drift codegen cuando `meta` pin se libere, paginación/infinite scroll, filtros combinados (área+ingrediente), ratings/compartir, flavors `dev/prod`, golden tests.

---

*Documento actualizado para `cocina_estrella_app` — 2026-05-11. Recetario ampliado verificado vía `flutter analyze` 0 issues y `flutter test` 24/24. Stack: TheMealDB + Spoonacular + Local SQLite + IA Muse Spark/Nemotron free.*
