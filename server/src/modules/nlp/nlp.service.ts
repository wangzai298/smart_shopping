import { Injectable, Logger } from '@nestjs/common';
import { doubaoConfig } from '../../config/doubao.config';
import { redisConfig } from '../../config/redis.config';
import * as crypto from 'crypto';
import * as Redis from 'ioredis';

export interface FilterResult {
  sort: string;
  priceRange?: { min: number; max: number };
  shopType?: string;
  brand?: string;
  category?: string;
}

export interface NlpResult {
  filter: FilterResult;
  conversationId: string;
}

const VALID_SORT = ['default', 'price_asc', 'price_desc'];
const VALID_SHOP_TYPES = ['旗舰店', 'C店', '自营'];

const BRAND_KEYWORDS: Record<string, string> = {
  'nike': 'Nike', '耐克': 'Nike',
  'adidas': 'Adidas', '阿迪达斯': 'Adidas', '阿迪': 'Adidas',
};

@Injectable()
export class NlpService {
  private readonly logger = new Logger(NlpService.name);
  private redis: Redis.default | null = null;

  constructor() {
    try {
      this.redis = new Redis.default({
        host: redisConfig.host,
        port: redisConfig.port,
        password: redisConfig.password,
        lazyConnect: true,
        retryStrategy: () => null, // Don't retry — fail fast if Redis unavailable
      });
      this.redis.connect().then(() => this.logger.log('Redis connected for NLP cache')).catch(() => {
        this.logger.warn('Redis unavailable, NLP multi-turn cache disabled');
        this.redis = null;
      });
    } catch {
      this.logger.warn('Redis init failed, NLP multi-turn cache disabled');
      this.redis = null;
    }
  }

  async analyze(
    query: string,
    context?: Record<string, any>,
    conversationId?: string,
  ): Promise<NlpResult> {
    let rawFilter: Record<string, any>;

    const convId = conversationId || `conv-${crypto.randomUUID()}`;

    // Load conversation history from Redis
    let conversationHistory: string[] = [];
    if (this.redis && conversationId) {
      try {
        const cached = await this.redis.get(`nlp:conv:${conversationId}`);
        if (cached) {
          conversationHistory = JSON.parse(cached) as string[];
        }
      } catch { /* ignore */ }
    }

    if (!query || query.trim().length === 0) {
      this.logger.warn('query is empty, returning default filter');
      return { filter: { sort: 'default' }, conversationId: convId };
    }

    if (!doubaoConfig.apiKey) {
      this.logger.log('apiKey is empty, using keyword rules');
      rawFilter = this.applyRules(query, context);
    } else {
      this.logger.log('Calling Doubao LLM API');
      rawFilter = await this.callDoubaoAPI(query, context);
    }

    // Save conversation history to Redis (keep last 5 rounds, TTL 30 min)
    conversationHistory.push(query);
    if (conversationHistory.length > 5) conversationHistory = conversationHistory.slice(-5);
    if (this.redis) {
      try {
        await this.redis.set(`nlp:conv:${convId}`, JSON.stringify(conversationHistory), 'EX', 1800);
      } catch { /* ignore */ }
    }

    return { filter: this.validateFilter(rawFilter), conversationId: convId };
  }

  // ── Keyword Rule Engine ──

  private applyRules(
    query: string,
    context?: Record<string, any>,
  ): Record<string, any> {
    const filter: Record<string, any> = { sort: 'default' };
    const q = query.toLowerCase();

    if (/便宜|低价|实惠|省钱|最便宜|最低价/.test(q)) {
      filter.sort = 'price_asc';
    } else if (/贵|高价|最贵|最高价/.test(q)) {
      filter.sort = 'price_desc';
    }

    if (/旗舰店/.test(q)) {
      filter.shopType = '旗舰店';
    } else if (/自营/.test(q)) {
      filter.shopType = '自营';
    } else if (/c店|淘宝店|个人店/.test(q)) {
      filter.shopType = 'C店';
    }

    for (const [keyword, brand] of Object.entries(BRAND_KEYWORDS)) {
      if (query.includes(keyword) || query.toLowerCase().includes(keyword)) {
        filter.brand = brand;
        break;
      }
    }

    if (/运动鞋|跑步鞋|篮球鞋/.test(q)) {
      filter.category = '运动鞋';
    }

    const maxMatch = q.match(/(?:价格|价钱|预算)?(?:在|不超过|低于|少于|以内|以下)?(\d+)\s*(?:以下|以内|之内|不超过)/);
    if (maxMatch) {
      filter.priceRange = {
        min: filter.priceRange?.min ?? 0,
        max: parseInt(maxMatch[1], 10),
      };
    }

    const minMatch = q.match(/(?:价格|价钱)?(?:在|不低于|高于|至少|以上)?(\d+)\s*(?:以上|起|起步)/);
    if (minMatch) {
      filter.priceRange = {
        min: parseInt(minMatch[1], 10),
        max: filter.priceRange?.max ?? Infinity,
      };
    }

    const rangeMatch = q.match(/(\d+)\s*[-到至]\s*(\d+)/);
    if (rangeMatch) {
      filter.priceRange = {
        min: parseInt(rangeMatch[1], 10),
        max: parseInt(rangeMatch[2], 10),
      };
    }

    return filter;
  }

  // ── Output Validation ──

  private validateFilter(raw: Record<string, any>): FilterResult {
    const filter: FilterResult = { sort: 'default' };

    if (typeof raw.sort === 'string' && VALID_SORT.includes(raw.sort)) {
      filter.sort = raw.sort;
    }

    if (typeof raw.shopType === 'string' && VALID_SHOP_TYPES.includes(raw.shopType)) {
      filter.shopType = raw.shopType;
    }

    if (typeof raw.brand === 'string' && raw.brand.trim().length > 0) {
      filter.brand = raw.brand.trim();
    }

    if (typeof raw.category === 'string' && raw.category.trim().length > 0) {
      filter.category = raw.category.trim();
    }

    if (raw.priceRange && typeof raw.priceRange === 'object') {
      const min = Number(raw.priceRange.min);
      const max = Number(raw.priceRange.max);
      if (!isNaN(min) || !isNaN(max)) {
        filter.priceRange = {
          min: !isNaN(min) && min >= 0 ? min : 0,
          max: !isNaN(max) && max >= 0 ? max : Infinity,
        };
      }
    }

    return filter;
  }

  // ── Doubao LLM API ──

  private async callDoubaoAPI(query: string, context?: Record<string, any>): Promise<Record<string, any>> {
    const systemPrompt = [
      '你是一个购物筛选条件解析器。根据用户的自然语言输入，提取结构化的筛选条件。',
      '',
      '只返回 JSON，格式如下：',
      '{',
      '  "sort": "default" | "price_asc" | "price_desc",',
      '  "priceRange": { "min": number, "max": number } | null,',
      '  "shopType": "旗舰店" | "C店" | "自营" | null,',
      '  "brand": "品牌名" | null,',
      '  "category": "类目名" | null',
      '}',
      '',
      '示例：',
      '输入："要便宜点的" → {"sort":"price_asc","priceRange":null,"shopType":null,"brand":null,"category":null}',
      '输入："Nike旗舰店" → {"sort":"default","priceRange":null,"shopType":"旗舰店","brand":"Nike","category":null}',
      '输入："价格在500以内的运动鞋" → {"sort":"default","priceRange":{"min":0,"max":500},"shopType":null,"brand":null,"category":"运动鞋"}',
    ].join('\n');

    const body = JSON.stringify({
      model: doubaoConfig.model,
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: context ? `上下文: ${JSON.stringify(context)}\n用户查询: ${query}` : query },
      ],
      temperature: 0.1,
      max_tokens: 256,
    });

    const response = await fetch(doubaoConfig.endpoint, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${doubaoConfig.apiKey}` },
      body,
    });

    const json: Record<string, any> = (await response.json()) as Record<string, any>;
    this.logger.log(`Doubao API response: ${JSON.stringify(json)}`);

    const content = json?.choices?.[0]?.message?.content || '{}';
    try {
      const jsonMatch = content.match(/\{[\s\S]*\}/);
      if (jsonMatch) return JSON.parse(jsonMatch[0]);
    } catch {
      this.logger.warn('Failed to parse Doubao response as JSON, using default');
    }
    return { sort: 'default' };
  }
}
