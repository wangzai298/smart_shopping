import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';

@Entity('price_history')
export class PriceHistory {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ type: 'text' })
  productId: string;

  @Column({ type: 'text' })
  platform: string;

  @Column({ type: 'decimal', precision: 10, scale: 2 })
  price: number;

  @Column({ type: 'date' })
  date: string;
}
