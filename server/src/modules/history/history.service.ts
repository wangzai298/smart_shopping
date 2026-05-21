import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Product } from '../../entities/product.entity';
import { PriceHistory } from '../../entities/price-history.entity';

interface PricePoint {
  date: string;
  price: number;
}

interface LowestPrice {
  price: number;
  platform: string;
  date: string;
}

export interface HistoryResult {
  productId: string;
  lowestPrice: LowestPrice | null;
  platforms: Record<string, PricePoint[]>;
}

@Injectable()
export class HistoryService {
  constructor(
    @InjectRepository(Product)
    private productRepo: Repository<Product>,
    @InjectRepository(PriceHistory)
    private priceHistoryRepo: Repository<PriceHistory>,
  ) {}

  async getHistory(productId: string): Promise<HistoryResult | null> {
    const product = await this.productRepo.findOne({ where: { id: productId } });
    if (!product) {
      return null;
    }

    const records = await this.priceHistoryRepo.find({
      where: { productId },
      order: { date: 'ASC' },
    });

    const platforms: Record<string, PricePoint[]> = {};
    let overallLowest: { price: number; platform: string; date: string } | null = null;

    for (const record of records) {
      if (!platforms[record.platform]) {
        platforms[record.platform] = [];
      }
      const price = parseFloat(record.price as any);
      platforms[record.platform].push({
        date: record.date,
        price,
      });

      if (overallLowest === null || price < overallLowest.price) {
        overallLowest = { price, platform: record.platform, date: record.date };
      }
    }

    return { productId, lowestPrice: overallLowest, platforms };
  }
}
