import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { SearchHistory } from '../../entities/search-history.entity';

@Injectable()
export class SearchHistoryService {
  constructor(
    @InjectRepository(SearchHistory) private repo: Repository<SearchHistory>,
  ) {}

  async save(userId: string | null, imageUrl: string, resultSnapshot: any) {
    const item = await this.repo.save({ userId: userId || undefined, imageUrl, resultSnapshot } as any);
    return { id: (item as any).id };
  }

  async findByUser(userId: string, limit = 20) {
    return this.repo.find({ where: { userId }, order: { createdAt: 'DESC' }, take: limit });
  }

  async deleteForUser(userId: string, id?: number) {
    if (id) {
      await this.repo.delete({ id, userId });
    } else {
      await this.repo.delete({ userId });
    }
    return { message: '已删除' };
  }
}
