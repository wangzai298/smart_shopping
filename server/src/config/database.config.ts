import { TypeOrmModuleOptions } from '@nestjs/typeorm';
import { Product } from '../entities/product.entity';
import { PriceHistory } from '../entities/price-history.entity';
import { User } from '../entities/user.entity';
import { ReviewSummary } from '../entities/review-summary.entity';
import { FavoriteList } from '../entities/favorite-list.entity';
import { FavoriteItem } from '../entities/favorite-item.entity';
import { SearchHistory } from '../entities/search-history.entity';
import { PriceAlert } from '../entities/price-alert.entity';
import * as dotenv from 'dotenv';
dotenv.config();

export const databaseConfig: TypeOrmModuleOptions = {
  type: 'postgres',
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5432', 10),
  username: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASS || '298556',
  database: process.env.DB_NAME || 'smart_shopping',
  entities: [Product, PriceHistory, User, ReviewSummary, FavoriteList, FavoriteItem, SearchHistory, PriceAlert],
  synchronize: true,
};
