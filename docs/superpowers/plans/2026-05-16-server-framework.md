# Server Basic Framework & Data Layer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build Nest.js server skeleton with TypeORM+SQLite data layer, entity definitions, and mock seed data per 任务说明.txt specs.

**Architecture:** Nest.js 10 + TypeORM 0.3 + better-sqlite3 9.x. Single AppModule importing TypeOrmModule.forRoot and SeedModule. Two entities (Product, PriceHistory) with mock data seeded via SeedService.

**Tech Stack:** Node.js 18, Nest.js 10, TypeORM 0.3, better-sqlite3 9.x, TypeScript 5.x

---

### Task 1: package.json

**Files:**
- Create: `server/package.json`

- [ ] **Step 1: Write package.json with all required deps**

```json
{
  "name": "smart-shopping-assistant-server",
  "version": "1.0.0",
  "description": "Smart Shopping Assistant - Nest.js Server",
  "private": true,
  "scripts": {
    "start": "ts-node src/main.ts",
    "start:dev": "ts-node src/main.ts",
    "build": "tsc"
  },
  "dependencies": {
    "@nestjs/common": "^10.4.15",
    "@nestjs/core": "^10.4.15",
    "@nestjs/platform-express": "^10.4.15",
    "@nestjs/typeorm": "^10.0.2",
    "typeorm": "^0.3.20",
    "better-sqlite3": "^9.6.0",
    "reflect-metadata": "^0.2.2",
    "rxjs": "^7.8.1"
  },
  "devDependencies": {
    "@types/node": "^20.14.0",
    "typescript": "^5.5.0",
    "ts-node": "^10.9.2"
  }
}
```

### Task 2: tsconfig.json

**Files:**
- Create: `server/tsconfig.json`

- [ ] **Step 1: Write tsconfig.json with decorator support**

```json
{
  "compilerOptions": {
    "target": "ES2021",
    "module": "commonjs",
    "lib": ["ES2021"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "experimentalDecorators": true,
    "emitDecoratorMetadata": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

### Task 3: Database Config

**Files:**
- Create: `server/src/config/database.config.ts`

- [ ] **Step 1: Write TypeORM SQLite configuration**

```typescript
import { TypeOrmModuleOptions } from '@nestjs/typeorm';
import { Product } from '../entities/product.entity';
import { PriceHistory } from '../entities/price-history.entity';
import * as path from 'path';

export const databaseConfig: TypeOrmModuleOptions = {
  type: 'better-sqlite3',
  database: path.join(__dirname, '..', '..', 'data', 'shopping.db'),
  entities: [Product, PriceHistory],
  synchronize: true,
};
```

### Task 4: Product Entity

**Files:**
- Create: `server/src/entities/product.entity.ts`

- [ ] **Step 1: Write Product entity**

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

  @Column({ type: 'simple-json', nullable: true })
  attributes: Record<string, string>;

  @Column({ type: 'text', nullable: true })
  imageUrl: string;
}
```

### Task 5: PriceHistory Entity

**Files:**
- Create: `server/src/entities/price-history.entity.ts`

- [ ] **Step 1: Write PriceHistory entity**

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

  @Column({ type: 'real' })
  price: number;

  @Column({ type: 'text' })
  date: string;
}
```

### Task 6: Seed Service

**Files:**
- Create: `server/src/modules/seed/seed.service.ts`

- [ ] **Step 1: Write SeedService with mock data**

```typescript
import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Product } from '../../entities/product.entity';
import { PriceHistory } from '../../entities/price-history.entity';

@Injectable()
export class SeedService {
  constructor(
    @InjectRepository(Product)
    private productRepo: Repository<Product>,
    @InjectRepository(PriceHistory)
    private priceHistoryRepo: Repository<PriceHistory>,
  ) {}

  async init(): Promise<{ message: string }> {
    // Clear existing data
    await this.priceHistoryRepo.delete({});
    await this.productRepo.delete({});

    // Product 1: Nike Air Max 90 黑白
    const product1 = await this.productRepo.save({
      id: 'uuid-1',
      name: 'Nike Air Max 90 黑白',
      category: '运动鞋',
      brand: 'Nike',
      attributes: { color: '黑白', style: '休闲' },
      imageUrl: 'https://example.com/nike-air-max-90.jpg',
    });

    const p1History = [
      { productId: product1.id, platform: '淘宝', price: 899, date: '2025-01' },
      { productId: product1.id, platform: '淘宝', price: 799, date: '2025-02' },
      { productId: product1.id, platform: '京东', price: 899, date: '2025-01' },
      { productId: product1.id, platform: '京东', price: 849, date: '2025-02' },
      { productId: product1.id, platform: '拼多多', price: 809, date: '2025-01' },
      { productId: product1.id, platform: '拼多多', price: 769, date: '2025-02' },
    ];
    await this.priceHistoryRepo.save(p1History);

    // Product 2: Adidas Ultraboost 22 白色
    const product2 = await this.productRepo.save({
      id: 'uuid-2',
      name: 'Adidas Ultraboost 22 白色',
      category: '运动鞋',
      brand: 'Adidas',
      attributes: { color: '白色', style: '跑步' },
      imageUrl: 'https://example.com/adidas-ultraboost-22.jpg',
    });

    const p2History = [
      { productId: product2.id, platform: '淘宝', price: 1099, date: '2025-01' },
      { productId: product2.id, platform: '淘宝', price: 999, date: '2025-02' },
      { productId: product2.id, platform: '京东', price: 1099, date: '2025-01' },
      { productId: product2.id, platform: '京东', price: 1049, date: '2025-02' },
      { productId: product2.id, platform: '拼多多', price: 1049, date: '2025-01' },
      { productId: product2.id, platform: '拼多多', price: 949, date: '2025-02' },
    ];
    await this.priceHistoryRepo.save(p2History);

    return { message: 'Seed data initialized: 2 products, 12 price history records' };
  }
}
```

### Task 7: Seed Controller

**Files:**
- Create: `server/src/modules/seed/seed.controller.ts`

- [ ] **Step 1: Write SeedController**

```typescript
import { Controller, Get } from '@nestjs/common';
import { SeedService } from './seed.service';

@Controller('seed')
export class SeedController {
  constructor(private readonly seedService: SeedService) {}

  @Get('init')
  async init() {
    return { success: true, data: await this.seedService.init() };
  }
}
```

### Task 8: Seed Module

**Files:**
- Create: `server/src/modules/seed/seed.module.ts`

```typescript
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Product } from '../../entities/product.entity';
import { PriceHistory } from '../../entities/price-history.entity';
import { SeedController } from './seed.controller';
import { SeedService } from './seed.service';

@Module({
  imports: [TypeOrmModule.forFeature([Product, PriceHistory])],
  controllers: [SeedController],
  providers: [SeedService],
})
export class SeedModule {}
```

### Task 9: App Module

**Files:**
- Create: `server/src/app.module.ts`

- [ ] **Step 1: Write AppModule with TypeORM + SeedModule**

```typescript
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { databaseConfig } from './config/database.config';
import { SeedModule } from './modules/seed/seed.module';

@Module({
  imports: [TypeOrmModule.forRoot(databaseConfig), SeedModule],
})
export class AppModule {}
```

### Task 10: Main Entry

**Files:**
- Create: `server/src/main.ts`

- [ ] **Step 1: Write main.ts with CORS enabled**

```typescript
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.enableCors();
  await app.listen(3000);
  console.log('Server running on http://localhost:3000');
}
bootstrap();
```

### Task 11: Install dependencies and verify

- [ ] **Step 1: Run npm install**

```bash
cd server && npm install
```

- [ ] **Step 2: Start server and verify seed endpoint**

```bash
npm run start:dev
# Test: curl http://localhost:3000/seed/init
```
