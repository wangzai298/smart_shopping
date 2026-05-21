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
