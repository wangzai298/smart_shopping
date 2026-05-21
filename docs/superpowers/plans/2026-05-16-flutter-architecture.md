# Flutter Client Architecture Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build Flutter 3.x client skeleton with Riverpod state management, Dio networking, go_router navigation, image_picker camera, and model layer matching server contracts (sections 6.1-6.3).

**Architecture:** Models mirror server JSON contracts exactly. ApiService wraps Dio with try-catch on all 3 endpoints. CameraService uses dart:ui for image decode/resize/encode (no extra native deps). SearchProvider uses Riverpod AsyncNotifier for loading/data/error states. FilterProvider uses StateNotifier for current filter + temporary input state.

**Tech Stack:** Flutter 3.x, Riverpod 2.5.1, Dio 5.4.0, go_router 10.0.0, fl_chart 0.68.0, image_picker 1.2.2

---

### Task 1: pubspec.yaml

Exact versions: dio 5.4.0, flutter_riverpod 2.5.1, go_router 10.0.0, fl_chart 0.68.0, image_picker 1.2.2

### Task 2: Models

- `product.dart`: PlatformPrice (platform, price double, shopType, url), Product (id, name, image, platformPrices List, lowestPrice double) with fromJson/toJson
- `filter.dart`: PriceRange (min double, max double), Filter (sort, priceRange?, shopType?, brand?, category?) with fromJson/toJson and toQueryParams

### Task 3: API Config + ApiService

- `api_config.dart`: baseUrl configurable per platform
- `api_service.dart`: Dio instance, uploadImage(String base64) → Product list, fetchHistory(String productId) → Map, sendFilter(String query, Map? context) → Filter

### Task 4: CameraService

- pickFromCamera() / pickFromGallery() using image_picker
- compressAndEncode(File) → String base64: read file, decode via dart:ui instantiateImageCodec, resize to ≤1024 on longest side, re-encode to PNG bytes, base64Encode

### Task 5: Providers

- `search_provider.dart`: AsyncNotifier<List<Product>> with search(imageBase64) method, states: AsyncLoading → AsyncData / AsyncError
- `filter_provider.dart`: StateNotifier<Filter> with applyFilter(Filter), resetFilter()

### Task 6: App Entry + Router

- `main.dart`: ProviderScope wrapping App
- `app.dart`: MaterialApp.router with go_router, 4 routes (/ → home, /camera → camera, /results → results, /detail/:id → detail), placeholder screen stubs
