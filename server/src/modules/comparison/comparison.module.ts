import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Product } from '../../entities/product.entity';
import { PriceHistory } from '../../entities/price-history.entity';
import { ComparisonController } from './comparison.controller';
import { ComparisonService } from './comparison.service';

@Module({
  imports: [TypeOrmModule.forFeature([Product, PriceHistory])],
  controllers: [ComparisonController],
  providers: [ComparisonService],
})
export class ComparisonModule {}
