import { Injectable, Logger } from '@nestjs/common';

@Injectable()
export class NotificationService {
  private readonly logger = new Logger(NotificationService.name);

  async sendPush(userId: string, title: string, body: string) {
    // FCM 推送占位 — Demo 阶段仅打印日志
    this.logger.log(`[FCM Push] userId=${userId} title="${title}" body="${body}"`);
    return { sent: true, message: '推送已发送(Demo日志模式)' };
  }
}
