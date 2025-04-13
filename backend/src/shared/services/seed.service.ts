import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { MenuItem } from 'src/database/entities/menu-item.entity';
import * as fs from 'fs';
import * as path from 'path';
import { Restaurant } from 'src/database/entities/restaurant/restaurant.entity';
import { RestaurantCategory } from 'src/database/entities/restaurant/restaurant-category.entity';
import { RestaurantCategoryMapping } from 'src/database/entities/restaurant/restaurant-category-mapping.entity';

@Injectable()
export class SeedService {
  constructor(
    @InjectRepository(Restaurant)
    private readonly restaurantRepo: Repository<Restaurant>,

    @InjectRepository(MenuItem)
    private readonly menuItemRepo: Repository<MenuItem>,

    @InjectRepository(RestaurantCategory)
    private readonly categoryRepo: Repository<RestaurantCategory>,

    @InjectRepository(RestaurantCategoryMapping)
    private readonly categoryMappingRepo: Repository<RestaurantCategoryMapping>,
  ) {}

  async importData() {
    const filePath = path.join(process.cwd(), 'data', 'data_processed.json');
    const jsonData = fs.readFileSync(filePath, 'utf8');
    const cities: any[] = JSON.parse(jsonData);

    for (const cityData of cities) {
      const city = cityData.city;

      for (const category of cityData.categories) {
        // 1. Lưu hoặc tìm category
        let categoryEntity = await this.categoryRepo.findOne({
          where: { name: category.category_name },
        });
        if (!categoryEntity) {
          categoryEntity = this.categoryRepo.create({
            name: category.category_name,
            image_url: category.category_image || '',
          });
          categoryEntity = await this.categoryRepo.save(categoryEntity);
        }

        for (const shop of category.shops) {
          const restaurantEntity = new Restaurant();
          restaurantEntity.name = shop.shop_name;
          restaurantEntity.street_address = shop.shop_address;
          restaurantEntity.city = city;
          restaurantEntity.shop_image_url = shop.shop_image;

          const savedRestaurant =
            await this.restaurantRepo.save(restaurantEntity);

          // 2. Mapping restaurant với category
          const mapping = this.categoryMappingRepo.create({
            restaurant_id: savedRestaurant.restaurant_id,
            category_id: categoryEntity.category_id,
          });
          await this.categoryMappingRepo.save(mapping);

          // 3. Insert menu items
          if (shop.products && shop.products.length > 0) {
            const menuItems = shop.products.map((product) => {
              const menuItem = new MenuItem();
              menuItem.name = product.product_name;
              menuItem.description = product.product_desc || '';
              menuItem.price = product.product_price;
              menuItem.image_url = product.product_image;
              menuItem.restaurant = savedRestaurant;
              return menuItem;
            });

            await this.menuItemRepo.save(menuItems);
          }
        }
      }
    }
    console.log('Import done successfully');

    return;
  }
}
