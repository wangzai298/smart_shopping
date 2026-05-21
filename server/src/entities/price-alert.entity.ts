import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';

@Entity('price_alerts')
export class PriceAlert {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ type: 'text', name: 'user_id' })
  userId: string;

  @Column({ type: 'text', name: 'product_id' })
  productId: string;

  @Column({ type: 'decimal', precision: 10, scale: 2, name: 'target_price' })
  targetPrice: number;

  @Column({ type: 'text', nullable: true })
  platform: string;

  @Column({ type: 'boolean', name: 'is_active', default: true })
  isActive: boolean;

  @Column({ type: 'timestamptz', name: 'created_at', default: () => 'NOW()' })
  createdAt: Date;
}
