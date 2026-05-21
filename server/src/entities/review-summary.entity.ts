import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';

@Entity('review_summaries')
export class ReviewSummary {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ type: 'text', name: 'product_id' })
  productId: string;

  @Column({ type: 'text' })
  platform: string;

  @Column({ type: 'simple-array', name: 'positive_keywords' })
  positiveKeywords: string[];

  @Column({ type: 'simple-array', name: 'negative_keywords' })
  negativeKeywords: string[];

  @Column({ type: 'text' })
  summary: string;
}
