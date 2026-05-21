import { Controller, Post, Body } from '@nestjs/common';
import { NlpService } from './nlp.service';
import { NlpRequestDto } from './dto/nlp-request.dto';

@Controller('nlp')
export class NlpController {
  constructor(private readonly nlpService: NlpService) {}

  @Post('filter')
  async filter(@Body() dto: NlpRequestDto) {
    const result = await this.nlpService.analyze(dto.query, dto.context, dto.conversationId);
    return { success: true, data: { conversationId: result.conversationId, filter: result.filter } };
  }
}
