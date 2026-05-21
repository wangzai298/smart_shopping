# NLP Filter Module Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build natural language filter endpoint that converts user queries ("要便宜点的") into structured Filter JSON, using keyword rules when Doubao API key is empty, with output validation discarding invalid fields.

**Architecture:** NlpService checks `doubaoConfig.apiKey` — if empty runs keyword rule engine; if set calls Doubao LLM via OpenAI-compatible chat completions API with a system prompt that instructs structured JSON output. Both paths produce a Filter object that is validated/sanitized before return. Controller wraps result in `{ success: true, data: { filter } }` per section 6.3.

**Tech Stack:** Nest.js 10, native fetch (no new dependencies)

---

### Task 1: Doubao Config

**Files:**
- Create: `server/src/config/doubao.config.ts`

```typescript
export const doubaoConfig = {
  apiKey: '',
  endpoint: 'https://ark.cn-beijing.volces.com/api/v3/chat/completions',
  model: '',
};
```

### Task 2: NLP Request DTO

**Files:**
- Create: `server/src/modules/nlp/dto/nlp-request.dto.ts`

```typescript
export class NlpRequestDto {
  query: string;
  context?: Record<string, any>;
}
```

### Task 3: NLP Service (rule engine + LLM reserve + validation)

**Files:**
- Create: `server/src/modules/nlp/nlp.service.ts`

Three core methods:
- `analyze(query, context?)`: Main entry, checks apiKey → rules or LLM → validate → return Filter
- `applyRules(query, context?)`: Keyword matching engine with brand extraction
- `callDoubaoAPI(query, context?)`: OpenAI-compatible chat completions with system prompt
- `validateFilter(raw)`: Whitelist valid fields, discard invalid, apply defaults

Keyword rules:
| Keyword Pattern | Filter Field |
|----------------|-------------|
| 便宜/低价/实惠/省钱 | sort: "price_asc" |
| 贵/高价/最贵 | sort: "price_desc" |
| 旗舰店 | shopType: "旗舰店" |
| 自营 | shopType: "自营" |
| C店/淘宝店 | shopType: "C店" |
| Nike/耐克 | brand: "Nike" |
| Adidas/阿迪达斯/阿迪 | brand: "Adidas" |
| 运动鞋/跑步鞋 | category: "运动鞋" |
| 价格在X以下/以内/不超过X | priceRange.max = X |
| 价格在X以上/不低于X | priceRange.min = X |

### Task 4: NLP Controller

**Files:**
- Create: `server/src/modules/nlp/nlp.controller.ts`

POST /nlp/filter → wraps NlpService.analyze() in `{ success: true, data: { filter } }`

### Task 5: NLP Module + AppModule wiring

**Files:**
- Create: `server/src/modules/nlp/nlp.module.ts`
- Modify: `server/src/app.module.ts` — add NlpModule

### Task 6: Verify

- Compile, start, test with: "要便宜点的", "Nike旗舰店", "价格在800以下", "无匹配关键词"
- Verify output validation: send mock LLM response with invalid fields → confirm discarded
