import { Controller, Get, Query } from '@nestjs/common';
import { ProductService } from './product.service';

@Controller('products')
export class ProductController {
  constructor(private readonly productService: ProductService) {}

  @Get('search')
  async search(
    @Query('category') category?: string,
    @Query('brand') brand?: string,
  ) {
    const data = await this.productService.search(category, brand);
    return { success: true, data };
  }
}
