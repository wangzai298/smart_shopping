import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';
import { APP_GUARD } from '@nestjs/core';
import { databaseConfig } from './config/database.config';
import { SeedModule } from './modules/seed/seed.module';
import { RecognitionModule } from './modules/recognition/recognition.module';
import { ProductModule } from './modules/product/product.module';
import { ComparisonModule } from './modules/comparison/comparison.module';
import { HistoryModule } from './modules/history/history.module';
import { NlpModule } from './modules/nlp/nlp.module';
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { FavoritesModule } from './modules/favorites/favorites.module';
import { SearchHistoryModule } from './modules/search-history/search-history.module';
import { ReviewsModule } from './modules/reviews/reviews.module';
import { PriceAlertModule } from './modules/price-alert/price-alert.module';
import { NotificationModule } from './modules/notification/notification.module';

@Module({
  imports: [
    TypeOrmModule.forRoot(databaseConfig),
    ThrottlerModule.forRoot([{
      ttl: 60000,
      limit: 100,
    }]),
    SeedModule,
    AuthModule,
    UsersModule,
    RecognitionModule,
    ProductModule,
    ComparisonModule,
    HistoryModule,
    NlpModule,
    FavoritesModule,
    SearchHistoryModule,
    ReviewsModule,
    PriceAlertModule,
    NotificationModule,
  ],
  providers: [
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard,
    },
  ],
})
export class AppModule {}
