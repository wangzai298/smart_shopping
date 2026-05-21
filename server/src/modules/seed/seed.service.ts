import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as bcrypt from 'bcryptjs';
import { Product } from '../../entities/product.entity';
import { PriceHistory } from '../../entities/price-history.entity';
import { User } from '../../entities/user.entity';
import { ReviewSummary } from '../../entities/review-summary.entity';
import { FavoriteList } from '../../entities/favorite-list.entity';
import { FavoriteItem } from '../../entities/favorite-item.entity';

interface SeedProduct {
  id: string;
  name: string;
  category: string;
  brand: string;
  attributes: Record<string, string>;
  imageUrl: string;
  prices: {
    platform: string;
    months: { date: string; price: number }[];
  }[];
}

@Injectable()
export class SeedService {
  constructor(
    @InjectRepository(Product)
    private productRepo: Repository<Product>,
    @InjectRepository(PriceHistory)
    private priceHistoryRepo: Repository<PriceHistory>,
    @InjectRepository(User)
    private userRepo: Repository<User>,
    @InjectRepository(ReviewSummary)
    private reviewSummaryRepo: Repository<ReviewSummary>,
    @InjectRepository(FavoriteList)
    private favoriteListRepo: Repository<FavoriteList>,
    @InjectRepository(FavoriteItem)
    private favoriteItemRepo: Repository<FavoriteItem>,
  ) {}

  async init(): Promise<{ message: string; productCount: number; priceCount: number; userCreated: boolean }> {
    await this.favoriteItemRepo.clear();
    await this.favoriteListRepo.clear();
    await this.reviewSummaryRepo.clear();
    await this.priceHistoryRepo.clear();
    await this.productRepo.clear();
    await this.userRepo.clear();

    let priceCount = 0;

    for (const sp of SEED_PRODUCTS) {
      await this.productRepo.save({
        id: sp.id,
        name: sp.name,
        category: sp.category,
        brand: sp.brand,
        attributes: sp.attributes,
        imageUrl: sp.imageUrl,
      });

      for (const p of sp.prices) {
        const rows = p.months.map((m) => ({
          productId: sp.id,
          platform: p.platform,
          price: m.price,
          date: m.date,
        }));
        await this.priceHistoryRepo.save(rows);
        priceCount += rows.length;
      }
    }

    // ── Test user ──
    const passwordHash = await bcrypt.hash('298556', 10);
    const savedUser = await this.userRepo.save({
      phone: '11111111111',
      passwordHash,
      nickname: 'Demo用户',
    });
    const userCreated = true;

    // ── Default favorites list ──
    await this.favoriteListRepo.save({ userId: savedUser.id, name: '默认清单' } as any);

    // ── Review summaries ──
    await this.reviewSummaryRepo.save({
      productId: 'shoe-001',
      platform: '综合',
      positiveKeywords: ['舒适', '透气', '百搭'],
      negativeKeywords: ['偏小', '溢胶'],
      summary: '用户普遍认为此款运动鞋舒适透气且百搭，但部分反映尺码偏小、做工有溢胶现象。',
    });
    await this.reviewSummaryRepo.save({
      productId: 'shoe-002',
      platform: '综合',
      positiveKeywords: ['回弹好', '轻便'],
      negativeKeywords: ['不耐脏'],
      summary: '多数用户称赞其回弹和轻便性，适合日常跑步训练，但白色款易脏需注意保养。',
    });

    return {
      message: `Seed data initialized: ${SEED_PRODUCTS.length} products, ${priceCount} price history records, test user, review summaries`,
      productCount: SEED_PRODUCTS.length,
      priceCount,
      userCreated,
    };
  }
}

// ── Helper: generate 6-month price history starting from a base price ──

function history(
  basePrice: number,
  variance: number = 0.08,
  months: string[] = PRICE_MONTHS,
): { date: string; price: number }[] {
  return months.map((date, i) => {
    const factor = 1 + (Math.sin(i * 0.8) * variance) + (Math.random() - 0.5) * variance;
    return { date, price: Math.round(basePrice * factor) };
  });
}

const PRICE_MONTHS = ['2024-06-01', '2025-01-01', '2025-02-01', '2025-03-01', '2025-04-01', '2025-05-01', '2025-06-01'];

// ── Seed Product Definitions ──

const SEED_PRODUCTS: SeedProduct[] = [
  // ======================== 运动鞋 ========================
  {
    id: 'shoe-001',
    name: 'Nike Air Max 90 黑白',
    category: '运动鞋',
    brand: 'Nike',
    attributes: { color: '黑白', style: '休闲', size: '39-45' },
    imageUrl: 'https://img.alicdn.com/nike-air-max-90.jpg',
    prices: [
      { platform: '淘宝', months: history(859, 0.07) },
      { platform: '京东', months: history(899, 0.05) },
      { platform: '拼多多', months: history(829, 0.08) },
    ],
  },
  {
    id: 'shoe-002',
    name: 'Adidas Ultraboost 22 白色',
    category: '运动鞋',
    brand: 'Adidas',
    attributes: { color: '白色', style: '跑步', size: '38-46' },
    imageUrl: 'https://img.alicdn.com/adidas-ultraboost-22.jpg',
    prices: [
      { platform: '淘宝', months: history(1059, 0.06) },
      { platform: '京东', months: history(1099, 0.05) },
      { platform: '拼多多', months: history(999, 0.09) },
    ],
  },
  {
    id: 'shoe-003',
    name: '李宁 超轻20 白色',
    category: '运动鞋',
    brand: '李宁',
    attributes: { color: '白色', style: '跑步', size: '39-44' },
    imageUrl: 'https://img.alicdn.com/lining-chaoqing-20.jpg',
    prices: [
      { platform: '淘宝', months: history(459, 0.08) },
      { platform: '京东', months: history(499, 0.06) },
      { platform: '拼多多', months: history(429, 0.10) },
    ],
  },
  {
    id: 'shoe-004',
    name: '安踏 C37+ 灰色',
    category: '运动鞋',
    brand: '安踏',
    attributes: { color: '灰色', style: '通勤', size: '40-44' },
    imageUrl: 'https://img.alicdn.com/anta-c37-plus.jpg',
    prices: [
      { platform: '淘宝', months: history(359, 0.07) },
      { platform: '京东', months: history(379, 0.05) },
      { platform: '拼多多', months: history(329, 0.09) },
    ],
  },

  // ======================== 智能手机 ========================
  {
    id: 'phone-001',
    name: 'iPhone 15 Pro 256GB 原色钛金属',
    category: '智能手机',
    brand: 'Apple',
    attributes: { color: '原色', storage: '256GB', ram: '8GB' },
    imageUrl: 'https://img.alicdn.com/iphone-15-pro.jpg',
    prices: [
      { platform: '淘宝', months: history(7999, 0.04) },
      { platform: '京东', months: history(8299, 0.03) },
      { platform: '拼多多', months: history(7699, 0.06) },
    ],
  },
  {
    id: 'phone-002',
    name: '华为 Mate 60 Pro 雅丹黑 512GB',
    category: '智能手机',
    brand: '华为',
    attributes: { color: '雅丹黑', storage: '512GB', ram: '12GB' },
    imageUrl: 'https://img.alicdn.com/huawei-mate60pro.jpg',
    prices: [
      { platform: '淘宝', months: history(6999, 0.05) },
      { platform: '京东', months: history(6999, 0.04) },
      { platform: '拼多多', months: history(6699, 0.07) },
    ],
  },
  {
    id: 'phone-003',
    name: '小米 14 徕卡光学 12+256GB',
    category: '智能手机',
    brand: '小米',
    attributes: { color: '黑色', storage: '256GB', ram: '12GB' },
    imageUrl: 'https://img.alicdn.com/xiaomi-14.jpg',
    prices: [
      { platform: '淘宝', months: history(3999, 0.05) },
      { platform: '京东', months: history(3999, 0.04) },
      { platform: '拼多多', months: history(3799, 0.07) },
    ],
  },

  // ======================== 笔记本电脑 ========================
  {
    id: 'laptop-001',
    name: 'MacBook Air M3 15英寸 星光色',
    category: '笔记本电脑',
    brand: 'Apple',
    attributes: { color: '星光色', cpu: 'M3', ram: '16GB', storage: '512GB' },
    imageUrl: 'https://img.alicdn.com/macbook-air-m3.jpg',
    prices: [
      { platform: '淘宝', months: history(10499, 0.04) },
      { platform: '京东', months: history(10999, 0.03) },
      { platform: '拼多多', months: history(9999, 0.05) },
    ],
  },
  {
    id: 'laptop-002',
    name: '联想 ThinkBook 14+ 锐龙版',
    category: '笔记本电脑',
    brand: '联想',
    attributes: { color: '银色', cpu: 'R7-7840H', ram: '32GB', storage: '1TB' },
    imageUrl: 'https://img.alicdn.com/thinkbook-14-plus.jpg',
    prices: [
      { platform: '淘宝', months: history(5499, 0.05) },
      { platform: '京东', months: history(5699, 0.04) },
      { platform: '拼多多', months: history(5199, 0.06) },
    ],
  },

  // ======================== 无线耳机 ========================
  {
    id: 'earphone-001',
    name: 'AirPods Pro 第二代 USB-C',
    category: '无线耳机',
    brand: 'Apple',
    attributes: { type: '入耳式', anc: '主动降噪', connectivity: '蓝牙5.3' },
    imageUrl: 'https://img.alicdn.com/airpods-pro-2.jpg',
    prices: [
      { platform: '淘宝', months: history(1649, 0.06) },
      { platform: '京东', months: history(1699, 0.04) },
      { platform: '拼多多', months: history(1549, 0.08) },
    ],
  },
  {
    id: 'earphone-002',
    name: '华为 FreeBuds Pro 3 陶瓷白',
    category: '无线耳机',
    brand: '华为',
    attributes: { type: '入耳式', anc: '智慧降噪', connectivity: '蓝牙5.2' },
    imageUrl: 'https://img.alicdn.com/freebuds-pro-3.jpg',
    prices: [
      { platform: '淘宝', months: history(1149, 0.06) },
      { platform: '京东', months: history(1199, 0.05) },
      { platform: '拼多多', months: history(1099, 0.08) },
    ],
  },
  {
    id: 'earphone-003',
    name: '漫步者 NeoBuds Pro 2',
    category: '无线耳机',
    brand: '漫步者',
    attributes: { type: '入耳式', anc: '主动降噪', connectivity: '蓝牙5.3' },
    imageUrl: 'https://img.alicdn.com/neobuds-pro-2.jpg',
    prices: [
      { platform: '淘宝', months: history(599, 0.08) },
      { platform: '京东', months: history(649, 0.06) },
      { platform: '拼多多', months: history(569, 0.10) },
    ],
  },

  // ======================== 家电 ========================
  {
    id: 'tv-001',
    name: '小米电视 S65 Mini LED',
    category: '电视机',
    brand: '小米',
    attributes: { size: '65英寸', resolution: '4K', refreshRate: '144Hz' },
    imageUrl: 'https://img.alicdn.com/xiaomi-tv-s65.jpg',
    prices: [
      { platform: '淘宝', months: history(4299, 0.05) },
      { platform: '京东', months: history(4499, 0.04) },
      { platform: '拼多多', months: history(4099, 0.07) },
    ],
  },
  {
    id: 'ac-001',
    name: '格力 冷静王+ 1.5匹 新一级能效',
    category: '空调',
    brand: '格力',
    attributes: { power: '1.5匹', efficiency: '新一级', type: '壁挂式' },
    imageUrl: 'https://img.alicdn.com/gree-lengjingwang.jpg',
    prices: [
      { platform: '淘宝', months: history(3499, 0.04) },
      { platform: '京东', months: history(3699, 0.03) },
      { platform: '拼多多', months: history(3299, 0.06) },
    ],
  },
  {
    id: 'fridge-001',
    name: '海尔 BCD-510WGHTD 十字对开门',
    category: '冰箱',
    brand: '海尔',
    attributes: { capacity: '510L', type: '十字对开门', efficiency: '一级能效' },
    imageUrl: 'https://img.alicdn.com/haier-bcd-510.jpg',
    prices: [
      { platform: '淘宝', months: history(3999, 0.04) },
      { platform: '京东', months: history(4299, 0.03) },
      { platform: '拼多多', months: history(3799, 0.06) },
    ],
  },
  {
    id: 'cooker-001',
    name: '美的 MB-FB40E511 IH电饭煲',
    category: '电饭煲',
    brand: '美的',
    attributes: { capacity: '4L', type: 'IH电磁加热', coating: '备长炭' },
    imageUrl: 'https://img.alicdn.com/midea-fb40e511.jpg',
    prices: [
      { platform: '淘宝', months: history(399, 0.07) },
      { platform: '京东', months: history(429, 0.05) },
      { platform: '拼多多', months: history(369, 0.09) },
    ],
  },
  {
    id: 'oven-001',
    name: '格兰仕 G70F20 平板微波炉',
    category: '微波炉',
    brand: '格兰仕',
    attributes: { capacity: '20L', power: '700W', type: '平板式' },
    imageUrl: 'https://img.alicdn.com/galanz-g70f20.jpg',
    prices: [
      { platform: '淘宝', months: history(369, 0.06) },
      { platform: '京东', months: history(399, 0.05) },
      { platform: '拼多多', months: history(339, 0.08) },
    ],
  },

  // ======================== 服装 ========================
  {
    id: 'clothes-001',
    name: '优衣库 纯棉圆领T恤 男士',
    category: 'T恤',
    brand: '优衣库',
    attributes: { color: '白色', material: '纯棉', size: 'S-XXL' },
    imageUrl: 'https://img.alicdn.com/uniqlo-tshirt-white.jpg',
    prices: [
      { platform: '淘宝', months: history(72, 0.10) },
      { platform: '京东', months: history(79, 0.08) },
      { platform: '拼多多', months: history(59, 0.12) },
    ],
  },
  {
    id: 'clothes-002',
    name: '海澜之家 弹力修身牛仔裤',
    category: '牛仔裤',
    brand: '海澜之家',
    attributes: { color: '深蓝', material: '棉弹混纺', size: '28-38' },
    imageUrl: 'https://img.alicdn.com/hailan-jeans.jpg',
    prices: [
      { platform: '淘宝', months: history(199, 0.08) },
      { platform: '京东', months: history(229, 0.06) },
      { platform: '拼多多', months: history(179, 0.10) },
    ],
  },
  {
    id: 'clothes-003',
    name: '波司登 轻薄羽绒服 女士',
    category: '羽绒服',
    brand: '波司登',
    attributes: { color: '黑色', fill: '90%白鹅绒', size: 'S-XL' },
    imageUrl: 'https://img.alicdn.com/bosideng-down.jpg',
    prices: [
      { platform: '淘宝', months: history(599, 0.06) },
      { platform: '京东', months: history(649, 0.05) },
      { platform: '拼多多', months: history(549, 0.08) },
    ],
  },

  // ======================== 日用品 ========================
  {
    id: 'daily-001',
    name: '蓝月亮 深层洁净洗衣液 3kg',
    category: '洗衣液',
    brand: '蓝月亮',
    attributes: { weight: '3kg', scent: '清新', type: '深层洁净' },
    imageUrl: 'https://img.alicdn.com/lanyueliang-3kg.jpg',
    prices: [
      { platform: '淘宝', months: history(42, 0.10) },
      { platform: '京东', months: history(49, 0.08) },
      { platform: '拼多多', months: history(35, 0.12) },
    ],
  },
  {
    id: 'daily-002',
    name: '云南白药 薄荷清爽牙膏 180g',
    category: '牙膏',
    brand: '云南白药',
    attributes: { weight: '180g', flavor: '薄荷', function: '护龈' },
    imageUrl: 'https://img.alicdn.com/yunnanbaiyao-toothpaste.jpg',
    prices: [
      { platform: '淘宝', months: history(32, 0.10) },
      { platform: '京东', months: history(35, 0.08) },
      { platform: '拼多多', months: history(26, 0.14) },
    ],
  },
  {
    id: 'daily-003',
    name: '维达 超韧抽纸 3层100抽×24包',
    category: '抽纸',
    brand: '维达',
    attributes: { layers: '3层', count: '24包', type: '超韧系列' },
    imageUrl: 'https://img.alicdn.com/vinda-tissue-24.jpg',
    prices: [
      { platform: '淘宝', months: history(45, 0.08) },
      { platform: '京东', months: history(49, 0.06) },
      { platform: '拼多多', months: history(39, 0.10) },
    ],
  },

  // ======================== 食品饮料 ========================
  {
    id: 'food-001',
    name: '雀巢 金牌速溶咖啡 200g',
    category: '咖啡',
    brand: '雀巢',
    attributes: { weight: '200g', type: '速溶', roast: '中度烘焙' },
    imageUrl: 'https://img.alicdn.com/nestle-gold-coffee.jpg',
    prices: [
      { platform: '淘宝', months: history(68, 0.08) },
      { platform: '京东', months: history(75, 0.06) },
      { platform: '拼多多', months: history(58, 0.10) },
    ],
  },
  {
    id: 'food-002',
    name: '德芙 丝滑牛奶巧克力 252g',
    category: '巧克力',
    brand: '德芙',
    attributes: { weight: '252g', flavor: '牛奶', type: '碗装' },
    imageUrl: 'https://img.alicdn.com/dove-chocolate-252.jpg',
    prices: [
      { platform: '淘宝', months: history(35, 0.10) },
      { platform: '京东', months: history(39, 0.08) },
      { platform: '拼多多', months: history(28, 0.14) },
    ],
  },
  {
    id: 'food-003',
    name: '三只松鼠 每日坚果 750g礼盒',
    category: '坚果',
    brand: '三只松鼠',
    attributes: { weight: '750g', type: '混合坚果', packaging: '礼盒装' },
    imageUrl: 'https://img.alicdn.com/3squirrels-nuts-750.jpg',
    prices: [
      { platform: '淘宝', months: history(89, 0.08) },
      { platform: '京东', months: history(99, 0.06) },
      { platform: '拼多多', months: history(79, 0.10) },
    ],
  },

  // ======================== 书籍 ========================
  {
    id: 'book-001',
    name: '深入理解计算机系统（第3版）',
    category: '书籍',
    brand: '机械工业出版社',
    attributes: { author: 'Randal E. Bryant', pages: '737', language: '中文' },
    imageUrl: 'https://img.alicdn.com/csapp-3e.jpg',
    prices: [
      { platform: '淘宝', months: history(98, 0.06) },
      { platform: '京东', months: history(109, 0.05) },
      { platform: '拼多多', months: history(79, 0.10) },
    ],
  },
  {
    id: 'book-002',
    name: '三体全集（全三册）刘慈欣',
    category: '书籍',
    brand: '重庆出版社',
    attributes: { author: '刘慈欣', pages: '1280', type: '科幻小说' },
    imageUrl: 'https://img.alicdn.com/three-body-trilogy.jpg',
    prices: [
      { platform: '淘宝', months: history(58, 0.08) },
      { platform: '京东', months: history(68, 0.06) },
      { platform: '拼多多', months: history(45, 0.12) },
    ],
  },

  // ======================== 箱包 ========================
  {
    id: 'bag-001',
    name: '小米 经典双肩包 15.6英寸',
    category: '双肩包',
    brand: '小米',
    attributes: { color: '深灰', size: '15.6英寸', material: '防泼水' },
    imageUrl: 'https://img.alicdn.com/xiaomi-backpack.jpg',
    prices: [
      { platform: '淘宝', months: history(99, 0.08) },
      { platform: '京东', months: history(99, 0.06) },
      { platform: '拼多多', months: history(89, 0.10) },
    ],
  },
  {
    id: 'bag-002',
    name: '外交官 万向轮拉杆箱 24寸',
    category: '行李箱',
    brand: '外交官',
    attributes: { color: '银色', size: '24寸', material: 'PC+ABS' },
    imageUrl: 'https://img.alicdn.com/diplomat-luggage-24.jpg',
    prices: [
      { platform: '淘宝', months: history(599, 0.06) },
      { platform: '京东', months: history(649, 0.05) },
      { platform: '拼多多', months: history(549, 0.08) },
    ],
  },
];
