import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';

@Entity('search_history')
export class SearchHistory {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ type: 'text', name: 'user_id', nullable: true })
  userId: string;

  @Column({ type: 'text', name: 'image_url', nullable: true })
  imageUrl: string;

  @Column({ type: 'jsonb', name: 'result_snapshot', nullable: true })
  resultSnapshot: any;

  @Column({ type: 'timestamptz', name: 'created_at', default: () => 'NOW()' })
  createdAt: Date;
}
