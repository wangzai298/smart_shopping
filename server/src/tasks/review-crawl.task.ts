import { Processor, Process } from '@nestjs/bull';
import { Logger } from '@nestjs/common';
import { Job } from 'bull';

@Processor('review-crawl')
export class ReviewCrawlProcessor {
  private readonly logger = new Logger(ReviewCrawlProcessor.name);

  @Process('update')
  async handleUpdate(job: Job) {
    this.logger.log('[ReviewCrawl] Starting daily review update...');
    // Demo: mock operation — in production this would crawl e-commerce sites
    // and call Doubao API to generate new review summaries
    this.logger.log('[ReviewCrawl] Mock: No real crawling in demo mode');
    this.logger.log('[ReviewCrawl] Update complete');
  }
}
