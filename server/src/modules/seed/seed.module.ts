import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Product } from '../../entities/product.entity';
import { PriceHistory } from '../../entities/price-history.entity';
import { User } from '../../entities/user.entity';
import { ReviewSummary } from '../../entities/review-summary.entity';
import { FavoriteList } from '../../entities/favorite-list.entity';
import { FavoriteItem } from '../../entities/favorite-item.entity';
import { SeedController } from './seed.controller';
import { SeedService } from './seed.service';

@Module({
  imports: [TypeOrmModule.forFeature([Product, PriceHistory, User, ReviewSummary, FavoriteList, FavoriteItem])],
  controllers: [SeedController],
  providers: [SeedService],
})
export class SeedModule {}
