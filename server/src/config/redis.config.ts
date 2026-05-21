import * as dotenv from 'dotenv';
dotenv.config();

export const redisConfig = {
  host: process.env.REDIS_HOST || 'localhost',
  port: parseInt(process.env.REDIS_PORT || '6379', 10),
  password: process.env.REDIS_PASSWORD || undefined,
};

// Bull queue config uses same connection
export const bullConfig = {
  redis: {
    host: redisConfig.host,
    port: redisConfig.port,
    password: redisConfig.password,
  },
};
