import { Controller, Get, Query } from '@nestjs/common';
import { ProductService } from 'src/routes/product/product.service';
import { IsPublic } from 'src/shared/decorators/auth.decorator';

@Controller('products')
export class ProductController {
  constructor(private readonly productService: ProductService) {}

  @Get('/')
  @IsPublic()
  getAllProducts(
    @Query('category') category?: string,
    @Query('page') page: number = 1,
    @Query('limit') limit: number = 10,
  ) {
    const categories = category
      ? category.split(',').map((c) => c.trim().toLowerCase())
      : [];

    if (categories.length > 0) {
      return this.productService.getAllProductsByCategories(
        categories,
        page,
        limit,
      );
    }

    return this.productService.getAllProducts(page, limit);
  }
}
