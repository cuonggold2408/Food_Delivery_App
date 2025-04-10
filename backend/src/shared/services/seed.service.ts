import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Restaurant } from 'src/database/entities/restaurant.entity';
import { MenuItem } from 'src/database/entities/menu-item.entity';
import * as fs from 'fs';
import * as path from 'path';

@Injectable()
export class SeedService {
  constructor(
    @InjectRepository(Restaurant)
    private readonly restaurantRepo: Repository<Restaurant>,

    @InjectRepository(MenuItem)
    private readonly menuItemRepo: Repository<MenuItem>,
  ) {}

  async importData() {
    // 1. Đọc file JSON
    const filePath = path.join(process.cwd(), 'data', 'filtered_shops.json');

    const jsonData = fs.readFileSync(filePath, 'utf8');
    const shops: any[] = JSON.parse(jsonData);

    // 2. Xử lý từng shop => Restaurant => MenuItem
    for (const shop of shops) {
      const restaurantEntity = new Restaurant();
      restaurantEntity.name = shop.shop_name;
      restaurantEntity.street_address = shop.shop_address;
      restaurantEntity.city = shop.city;
      restaurantEntity.shop_image_url = shop.shop_image;

      // Lưu nhà hàng trước => để có khóa chính
      const savedRestaurant = await this.restaurantRepo.save(restaurantEntity);

      // Insert menu items
      if (shop.products && shop.products.length > 0) {
        const menuItems = shop.products.map((product) => {
          const menuItem = new MenuItem();
          menuItem.name = product.product_name;
          menuItem.description = product.product_desc || '';
          menuItem.price = product.product_price;
          menuItem.image_url = product.product_image;
          menuItem.restaurant = savedRestaurant; // liên kết FK

          return menuItem;
        });

        await this.menuItemRepo.save(menuItems);
      }
    }
    return 'Import done successfully';
  }
}
