import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { MenuItem } from 'src/database/entities/menu-item.entity';
import * as fs from 'fs';
import * as path from 'path';
import * as unzipper from 'unzipper';
import { Restaurant } from 'src/database/entities/restaurant/restaurant.entity';
import { RestaurantCategory } from 'src/database/entities/restaurant/restaurant-category.entity';
import { RestaurantCategoryMapping } from 'src/database/entities/restaurant/restaurant-category-mapping.entity';
import { Promotion } from 'src/database/entities/restaurant/promotions/promotion.entity';
import { CustomizationCategory } from 'src/database/entities/restaurant/category/customization-category.entity';
import { CustomizationOption } from 'src/database/entities/restaurant/category/customization-option.entity';
import { ItemCustomizationCategory } from 'src/database/entities/restaurant/category/item-customization-category.entity';
import { MenuCategory } from 'src/database/entities/restaurant/category/menu-categories.entity';
import { v4 as uuidv4 } from 'uuid';

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
    await this.restaurantRepo.query(`CREATE EXTENSION IF NOT EXISTS postgis`);

    // Bước 1: Giải nén zip
    const zipPath = path.join(process.cwd(), 'data', 'data_app.zip');
    const extractPath = path.join(process.cwd(), 'data', 'extracted');

    if (!fs.existsSync(extractPath)) {
      fs.mkdirSync(extractPath, { recursive: true });
    }

    // Xử lý tuần tự thay vì đợi toàn bộ tệp giải nén xong
    await new Promise((resolve, reject) => {
      fs.createReadStream(zipPath)
        .pipe(unzipper.Extract({ path: extractPath }))
        .on('error', reject)
        .on('close', resolve);
    });

    // Bước 2: Xử lý tệp JSON theo phần nhỏ thay vì đọc toàn bộ vào bộ nhớ
    const jsonPath = path.join(extractPath, 'data_app.json');
    const jsonData = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));
    const cities = jsonData;

    // Xử lý từng thành phố một để giảm tải
    for (const cityData of cities) {
      const city = cityData.city;
      console.log(`Processing city: ${city}`);

      for (const category of cityData.categories) {
        console.log(`Processing category: ${category.category}`);

        // Tạo/tìm category
        let categoryEntity = await this.categoryRepo.findOne({
          where: { name: category.category },
        });

        if (!categoryEntity) {
          categoryEntity = this.categoryRepo.create({
            category_id: uuidv4(),
            name: category.category,
            image_url: category.url_category_image || '',
          });
          categoryEntity = await this.categoryRepo.save(categoryEntity);
        }

        // Xử lý shop theo lô
        const batchSize = 5; // Số lượng shop xử lý mỗi lần
        for (let i = 0; i < category.shops.length; i += batchSize) {
          const shopBatch = category.shops.slice(i, i + batchSize);
          console.log(
            `Processing shops batch ${i / batchSize + 1}/${Math.ceil(category.shops.length / batchSize)}`,
          );

          // Xử lý từng shop trong lô
          for (const shop of shopBatch) {
            const merchant = shop.merchant;

            // Tạo restaurant
            let savedRestaurant;
            try {
              const restaurant = this.restaurantRepo.create({
                restaurant_id: merchant.ID,
                name: merchant.name,
                city: city,
                shop_image_url: merchant.photoHref,
                longitude: merchant.latlng.longitude,
                latitude: merchant.latlng.latitude,
                rating: merchant.rating,
              });
              savedRestaurant = await this.restaurantRepo.save(restaurant);

              // Mapping restaurant - category
              const mapping = this.categoryMappingRepo.create({
                restaurant_id: savedRestaurant.restaurant_id,
                category_id: categoryEntity.category_id,
              });
              await this.categoryMappingRepo.save(mapping);
            } catch (error) {
              console.error(
                `Error saving restaurant ${merchant.name}:`,
                error.message,
              );
              continue; // Skip to next shop if this one fails
            }

            // Xử lý promotions theo lô nếu có
            if (merchant.promotions?.length > 0) {
              try {
                const promotionEntities = merchant.promotions.map((promo) =>
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
                await this.promotionRepo.save(promotionEntities);
              } catch (error) {
                console.error(
                  `Error saving promotions for ${merchant.name}:`,
                  error.message,
                );
                // Continue processing other parts even if promotions fail
              }
            }

            // Xử lý menu items
            if (merchant.menu?.categories?.length > 0) {
              for (const itemCategory of merchant.menu.categories) {
                // Tạo hoặc lấy menu category
                let menuCategoryEntity;
                try {
                  menuCategoryEntity = await this.menuCategoryRepo.findOne({
                    where: {
                      name: itemCategory.name,
                      restaurant: savedRestaurant,
                    },
                  });

                  if (!menuCategoryEntity) {
                    menuCategoryEntity = this.menuCategoryRepo.create({
                      categoryId: itemCategory.ID,
                      name: itemCategory.name,
                      restaurant: savedRestaurant,
                    });
                    menuCategoryEntity =
                      await this.menuCategoryRepo.save(menuCategoryEntity);
                  }
                } catch (error) {
                  console.error(
                    `Error with menu category ${itemCategory.name}:`,
                    error.message,
                  );
                  continue; // Skip to next category if this one fails
                }

                // Xử lý items theo lô
                const menuItemBatchSize = 10;
                const availableItems = (itemCategory.items || []).filter(
                  (item) => item.available,
                );

                for (
                  let j = 0;
                  j < availableItems.length;
                  j += menuItemBatchSize
                ) {
                  const itemBatch = availableItems.slice(
                    j,
                    j + menuItemBatchSize,
                  );
                  const menuItemEntities: MenuItem[] = [];

                  // Tạo các entities cho menu items
                  for (const item of itemBatch) {
                    const menuItem = this.menuItemRepo.create({
                      item_id: item.ID,
                      name: item.name,
                      description: item.description || '',
                      price: item.priceInMinorUnit ?? 0,
                      image_url:
                        item.imgHref ||
                        'https://inkythuatso.com/uploads/thumbnails/800/2021/12/logo-grab-food-inkythuatso-20-15-57-46.jpg',
                      restaurant: savedRestaurant,
                      menuCategory: menuCategoryEntity,
                    });
                    menuItemEntities.push(menuItem);
                  }

                  // Lưu menu items theo lô
                  try {
                    const savedItems =
                      await this.menuItemRepo.save(menuItemEntities);

                    // Xử lý customizations cho từng item đã lưu
                    for (let k = 0; k < savedItems.length; k++) {
                      const savedItem = savedItems[k];
                      const originalItem = itemBatch[k];

                      // Xử lý modifierGroups cho item
                      for (const group of originalItem.modifierGroups || []) {
                        try {
                          // Tạo customization category
                          const customizationCategory =
                            this.customizationCategoryRepo.create({
                              categoryId: group.ID,
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

                          // Tạo và lưu options theo lô
                          if (group.modifiers?.length > 0) {
                            const optionEntities = group.modifiers.map((mod) =>
                              this.customizationOptionRepo.create({
                                optionId: mod.ID,
                                name: mod.name,
                                additionalPrice:
                                  mod.priceInMinorUnit?.toString() || '0',
                                categoryId: savedCategory,
                                available: mod.available ?? true,
                              }),
                            );
                            await this.customizationOptionRepo.save(
                              optionEntities,
                            );
                          }
                        } catch (error) {
                          console.error(
                            `Error processing modifier group ${group.name}:`,
                            error.message,
                          );
                          // Tiếp tục với group tiếp theo nếu có lỗi
                        }
                      }
                    }
                  } catch (error) {
                    console.error(
                      `Error saving menu items batch:`,
                      error.message,
                    );
                    // Tiếp tục với batch tiếp theo nếu có lỗi
                  }

                  // Thêm độ trễ nhỏ giữa các batch để giảm áp lực cho DB
                  await new Promise((resolve) => setTimeout(resolve, 100));
                }
              }
            }
          }

          // Thêm độ trễ giữa các batch shop để giảm tải
          await new Promise((resolve) => setTimeout(resolve, 500));
        }
      }
    }

    console.log('✅ Data import completed');
    return;
  }
}
