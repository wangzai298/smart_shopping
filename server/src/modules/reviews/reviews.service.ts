import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ReviewSummary } from '../../entities/review-summary.entity';

@Injectable()
export class ReviewsService {
  constructor(
    @InjectRepository(ReviewSummary) private repo: Repository<ReviewSummary>,
  ) {}

  async getByProduct(productId: string) {
    return this.repo.find({ where: { productId } });
  }
}
