import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PriceAlert } from '../../entities/price-alert.entity';
import { PriceAlertController } from './price-alert.controller';
import { PriceAlertService } from './price-alert.service';

@Module({
  imports: [TypeOrmModule.forFeature([PriceAlert])],
  controllers: [PriceAlertController],
  providers: [PriceAlertService],
  exports: [PriceAlertService],
})
export class PriceAlertModule {}
