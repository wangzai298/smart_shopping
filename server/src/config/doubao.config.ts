import * as dotenv from 'dotenv';
dotenv.config();

export const doubaoConfig = {
  apiKey: process.env.DOUBAO_API_KEY || '',
  endpoint: 'https://ark.cn-beijing.volces.com/api/v3/responses',
  model: process.env.DOUBAO_MODEL || '',
};
