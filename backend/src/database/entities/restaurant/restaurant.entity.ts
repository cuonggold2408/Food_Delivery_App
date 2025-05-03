import { MenuItem } from 'src/database/entities/menu-item.entity';
import { MenuCategory } from 'src/database/entities/restaurant/category/menu-categories.entity';
import { UserFavoriteRestaurant } from 'src/database/entities/restaurant/favorite/user-favorite.entity';
import { RestaurantCategoryMapping } from 'src/database/entities/restaurant/restaurant-category-mapping.entity';
import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  OneToMany,
  Index,
} from 'typeorm';

@Entity('restaurants')
@Index(['name', 'city'])
export class Restaurant {
  @PrimaryGeneratedColumn()
  restaurant_id: number;

  @Column({ type: 'varchar', length: 255 })
  name: string;

  @Column({ type: 'varchar', length: 100 })
  city: string;

  @Column({ type: 'varchar', length: 255, nullable: true })
  shop_image_url: string;

  @Column({ type: 'boolean', default: true })
  is_active: boolean;

  @Column('decimal', { precision: 10, scale: 8 })
  latitude: number;

  @Column('decimal', { precision: 11, scale: 8 })
  longitude: number;

  @Column({ type: 'float', default: 0 })
  rating: number;

  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP' })
  created_at: Date;

  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP' })
  updated_at: Date;

  @OneToMany(() => RestaurantCategoryMapping, (mapping) => mapping.restaurant)
  mappings: RestaurantCategoryMapping[];

  @OneToMany(() => MenuItem, (menuItem) => menuItem.restaurant, {
    cascade: true,
  })
  menuItems: MenuItem[];
  @OneToMany(() => MenuCategory, (menuCategory) => menuCategory.restaurant, {
    cascade: true,
  })
  menuCategories: MenuCategory[];

  @OneToMany(
    () => UserFavoriteRestaurant,
    (userFavorite) => userFavorite.restaurant,
    {
      cascade: true,
    },
  )
  userFavorites: UserFavoriteRestaurant[];
}
