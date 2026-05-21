import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../../entities/user.entity';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private userRepo: Repository<User>,
  ) {}

  async findById(id: string) {
    const user = await this.userRepo.findOne({ where: { id } });
    if (!user) throw new NotFoundException('用户不存在');
    const { passwordHash, wechatOpenid, alipayUserid, ...safe } = user;
    return safe;
  }

  async update(id: string, data: { nickname?: string; avatarUrl?: string }) {
    await this.userRepo.update(id, data);
    return this.findById(id);
  }
}
