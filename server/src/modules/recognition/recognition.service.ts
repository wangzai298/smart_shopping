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

  async recognize(images: string[]): Promise<RecognitionData> {
    const imageBase64 = Array.isArray(images) && images.length > 0 ? images[0] : '';
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
