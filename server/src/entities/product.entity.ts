import { Entity, Column, PrimaryColumn } from 'typeorm';

@Entity('products')
export class Product {
  @PrimaryColumn({ type: 'text' })
  id: string;

  @Column({ type: 'text' })
  name: string;

  @Column({ type: 'text' })
  category: string;

  @Column({ type: 'text' })
  brand: string;

  @Column({ type: 'jsonb', nullable: true })
  attributes: Record<string, string>;

  @Column({ type: 'text', nullable: true })
  imageUrl: string;
}
