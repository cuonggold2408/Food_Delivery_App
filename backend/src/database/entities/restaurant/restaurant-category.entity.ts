import { RestaurantCategoryMapping } from 'src/database/entities/restaurant/restaurant-category-mapping.entity';
import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  OneToMany,
} from 'typeorm';

@Entity('restaurant_categories')
export class RestaurantCategory {
  @PrimaryGeneratedColumn()
  category_id: number;

  @Column({ type: 'varchar', length: 100 })
  name: string;

  @Column({ type: 'varchar', length: 255, nullable: false })
  image_url: string;

  @CreateDateColumn()
  created_at: Date;

  @UpdateDateColumn()
  updated_at: Date;

  @OneToMany(() => RestaurantCategoryMapping, (mapping) => mapping.category)
  mappings: RestaurantCategoryMapping[];
}
