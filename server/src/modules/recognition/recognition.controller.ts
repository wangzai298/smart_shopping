import { Controller, Post, Body, Req } from '@nestjs/common';
import * as jwt from 'jsonwebtoken';
import { RecognitionService } from './recognition.service';
import { SearchHistoryService } from '../search-history/search-history.service';
import { UploadImageDto } from './dto/upload-image.dto';

@Controller('recognition')
export class RecognitionController {
  constructor(
    private readonly recognitionService: RecognitionService,
    private readonly searchHistoryService: SearchHistoryService,
  ) {}

  @Post('upload')
  async upload(@Body() dto: UploadImageDto, @Req() req: any) {
    const data = await this.recognitionService.recognize(dto.images);

    // Extract userId from JWT if Authorization header present
    let userId: string | null = null;
    try {
      const auth = req.headers?.authorization;
      if (auth?.startsWith('Bearer ')) {
        const token = auth.slice(7);
        const payload: any = jwt.decode(token);
        if (payload?.sub) userId = payload.sub;
      }
    } catch (_) { /* ignore decode errors */ }

    await this.searchHistoryService.save(userId, '', data).catch(() => {});
    return { success: true, data };
  }
}
