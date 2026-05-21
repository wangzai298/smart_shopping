import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Product } from '../../entities/product.entity';
import { PriceHistory } from '../../entities/price-history.entity';
import { SearchHistory } from '../../entities/search-history.entity';
import { SearchHistoryModule } from '../search-history/search-history.module';
import { RecognitionController } from './recognition.controller';
import { RecognitionService } from './recognition.service';

@Module({
  imports: [TypeOrmModule.forFeature([Product, PriceHistory, SearchHistory]), SearchHistoryModule],
  controllers: [RecognitionController],
  providers: [RecognitionService],
})
export class RecognitionModule {}
