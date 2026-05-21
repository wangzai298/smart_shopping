# Recognition Module Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build the image recognition module with Volcano Engine API integration (mock fallback when keys are empty), returning product matches with platform prices per section 6.1 schema.

**Architecture:** RecognitionService checks `accessKeyId` — if empty returns mock attributes then queries DB for matching products with latest prices; if set, calls Volcano Engine Visual Intelligence API with HMAC-SHA256 signature V4, parses response, then queries DB. RecognitionController exposes POST `/recognition/upload`. RecognitionModule imports TypeOrmModule.forFeature([Product, PriceHistory]).

**Tech Stack:** Nest.js 10, TypeORM 0.3, sql.js, Node.js crypto (for HMAC-SHA256), native fetch/https

---

### Task 1: Volcano Engine Config

**Files:**
- Create: `server/src/config/volcengine.config.ts`

```typescript
export const volcengineConfig = {
  accessKeyId: '',
  secretAccessKey: '',
  region: 'cn-north-1',
  service: 'visual',
  host: 'visual.volcengineapi.com',
  endpoint: 'https://visual.volcengineapi.com',
  productRecognitionAction: 'ProductRecognize',
  apiVersion: '2022-08-31',
};
```

### Task 2: UploadImage DTO

**Files:**
- Create: `server/src/modules/recognition/dto/upload-image.dto.ts`

```typescript
export class UploadImageDto {
  imageBase64: string;
}
```

### Task 3: Recognition Service

**Files:**
- Create: `server/src/modules/recognition/recognition.service.ts`

Full service with:
- `recognize(imageBase64: string)` method
- `if (!this.config.accessKeyId)` mock branch returning section 7 mock data + DB query
- `else` real API branch with Volcengine signature V4 (HMAC-SHA256), HTTP POST, parse + DB query
- `signRequest()` private method for canonical request → string to sign → signing key → signature
- `buildAuthorization()` private method for Authorization header
- DB query: fuzzy match products by category LIKE, then subquery latest price per platform per product, compute lowestPrice

Mock response format (section 6.1):
```json
{
  "success": true,
  "data": {
    "category": "运动鞋",
    "brand": "Nike",
    "attributes": { "color": "黑白", "style": "休闲" },
    "products": [
      {
        "id": "uuid-1",
        "name": "Nike Air Max 90 黑白",
        "image": "https://example.com/nike-air-max-90.jpg",
        "platformPrices": [
          { "platform": "淘宝", "price": 799, "shopType": "C店", "url": "#" },
          { "platform": "京东", "price": 849, "shopType": "旗舰店", "url": "#" },
          { "platform": "拼多多", "price": 769, "shopType": "旗舰店", "url": "#" }
        ],
        "lowestPrice": 769
      },
      {
        "id": "uuid-2",
        "name": "Adidas Ultraboost 22 白色",
        "image": "https://example.com/adidas-ultraboost-22.jpg",
        "platformPrices": [
          { "platform": "淘宝", "price": 999, "shopType": "C店", "url": "#" },
          { "platform": "京东", "price": 1049, "shopType": "旗舰店", "url": "#" },
          { "platform": "拼多多", "price": 949, "shopType": "旗舰店", "url": "#" }
        ],
        "lowestPrice": 949
      }
    ]
  }
}
```

### Task 4: Recognition Controller

**Files:**
- Create: `server/src/modules/recognition/recognition.controller.ts`

```typescript
import { Controller, Post, Body } from '@nestjs/common';
import { RecognitionService } from './recognition.service';
import { UploadImageDto } from './dto/upload-image.dto';

@Controller('recognition')
export class RecognitionController {
  constructor(private readonly recognitionService: RecognitionService) {}

  @Post('upload')
  async upload(@Body() dto: UploadImageDto) {
    const data = await this.recognitionService.recognize(dto.imageBase64);
    return { success: true, data };
  }
}
```

### Task 5: Recognition Module

**Files:**
- Create: `server/src/modules/recognition/recognition.module.ts`

```typescript
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Product } from '../../entities/product.entity';
import { PriceHistory } from '../../entities/price-history.entity';
import { RecognitionController } from './recognition.controller';
import { RecognitionService } from './recognition.service';

@Module({
  imports: [TypeOrmModule.forFeature([Product, PriceHistory])],
  controllers: [RecognitionController],
  providers: [RecognitionService],
})
export class RecognitionModule {}
```

### Task 6: Wire into AppModule

**Files:**
- Modify: `server/src/app.module.ts:3-6`

Add `import { RecognitionModule } from './modules/recognition/recognition.module';` and add `RecognitionModule` to imports array.

### Task 7: Verify

- Start server, POST to /recognition/upload with `{"imageBase64":"test"}`, verify response matches section 6.1 schema
- Confirm mock branch is taken (check server logs or response content)
