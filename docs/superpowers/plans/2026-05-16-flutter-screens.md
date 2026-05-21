# Flutter Screens & Widgets Implementation Plan

**Goal:** Build 4 screens (home, camera, results, detail) + 3 reusable widgets (loading, error, empty) + 2 results sub-widgets (product_card, price_trend_chart). Every screen covers loading/error/empty/data 4 states.

**Architecture:** Screens consume Riverpod providers (searchProvider, filterProvider, nlpFilterProvider). CameraScreen orchestrates CameraService → compress → searchProvider. ResultsScreen watches searchProvider and filters client-side. DetailScreen fetches history/comparison reactively. Reusable widgets accept callbacks for retry/action.

---

### Files to create (10):

| # | File | Responsibility |
|---|------|---------------|
| 1 | `widgets/loading_widget.dart` | Centered spinner + optional text |
| 2 | `widgets/app_error_widget.dart` | Error icon + message + retry button |
| 3 | `widgets/empty_widget.dart` | Icon + message for no-data state |
| 4 | `screens/home_screen.dart` | Landing page: camera button + instructions |
| 5 | `screens/camera_screen.dart` | Pick → preview → compress → upload → navigate |
| 6 | `screens/results_screen.dart` | Filter input + async product list (4-state) |
| 7 | `screens/results_screen/widgets/product_card.dart` | Card: image, name, platform rows, shop type chips |
| 8 | `screens/results_screen/widgets/price_trend_chart.dart` | fl_chart multi-line per platform |
| 9 | `screens/detail_screen.dart` | Product info + chart + platform prices |
| 10 | `app.dart` (modify) | Replace placeholder screens with real imports |

### 4-state pattern per screen:

```
AsyncValue.when(
  loading: () => LoadingWidget(),
  error: (e, _) => AppErrorWidget(onRetry: ...),
  data: (d) => d.isEmpty ? EmptyWidget() : DataView(d),
)
```

### Chart colors:
- 淘宝: orange, 京东: red, 拼多多: teal
