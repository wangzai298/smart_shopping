import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';

@Entity('favorite_lists')
export class FavoriteList {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ type: 'text', name: 'user_id' })
  userId: string;

  @Column({ type: 'text' })
  name: string;

  @Column({ type: 'boolean', name: 'is_public', default: false })
  isPublic: boolean;

  @Column({ type: 'timestamptz', name: 'created_at', default: () => 'NOW()' })
  createdAt: Date;
}
