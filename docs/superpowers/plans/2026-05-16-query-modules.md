# Product / Comparison / History Modules Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build three query modules — product search (fuzzy match + latest prices), comparison aggregation (per-platform lowest), price history (section 6.2 grouped time series) — all with graceful empty-result handling.

**Architecture:** Each module follows the Nest.js pattern: Module → Controller → Service → TypeORM Repository. Product service uses LIKE for fuzzy matching and subquery for latest prices (same pattern as RecognitionService.matchProducts). Comparison service subqueries latest price per platform then computes min. History service groups all PriceHistory rows by platform.

**Tech Stack:** Nest.js 10, TypeORM 0.3, sql.js (no new dependencies)

---

### Task 1: Product Module (search)

**Files:**
- Create: `server/src/modules/product/product.module.ts`
- Create: `server/src/modules/product/product.controller.ts`
- Create: `server/src/modules/product/product.service.ts`

ProductService.search(category?, brand?): uses LIKE `%value%` on both fields, then for each matched product subqueries latest platform prices (MAX date per platform), computes lowestPrice. Returns `ProductResult[]`.

Controller: `GET /products/search?category=&brand=` wraps result in `{ success: true, data }`.

Empty result: returns `{ success: true, data: [] }`.

### Task 2: Comparison Module

**Files:**
- Create: `server/src/modules/comparison/comparison.module.ts`
- Create: `server/src/modules/comparison/comparison.controller.ts`
- Create: `server/src/modules/comparison/comparison.service.ts`

ComparisonService.compare(productId): looks up product, subqueries latest price per platform, finds overall lowestPrice. Returns `{ productId, productName, platformPrices, lowestPrice, lowestPlatform }`.

Controller: `GET /comparison/:productId` wraps in `{ success: true, data }`.

Empty result: product not found → `{ success: true, data: null, message: "Product not found" }`.

### Task 3: History Module

**Files:**
- Create: `server/src/modules/history/history.module.ts`
- Create: `server/src/modules/history/history.controller.ts`
- Create: `server/src/modules/history/history.service.ts`

HistoryService.getHistory(productId): finds all PriceHistory rows for productId, groups by platform, sorts each platform's entries by date ascending. Returns `{ productId, platforms: Record<string, {date, price}[]> }` matching section 6.2 schema.

Controller: `GET /products/:id/history` wraps in `{ success: true, data }`.

Empty result: product not found or no history → `{ success: true, data: { productId, platforms: {} } }`.

### Task 4: Wire AppModule

**Files:**
- Modify: `server/src/app.module.ts` — add ProductModule, ComparisonModule, HistoryModule to imports.

### Task 5: Verify

- Compile TypeScript
- Start server, seed data
- Test all three endpoints with valid and invalid params
- Confirm empty-result handling
