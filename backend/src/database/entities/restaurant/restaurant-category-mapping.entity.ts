import { Entity, PrimaryColumn, ManyToOne, JoinColumn } from 'typeorm';
import { Restaurant } from './restaurant.entity';
import { RestaurantCategory } from './restaurant-category.entity';

@Entity('restaurant_category_mappings')
export class RestaurantCategoryMapping {
  @PrimaryColumn()
  restaurant_id: string;

  @PrimaryColumn()
  category_id: string;

  @ManyToOne(() => Restaurant, (restaurant) => restaurant.mappings, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'restaurant_id' })
  restaurant: Restaurant;

  @ManyToOne(() => RestaurantCategory, (category) => category.mappings, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'category_id' })
  category: RestaurantCategory;
}
