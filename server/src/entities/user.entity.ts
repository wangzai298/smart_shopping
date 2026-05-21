import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'text', nullable: true })
  phone: string;

  @Column({ type: 'text', nullable: true })
  email: string;

  @Column({ type: 'text', name: 'password_hash', nullable: true })
  passwordHash: string;

  @Column({ type: 'text', name: 'wechat_openid', nullable: true })
  wechatOpenid: string;

  @Column({ type: 'text', name: 'alipay_userid', nullable: true })
  alipayUserid: string;

  @Column({ type: 'text', nullable: true })
  nickname: string;

  @Column({ type: 'text', name: 'avatar_url', nullable: true })
  avatarUrl: string;

  @Column({ type: 'timestamptz', name: 'created_at', default: () => 'NOW()' })
  createdAt: Date;
}
