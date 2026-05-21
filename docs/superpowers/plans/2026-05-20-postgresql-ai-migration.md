# PostgreSQL Migration & AI Unification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Migrate database from SQLite to PostgreSQL, unify AI services from Volcano+Doubao to single Doubao multimodal API, and update all documentation.

**Architecture:** PostgreSQL via TypeORM pg driver replaces sql.js. Single doubao.config.ts replaces volcengine.config.ts + doubao.config.ts. Recognition service rewritten to use OpenAI-compatible Doubao multimodal API instead of Volcano V4 HMAC-SHA256.

**Tech Stack:** Node.js 18, Nest.js 10, TypeORM 0.3, pg, TypeScript 5.x, PostgreSQL

---

### Task 1: Update package.json — replace sql.js with pg

**Files:**
- Modify: `server/package.json`

- [ ] **Step 1: Replace sql.js dependency with pg**

Change the dependencies section — remove `"sql.js": "^1.10.0"` and add `"pg": "^8.13.0"`.

```json
{
  "dependencies": {
    "@nestjs/common": "^10.4.15",
    "@nestjs/core": "^10.4.15",
    "@nestjs/platform-express": "^10.4.15",
    "@nestjs/typeorm": "^10.0.2",
    "reflect-metadata": "^0.2.2",
    "rxjs": "^7.8.1",
    "pg": "^8.13.0",
    "typeorm": "^0.3.20"
  }
}
```

- [ ] **Step 2: Run npm install**

```bash
cd server && npm install
```

---

### Task 2: Update database.config.ts — PostgreSQL connection

**Files:**
- Modify: `server/src/config/database.config.ts`

- [ ] **Step 1: Rewrite for PostgreSQL**

```typescript
import { TypeOrmModuleOptions } from '@nestjs/typeorm';
import { Product } from '../entities/product.entity';
import { PriceHistory } from '../entities/price-history.entity';

export const databaseConfig: TypeOrmModuleOptions = {
  type: 'postgres',
  host: 'localhost',
  port: 5432,
  username: 'postgres',
  password: '298556',
  database: 'smart_shopping',
  entities: [Product, PriceHistory],
  synchronize: true,
};
```

---

### Task 3: Update Product Entity — jsonb type

**Files:**
- Modify: `server/src/entities/product.entity.ts`

- [ ] **Step 1: Change attributes column from simple-json to jsonb**

```typescript
import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';

@Entity('products')
export class Product {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'text' })
  name: string;

  @Column({ type: 'text' })
  category: string;

  @Column({ type: 'text' })
  brand: string;

  @Column({ type: 'jsonb', nullable: true })
  attributes: Record<string, string>;

  @Column({ type: 'text', nullable: true })
  imageUrl: string;
}
```

---

### Task 4: Update PriceHistory Entity — decimal + date types

**Files:**
- Modify: `server/src/entities/price-history.entity.ts`

- [ ] **Step 1: Change price to decimal(10,2) and date to date type**

```typescript
import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';

@Entity('price_history')
export class PriceHistory {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ type: 'text' })
  productId: string;

  @Column({ type: 'text' })
  platform: string;

  @Column({ type: 'decimal', precision: 10, scale: 2 })
  price: number;

  @Column({ type: 'date' })
  date: string;
}
```

---

### Task 5: Delete volcengine.config.ts

**Files:**
- Delete: `server/src/config/volcengine.config.ts`

- [ ] **Step 1: Delete the file**

```bash
rm server/src/config/volcengine.config.ts
```

---

### Task 6: Update doubao.config.ts — unified multimodal API

**Files:**
- Modify: `server/src/config/doubao.config.ts`

- [ ] **Step 1: Update to multimodal endpoint with model config**

```typescript
export const doubaoConfig = {
  apiKey: '',
  endpoint: 'https://ark.cn-beijing.volces.com/api/v3/responses',
  model: '',
};
```

---

### Task 7: Rewrite recognition.service.ts — Doubao multimodal API

**Files:**
- Modify: `server/src/modules/recognition/recognition.service.ts`

- [ ] **Step 1: Replace Volcano V4 signature logic with Doubao multimodal API call**

```typescript
import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Product } from '../../entities/product.entity';
import { PriceHistory } from '../../entities/price-history.entity';
import { doubaoConfig } from '../../config/doubao.config';

interface PlatformPrice {
  platform: string;
  price: number;
  shopType: string;
  url: string;
}

interface ProductResult {
  id: string;
  name: string;
  image: string;
  platformPrices: PlatformPrice[];
  lowestPrice: number;
}

export interface RecognitionData {
  category: string;
  brand: string;
  attributes: Record<string, string>;
  products: ProductResult[];
}

const SHOP_TYPE_MAP: Record<string, string> = {
  '淘宝': 'C店',
  '京东': '旗舰店',
  '拼多多': '旗舰店',
};

@Injectable()
export class RecognitionService {
  private readonly logger = new Logger(RecognitionService.name);

  constructor(
    @InjectRepository(Product)
    private productRepo: Repository<Product>,
    @InjectRepository(PriceHistory)
    private priceHistoryRepo: Repository<PriceHistory>,
  ) {}

  async recognize(imageBase64: string): Promise<RecognitionData> {
    let category: string;
    let brand: string;
    let attributes: Record<string, string>;

    if (!doubaoConfig.apiKey) {
      this.logger.log('apiKey is empty, using mock recognition data');
      const mock = this.getMockResult();
      category = mock.category;
      brand = mock.brand;
      attributes = mock.attributes;
    } else {
      this.logger.log('Calling Doubao Multimodal API for product recognition');
      const result = await this.callDoubaoVisionAPI(imageBase64);
      category = result.category;
      brand = result.brand;
      attributes = result.attributes;
    }

    const products = await this.matchProducts(category, brand);

    return { category, brand, attributes, products };
  }

  private getMockResult(): { category: string; brand: string; attributes: Record<string, string> } {
    return {
      category: '运动鞋',
      brand: 'Nike',
      attributes: { color: '黑白', style: '休闲' },
    };
  }

  private async matchProducts(category: string, brand: string): Promise<ProductResult[]> {
    const where: any = {};
    if (category) {
      where.category = category;
    }

    const products = await this.productRepo.find({ where });
    const results: ProductResult[] = [];

    for (const product of products) {
      const latestPrices = await this.priceHistoryRepo
        .createQueryBuilder('ph')
        .select('ph.platform', 'platform')
        .addSelect('ph.price', 'price')
        .where('ph.productId = :productId', { productId: product.id })
        .andWhere((qb) => {
          const subQuery = qb
            .subQuery()
            .select('MAX(ph2.date)', 'maxDate')
            .from('price_history', 'ph2')
            .where('ph2.productId = ph.productId')
            .andWhere('ph2.platform = ph.platform')
            .getQuery();
          return 'ph.date = ' + subQuery;
        })
        .getRawMany();

      const platformPrices: PlatformPrice[] = latestPrices.map((p) => ({
        platform: p.platform,
        price: parseFloat(p.price),
        shopType: SHOP_TYPE_MAP[p.platform] || 'C店',
        url: '#',
      }));

      const prices = platformPrices.map((p) => p.price);
      const lowestPrice = prices.length > 0 ? Math.min(...prices) : 0;

      results.push({
        id: product.id,
        name: product.name,
        image: product.imageUrl || '',
        platformPrices,
        lowestPrice,
      });
    }

    return results;
  }

  // ── Doubao Multimodal API (OpenAI-compatible) ──

  private async callDoubaoVisionAPI(
    imageBase64: string,
  ): Promise<{ category: string; brand: string; attributes: Record<string, string> }> {
    const systemPrompt = [
      '你是一个商品识别助手。根据用户提供的商品图片，识别商品类别、品牌和属性。',
      '',
      '只返回 JSON，格式如下：',
      '{',
      '  "category": "商品类目",',
      '  "brand": "品牌",',
      '  "attributes": { "颜色": "...", "款式": "..." }',
      '}',
    ].join('\n');

    const body = JSON.stringify({
      model: doubaoConfig.model,
      messages: [
        { role: 'system', content: systemPrompt },
        {
          role: 'user',
          content: [
            {
              type: 'image_url',
              image_url: { url: `data:image/jpeg;base64,${imageBase64}` },
            },
            {
              type: 'text',
              text: '请识别图中的商品类别、品牌、颜色等属性。',
            },
          ],
        },
      ],
      temperature: 0.1,
      max_tokens: 256,
    });

    const response = await fetch(doubaoConfig.endpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${doubaoConfig.apiKey}`,
      },
      body,
    });

    const json: Record<string, any> = (await response.json()) as Record<string, any>;
    this.logger.log(`Doubao Vision API response: ${JSON.stringify(json)}`);

    const content = json?.choices?.[0]?.message?.content || '{}';

    try {
      const jsonMatch = content.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        const parsed = JSON.parse(jsonMatch[0]);
        return {
          category: parsed.category || '',
          brand: parsed.brand || '',
          attributes: parsed.attributes || {},
        };
      }
    } catch {
      this.logger.warn('Failed to parse Doubao Vision response as JSON, using mock');
    }

    return this.getMockResult();
  }
}
```

---

### Task 8: Update product.service.ts — ILIKE for PostgreSQL

**Files:**
- Modify: `server/src/modules/product/product.service.ts`

- [ ] **Step 1: Replace Like with ILIKE, parse decimal price**

```typescript
import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, ILike } from 'typeorm';
import { Product } from '../../entities/product.entity';
import { PriceHistory } from '../../entities/price-history.entity';

interface PlatformPrice {
  platform: string;
  price: number;
  shopType: string;
  url: string;
}

export interface ProductResult {
  id: string;
  name: string;
  image: string;
  platformPrices: PlatformPrice[];
  lowestPrice: number;
}

const SHOP_TYPE_MAP: Record<string, string> = {
  '淘宝': 'C店',
  '京东': '旗舰店',
  '拼多多': '旗舰店',
};

@Injectable()
export class ProductService {
  constructor(
    @InjectRepository(Product)
    private productRepo: Repository<Product>,
    @InjectRepository(PriceHistory)
    private priceHistoryRepo: Repository<PriceHistory>,
  ) {}

  async search(category?: string, brand?: string): Promise<ProductResult[]> {
    const where: any = {};
    if (category) {
      where.category = ILike(`%${category}%`);
    }
    if (brand) {
      where.brand = ILike(`%${brand}%`);
    }

    const products = await this.productRepo.find({ where });
    const results: ProductResult[] = [];

    for (const product of products) {
      const latestPrices = await this.priceHistoryRepo
        .createQueryBuilder('ph')
        .select('ph.platform', 'platform')
        .addSelect('ph.price', 'price')
        .where('ph.productId = :productId', { productId: product.id })
        .andWhere((qb) => {
          const subQuery = qb
            .subQuery()
            .select('MAX(ph2.date)', 'maxDate')
            .from('price_history', 'ph2')
            .where('ph2.productId = ph.productId')
            .andWhere('ph2.platform = ph.platform')
            .getQuery();
          return 'ph.date = ' + subQuery;
        })
        .getRawMany();

      const platformPrices: PlatformPrice[] = latestPrices.map((p) => ({
        platform: p.platform,
        price: parseFloat(p.price),
        shopType: SHOP_TYPE_MAP[p.platform] || 'C店',
        url: '#',
      }));

      const prices = platformPrices.map((p) => p.price);
      const lowestPrice = prices.length > 0 ? Math.min(...prices) : 0;

      results.push({
        id: product.id,
        name: product.name,
        image: product.imageUrl || '',
        platformPrices,
        lowestPrice,
      });
    }

    return results;
  }
}
```

---

### Task 9: Update comparison.service.ts — parse decimal price

**Files:**
- Modify: `server/src/modules/comparison/comparison.service.ts`

- [ ] **Step 1: Add parseFloat for decimal price values**

In the platformPrices mapping, change `price: p.price` to `price: parseFloat(p.price)`. Rest unchanged.

---

### Task 10: Update seed.service.ts — date format "YYYY-MM-DD"

**Files:**
- Modify: `server/src/modules/seed/seed.service.ts`

- [ ] **Step 1: Change PRICE_MONTHS from "YYYY-MM" to "YYYY-MM-DD"**

Change:
```typescript
const PRICE_MONTHS = ['2025-01', '2025-02', '2025-03', '2025-04', '2025-05', '2025-06'];
```
To:
```typescript
const PRICE_MONTHS = ['2025-01-01', '2025-02-01', '2025-03-01', '2025-04-01', '2025-05-01', '2025-06-01'];
```

---

### Task 11: Update nlp.service.ts — endpoint already uses doubaoConfig

**Files:**
- Modify: `server/src/modules/nlp/nlp.service.ts`

- [ ] **Step 1: No code change needed**

The NLP service already reads from `doubaoConfig`. The config file update (Task 6) changes the endpoint. No further changes needed.

---

### Task 12: Update 项目说明.txt — reflect all changes

**Files:**
- Modify: `项目说明.txt`

Key updates:
- §二 技术栈: SQLite → PostgreSQL (pg driver), AI → 豆包多模态大模型API
- §三 目录结构: Remove volcengine.config.ts reference, update doubao.config.ts description, database.config.ts now PostgreSQL
- §四 数据库表结构: date format "YYYY-MM-DD", price type decimal(10,2), attributes jsonb
- §七 关键设计决策: Update sql.js rationale → pg rationale

---

### Task 13: Update 配置清单.txt — reflect all changes

**Files:**
- Modify: `配置清单.txt`

Key updates:
- Remove §一火山引擎 (no longer separate API)
- §一 now only 豆包大模型API Key (unified, single key for both vision + text)
- Remove PostgreSQL connection info (now hardcoded with password)
- Keep LAN IP and 鸿蒙 sections
```

---

### Task 14: Verify server starts and seed endpoint works

- [ ] **Step 1: Start server and verify**

```bash
cd server && npm start
# Test: curl http://localhost:3000/seed/init
```

- [ ] **Step 2: Test recognition mock endpoint**

```bash
curl -X POST http://localhost:3000/recognition/upload -H "Content-Type: application/json" -d '{"imageBase64":"dGVzdA=="}'
```
