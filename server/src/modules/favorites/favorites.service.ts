import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { FavoriteList } from '../../entities/favorite-list.entity';
import { FavoriteItem } from '../../entities/favorite-item.entity';

@Injectable()
export class FavoritesService {
  constructor(
    @InjectRepository(FavoriteList) private listRepo: Repository<FavoriteList>,
    @InjectRepository(FavoriteItem) private itemRepo: Repository<FavoriteItem>,
  ) {}

  async getLists(userId: string) {
    const lists = await this.listRepo.find({ where: { userId }, order: { createdAt: 'DESC' } });
    return Promise.all(lists.map(async (l) => ({
      id: l.id, name: l.name, isPublic: l.isPublic,
      itemCount: await this.itemRepo.count({ where: { listId: l.id } }),
    })));
  }

  async createList(userId: string, name: string) {
    console.log(`[Favorites] createList userId=${userId} name="${name}"`);
    const list = await this.listRepo.save({ userId, name } as any);
    return { id: list.id, name: list.name, itemCount: 0 };
  }

  async deleteList(userId: string, listId: number) {
    const list = await this.listRepo.findOne({ where: { id: listId, userId } });
    if (!list) throw new NotFoundException('清单不存在');
    await this.itemRepo.delete({ listId });
    await this.listRepo.delete(listId);
    return { message: '清单已删除' };
  }

  async addItem(listId: number, productId: string) {
    const exists = await this.itemRepo.findOne({ where: { listId, productId } });
    if (exists) return { message: '商品已在清单中' };
    await this.itemRepo.save({ listId, productId });
    return { message: '已添加' };
  }

  async removeItem(itemId: number) {
    await this.itemRepo.delete(itemId);
    return { message: '已移除' };
  }

  async getItems(listId: number) {
    return this.itemRepo.find({ where: { listId }, order: { addedAt: 'DESC' } });
  }
}
