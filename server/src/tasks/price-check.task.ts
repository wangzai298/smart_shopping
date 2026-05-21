import { Processor, Process } from '@nestjs/bull';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Logger } from '@nestjs/common';
import { Job } from 'bull';
import { PriceAlert } from '../entities/price-alert.entity';
import { PriceHistory } from '../entities/price-history.entity';

@Processor('price-check')
export class PriceCheckProcessor {
  private readonly logger = new Logger(PriceCheckProcessor.name);

  constructor(
    @InjectRepository(PriceAlert)
    private alertRepo: Repository<PriceAlert>,
    @InjectRepository(PriceHistory)
    private priceRepo: Repository<PriceHistory>,
  ) {}

  @Process('scan')
  async handleScan(job: Job) {
    this.logger.log('[PriceCheck] Starting hourly scan...');

    const activeAlerts = await this.alertRepo.find({ where: { isActive: true } });
    this.logger.log(`[PriceCheck] Found ${activeAlerts.length} active alerts`);

    for (const alert of activeAlerts) {
      const latestPrices = await this.priceRepo
        .createQueryBuilder('ph')
        .select('ph.price', 'price')
        .where('ph.productId = :pid', { pid: alert.productId })
        .andWhere((qb) => {
          const sub = qb.subQuery()
            .select('MAX(ph2.date)', 'maxDate')
            .from('price_history', 'ph2')
            .where('ph2.productId = ph.productId')
            .andWhere('ph2.platform = ph.platform')
            .getQuery();
          return 'ph.date = ' + sub;
        })
        .getRawMany();

      const prices = latestPrices.map((p: any) => parseFloat(p.price));
      const currentMin = prices.length > 0 ? Math.min(...prices) : Infinity;

      if (currentMin <= alert.targetPrice) {
        this.logger.log(
          `[PriceCheck] ALERT: Product ${alert.productId} price ${currentMin} <= target ${alert.targetPrice} for user ${alert.userId}`,
        );
        // TODO: FCM push notification via NotificationService
      }
    }

    this.logger.log('[PriceCheck] Scan complete');
  }
}
