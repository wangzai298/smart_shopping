# 识物比价 — AI 多模态购物比价助手

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![NestJS](https://img.shields.io/badge/NestJS-10.x-E0234E?logo=nestjs)](https://nestjs.com)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-4169E1?logo=postgresql)](https://www.postgresql.org)
[![Docker](https://img.shields.io/badge/Docker-✓-2496ED?logo=docker)](https://www.docker.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

拍照识别商品 → 多平台价格比较 → 历史趋势可视化 → 自然语言筛选 → 降价提醒。一套代码同时运行 Android / iOS / 鸿蒙。

---

## 功能特性

- 📷 **拍照识物** — 拍照或相册选图，AI 自动识别商品类别、品牌、属性
- 💰 **多平台比价** — 淘宝 / 京东 / 拼多多价格聚合，最低价高亮标注
- 📈 **历史趋势** — 7 个月价格折线图，红色虚线标注历史最低价
- 🗣️ **自然语言筛选** — 输入"便宜点的Nike旗舰店"自动解析为筛选条件，支持多轮对话
- ❤️ **收藏夹** — 多清单管理，商品一键收藏
- ⭐ **评价摘要** — 多平台评价聚合，正面/负面标签 + AI 总结
- 🔔 **降价提醒** — 设置目标价格，低于预期时收到通知
- 🔐 **用户认证** — 手机号注册/登录，JWT 双令牌自动刷新
- 🐳 **Docker 部署** — 一行命令启动 PostgreSQL + Redis + App
- 📱 **跨平台** — Android / iOS / 鸿蒙，一套 Dart 代码

---

## 技术栈

| 层 | 技术 | 说明 |
|---|------|------|
| 客户端 | Flutter 3.x + Dart 3.x | Riverpod / Dio / go_router / fl_chart / shimmer |
| 服务端 | Nest.js 10 + TypeScript 5 | 16 个业务模块，24 个 REST API |
| 数据库 | PostgreSQL 16 | TypeORM + pg 驱动，JSONB / DECIMAL / DATE |
| AI | 豆包多模态大模型 | OpenAI-compatible，图片识别 + NLP 统一接口 |
| 认证 | JWT 双令牌 | Access 15min + Refresh 7d，自动刷新 |
| 安全 | Helmet + Throttler | HTTP 安全头 + 100 req/min 全局限流 |
| 部署 | Docker + docker-compose | 三容器编排，Volumes 数据持久化 |

---

## 快速开始

### 前提

- Node.js 18+、Flutter SDK 3.x、PostgreSQL 16
- PostgreSQL 中创建 `smart_shopping` 数据库
- （可选）Docker Desktop

### 1. 启动服务端

```bash
cd server
npm install
npm start
# → Server running on http://localhost:3000
```

### 2. 初始化数据

```bash
curl http://localhost:3000/seed/init
# → { productCount: 30, priceCount: 630, userCreated: true }
```

### 3. 启动客户端

```bash
cd client
flutter pub get
flutter run
```

### Docker 一键启动

```bash
docker-compose up -d
# PostgreSQL + Redis + App 全部启动
```

---

## Demo 账号

| 字段 | 值 |
|------|-----|
| 手机号 | 11111111111 |
| 密码 | 298556 |

不填任何 AI Key 也能跑通全流程（Mock 兜底）。

---

## 项目结构

```
smart-shopping-assistant/
├── server/                     Nest.js 服务端
│   ├── src/
│   │   ├── main.ts             启动入口（CORS + Helmet + ValidationPipe）
│   │   ├── app.module.ts       根模块（15 个子模块）
│   │   ├── config/             数据库 / AI / JWT / Redis 配置
│   │   ├── entities/           8 个数据库实体
│   │   ├── common/             Guard / Decorator / Filter / Interceptor
│   │   └── modules/
│   │       ├── auth/           认证（注册/登录/JWT/短信）
│   │       ├── recognition/    图像识别（多图→AI→匹配商品）
│   │       ├── product/        商品搜索（ILIKE 模糊匹配）
│   │       ├── comparison/     比价聚合（最低价平台）
│   │       ├── history/        历史价格（含全时段最低价）
│   │       ├── nlp/            自然语言筛选（多轮对话）
│   │       ├── favorites/      收藏夹（多清单+商品管理）
│   │       ├── search-history/ 搜索历史（自动保存）
│   │       ├── reviews/        评价摘要
│   │       ├── price-alert/    降价提醒
│   │       ├── notification/   推送（FCM 占位）
│   │       └── seed/           种子数据（30商品+630价格）
│   ├── .env.example            环境变量模板
│   ├── .env.docker             Docker 环境变量
│   └── Dockerfile              多阶段构建
│
├── client/                     Flutter 客户端
│   └── lib/
│       ├── main.dart / app.dart 入口 + 11 条路由
│       ├── config/             后端地址（模拟器/真机自动检测）
│       ├── models/             数据模型（Product / Filter / User）
│       ├── services/           API / Auth / Camera / Storage
│       ├── providers/          状态管理（Search / Filter / Auth）
│       ├── screens/
│       │   ├── splash/login     启动 + 登录
│       │   ├── home/camera      首页 + 拍照
│       │   ├── results/detail   结果 + 详情（趋势图+评价+提醒）
│       │   ├── favorites        收藏夹（展开+商品管理）
│       │   ├── profile/history/alerts  个人中心
│       │   └── results_screen/widgets/ ProductCard / Chart / ReviewCard
│       └── widgets/            公共组件（Loading / Error / Empty）
│
├── docker-compose.yml          PostgreSQL + Redis + App 编排
├── 项目说明.txt                  项目全貌文档
├── 技术说明.txt                  技术教程（含类比，面向零基础）
├── 配置清单.txt                  Key / 地址 / Demo 账号
└── 任务说明.txt                  原始开发蓝图
```

---

## API 概览（24 个端点）

| 方法 | 端点 | 说明 | 认证 |
|------|------|------|------|
| POST | `/auth/register` | 用户注册 | - |
| POST | `/auth/login` | 用户登录 | - |
| POST | `/auth/refresh` | 刷新令牌 | - |
| POST | `/auth/send-sms-code` | 发送验证码 | - |
| GET | `/users/me` | 当前用户信息 | JWT |
| PATCH | `/users/me` | 更新用户信息 | JWT |
| POST | `/recognition/upload` | 图片上传识别 | - |
| GET | `/products/search` | 商品搜索 | - |
| GET | `/comparison/:productId` | 单商品比价 | - |
| GET | `/products/:id/history` | 历史价格趋势 | - |
| GET | `/products/:id/reviews` | 评价摘要 | - |
| POST | `/nlp/filter` | 自然语言筛选 | - |
| GET | `/favorites/lists` | 收藏清单列表 | JWT |
| POST | `/favorites/lists` | 创建清单 | JWT |
| DELETE | `/favorites/lists/:id` | 删除清单 | JWT |
| GET | `/favorites/lists/:id/items` | 清单商品 | JWT |
| POST | `/favorites/lists/:id/items` | 添加商品 | JWT |
| DELETE | `/favorites/items/:id` | 移除商品 | JWT |
| GET | `/search-history` | 搜索历史 | JWT |
| DELETE | `/search-history` | 清空历史 | JWT |
| GET | `/price-alerts` | 降价提醒列表 | JWT |
| POST | `/price-alerts` | 创建提醒 | JWT |
| PATCH | `/price-alerts/:id` | 修改提醒 | JWT |
| DELETE | `/price-alerts/:id` | 删除提醒 | JWT |
| GET | `/seed/init` | 初始化种子数据 | - |

---

## 项目文档

| 文档 | 说明 |
|------|------|
| [项目说明.txt](./项目说明.txt) | 项目全貌：架构、目录、表结构、API、设计决策 |
| [技术说明.txt](./技术说明.txt) | 技术教程：零基础入门 + 每个技术详解 + 类比说明 + STAR 简历 |
| [配置清单.txt](./配置清单.txt) | 需填写的 Key / 地址 / Demo 账号 / 快速验证步骤 |
| [任务说明.txt](./任务说明.txt) | 原始开发蓝图，唯一开发准则 |

---

## 许可证

MIT License
