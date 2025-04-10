import { Controller, Get, Query } from '@nestjs/common';
import { ProductService } from 'src/routes/product/product.service';
import { IsPublic } from 'src/shared/decorators/auth.decorator';

@Controller('products')
export class ProductController {
  constructor(private readonly productService: ProductService) {}
  @Get('/')
  @IsPublic()
  getAllProducts(
    @Query('page') page: number = 1,
    @Query('limit') limit: number = 10,
  ) {
    return this.productService.getAllProducts(page, limit);
  }
}
