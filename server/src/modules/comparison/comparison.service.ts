import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Product } from '../../entities/product.entity';
import { PriceHistory } from '../../entities/price-history.entity';

interface PlatformPrice {
  platform: string;
  price: number;
  shopType: string;
  url: string;
}

export interface ComparisonResult {
  productId: string;
  productName: string;
  platformPrices: PlatformPrice[];
  lowestPrice: number;
  lowestPlatform: string;
}

const SHOP_TYPE_MAP: Record<string, string> = {
  '淘宝': 'C店',
  '京东': '旗舰店',
  '拼多多': '旗舰店',
};

@Injectable()
export class ComparisonService {
  constructor(
    @InjectRepository(Product)
    private productRepo: Repository<Product>,
    @InjectRepository(PriceHistory)
    private priceHistoryRepo: Repository<PriceHistory>,
  ) {}

  async compare(productId: string): Promise<ComparisonResult | null> {
    const product = await this.productRepo.findOne({ where: { id: productId } });
    if (!product) {
      return null;
    }

    const latestPrices = await this.priceHistoryRepo
      .createQueryBuilder('ph')
      .select('ph.platform', 'platform')
      .addSelect('ph.price', 'price')
      .where('ph.productId = :productId', { productId })
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

    let lowestPrice = 0;
    let lowestPlatform = '';

    if (platformPrices.length > 0) {
      const min = platformPrices.reduce((prev, curr) =>
        prev.price < curr.price ? prev : curr,
      );
      lowestPrice = min.price;
      lowestPlatform = min.platform;
    }

    return {
      productId: product.id,
      productName: product.name,
      platformPrices,
      lowestPrice,
      lowestPlatform,
    };
  }
}
