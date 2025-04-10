import { Injectable } from '@nestjs/common';
import { ProductRepository } from 'src/routes/product/product.repo';

@Injectable()
export class ProductService {
  constructor(private readonly productRepository: ProductRepository) {}
  async getAllProducts(page: number, limit: number) {
    // Tính skip
    const skip = (page - 1) * limit;

    // Lấy dữ liệu kèm menuItems
    const restaurants =
      await this.productRepository.getRestaurantsWithMenuItems(skip, limit);

    const result = restaurants.map((rest) => ({
      shop_name: rest.name,
      shop_address: rest.street_address,
      shop_image: rest.shop_image_url,
      city: rest.city,
      products: rest.menuItems.map((item) => ({
        product_name: item.name,
        product_desc: item.description,
        product_price: item.price,
        product_image: item.image_url,
      })),
    }));

    return {
      currentPage: page,
      limit,
      data: result,
    };
  }
}
