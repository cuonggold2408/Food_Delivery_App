import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { MenuItem } from 'src/database/entities/menu-item.entity';
import * as fs from 'fs';
import * as path from 'path';
import { Restaurant } from 'src/database/entities/restaurant/restaurant.entity';
import { RestaurantCategory } from 'src/database/entities/restaurant/restaurant-category.entity';
import { RestaurantCategoryMapping } from 'src/database/entities/restaurant/restaurant-category-mapping.entity';
import { Promotion } from 'src/database/entities/restaurant/promotions/promotion.entity';
import { CustomizationCategory } from 'src/database/entities/restaurant/category/customization-category.entity';
import { CustomizationOption } from 'src/database/entities/restaurant/category/customization-option.entity';
import { ItemCustomizationCategory } from 'src/database/entities/restaurant/category/item-customization-category.entity';
import { MenuCategory } from 'src/database/entities/restaurant/category/menu-categories.entity';

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

    @InjectRepository(Promotion)
    private readonly promotionRepo: Repository<Promotion>,

    @InjectRepository(CustomizationCategory)
    private readonly customizationCategoryRepo: Repository<CustomizationCategory>,

    @InjectRepository(CustomizationOption)
    private readonly customizationOptionRepo: Repository<CustomizationOption>,

    @InjectRepository(ItemCustomizationCategory)
    private readonly itemCustomizationCategoryRepo: Repository<ItemCustomizationCategory>,

    @InjectRepository(MenuCategory)
    private readonly menuCategoryRepo: Repository<MenuCategory>,
  ) {}

  async importData() {
    await this.restaurantRepo.query(`CREATE EXTENSION IF NOT EXISTS unaccent`);
    const filePath = path.join(process.cwd(), 'data', 'data_app.json');
    const jsonData = fs.readFileSync(filePath, 'utf8');
    const cities: any[] = JSON.parse(jsonData);

    for (const cityData of cities) {
      const city = cityData.city;

      for (const category of cityData.categories) {
        // Tạo/tìm category
        let categoryEntity = await this.categoryRepo.findOne({
          where: { name: category.category },
        });

        if (!categoryEntity) {
          categoryEntity = this.categoryRepo.create({
            name: category.category,
            image_url: category.url_category_image || '',
          });
          categoryEntity = await this.categoryRepo.save(categoryEntity);
        }

        for (const shop of category.shops) {
          const merchant = shop.merchant;

          // Tạo restaurant
          const restaurant = this.restaurantRepo.create({
            restaurant_id: merchant.id,
            name: merchant.name,
            city: city,
            shop_image_url: merchant.photoHref,
            longitude: merchant.latlng.longitude,
            latitude: merchant.latlng.latitude,
            rating: merchant.rating,
          });
          const savedRestaurant = await this.restaurantRepo.save(restaurant);

          // Mapping restaurant - category
          const mapping = this.categoryMappingRepo.create({
            restaurant_id: savedRestaurant.restaurant_id,
            category_id: categoryEntity.category_id,
          });
          await this.categoryMappingRepo.save(mapping);

          // Insert promotions nếu có
          if (merchant.promotions?.length > 0) {
            const promotions = merchant.promotions.map((promo) =>
              this.promotionRepo.create({
                title: promo.title,
                promoCode: promo.promo_code,
                description: promo.description,
                discountType: promo.discount_type,
                discountValue: promo.discount_value.toString(),
                minOrderValue: promo.min_order_value?.toString() || '0',
                maxDiscountAmount: promo.max_discount_amount?.toString(),
                startDate: new Date(promo.start_date),
                endDate: new Date(promo.end_date),
                restaurant: savedRestaurant,
              }),
            );
            await this.promotionRepo.save(promotions);
          }

          // Insert menu items từ menu.categories[].items
          if (merchant.menu?.categories?.length > 0) {
            for (const itemCategory of merchant.menu.categories) {
              // Tạo hoặc lấy menu category
              let menuCategoryEntity = await this.menuCategoryRepo.findOne({
                where: {
                  name: itemCategory.name,
                  restaurant: savedRestaurant,
                },
              });

              if (!menuCategoryEntity) {
                menuCategoryEntity = this.menuCategoryRepo.create({
                  categoryId: itemCategory.id,
                  name: itemCategory.name,
                  restaurant: savedRestaurant,
                });
                menuCategoryEntity =
                  await this.menuCategoryRepo.save(menuCategoryEntity);
              }

              // Duyệt menu item
              for (const item of itemCategory.items || []) {
                if (!item.available) continue;

                const menuItem = this.menuItemRepo.create({
                  item_id: item.id,
                  name: item.name,
                  description: item.description || '',
                  price: item.priceInMinorUnit ?? 0,
                  image_url:
                    item.imgHref ||
                    'https://inkythuatso.com/uploads/thumbnails/800/2021/12/logo-grab-food-inkythuatso-20-15-57-46.jpg',
                  restaurant: savedRestaurant,
                  menuCategory: menuCategoryEntity,
                });
                const savedItem = await this.menuItemRepo.save(menuItem);

                // Duyệt modifierGroups (customizations)
                for (const group of item.modifierGroups || []) {
                  const customizationCategory =
                    this.customizationCategoryRepo.create({
                      categoryId: group.id,
                      name: group.name,
                      restaurantId: savedRestaurant,
                      minSelections: group.selectionType ?? 0,
                      maxSelections: group.selectionRangeMax ?? 1,
                      available: group.available ?? true,
                    });
                  const savedCategory =
                    await this.customizationCategoryRepo.save(
                      customizationCategory,
                    );

                  // Mapping item <-> customizationCategory
                  const itemCustomization =
                    this.itemCustomizationCategoryRepo.create({
                      itemId: savedItem.item_id,
                      categoryId: savedCategory.categoryId,
                    });
                  await this.itemCustomizationCategoryRepo.save(
                    itemCustomization,
                  );

                  // Insert customization options
                  const options = (group.modifiers || []).map((mod) =>
                    this.customizationOptionRepo.create({
                      optionId: mod.id,
                      name: mod.name,
                      additionalPrice: mod.priceInMinorUnit?.toString() || '0',
                      categoryId: savedCategory,
                      available: mod.available ?? true,
                    }),
                  );
                  await this.customizationOptionRepo.save(options);
                }
              }
            }
          }
        }
      }
    }

    console.log('✅ Data import completed');

    return;
  }
}
