import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { RestaurantCategory } from 'src/database/entities/restaurant/restaurant-category.entity';
import { ProductRepository } from 'src/routes/product/product.repo';
import { Repository } from 'typeorm';

@Injectable()
export class ProductService {
  constructor(
    private readonly productRepository: ProductRepository,
    @InjectRepository(RestaurantCategory)
    private readonly categoryRepo: Repository<RestaurantCategory>,
  ) {}
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

  async getAllProductsByCategories(
    categoryNames: string[],
    page: number,
    limit: number,
  ) {
    const skip = (page - 1) * limit;

    if (!categoryNames || categoryNames.length === 0) {
      throw new BadRequestException('Phải có ít nhất một category để lọc');
    }

    // Lấy các category có thật
    const validCategories = await this.categoryRepo.find({
      where: categoryNames.map((name) => ({ name })),
    });

    if (validCategories.length === 0) {
      throw new NotFoundException('Không có category nào hợp lệ');
    }

    const restaurants = await this.productRepository.getRestaurantsByCategories(
      validCategories.map((c) => c.name),
      skip,
      limit,
    );

    const grouped = {
      categories: categoryNames,
      shops: restaurants.map((rest) => ({
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
      })),
    };

    return {
      currentPage: page,
      limit,
      data: grouped,
    };
  }
}
