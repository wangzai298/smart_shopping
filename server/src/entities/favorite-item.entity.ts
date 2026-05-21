import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';

@Entity('favorite_items')
export class FavoriteItem {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ type: 'int', name: 'list_id' })
  listId: number;

  @Column({ type: 'text', name: 'product_id' })
  productId: string;

  @Column({ type: 'timestamptz', name: 'added_at', default: () => 'NOW()' })
  addedAt: Date;
}
