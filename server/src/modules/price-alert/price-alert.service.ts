import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { PriceAlert } from '../../entities/price-alert.entity';

@Injectable()
export class PriceAlertService {
  constructor(
    @InjectRepository(PriceAlert) private repo: Repository<PriceAlert>,
  ) {}

  async listByUser(userId: string) {
    return this.repo.find({ where: { userId }, order: { createdAt: 'DESC' } });
  }

  async create(userId: string, dto: { productId: string; targetPrice: number; platform?: string }) {
    const alert = await this.repo.save({ userId, productId: dto.productId, targetPrice: dto.targetPrice, platform: dto.platform, isActive: true });
    return alert;
  }

  async update(userId: string, id: number, dto: { isActive?: boolean; targetPrice?: number }) {
    const alert = await this.repo.findOne({ where: { id, userId } });
    if (!alert) throw new NotFoundException('提醒不存在');
    await this.repo.update(id, dto);
    return this.repo.findOne({ where: { id } });
  }

  async delete(userId: string, id: number) {
    await this.repo.delete({ id, userId });
    return { message: '已删除' };
  }
}
