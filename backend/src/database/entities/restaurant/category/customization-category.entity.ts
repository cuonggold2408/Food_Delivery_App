import { CustomizationOption } from 'src/database/entities/restaurant/category/customization-option.entity';
import { Restaurant } from 'src/database/entities/restaurant/restaurant.entity';
import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  OneToMany,
  PrimaryColumn,
} from 'typeorm';

@Entity({ name: 'customization_categories' })
export class CustomizationCategory {
  @PrimaryColumn({ name: 'category_id' })
  categoryId: string;
  @PrimaryGeneratedColumn({ name: 'category_id' })
  categoryId: number;

  @ManyToOne(() => Restaurant, (r) => r.restaurant_id, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'restaurant_id' })
  restaurantId: Restaurant;

  @OneToMany(() => CustomizationOption, (option) => option.categoryId)
  options: CustomizationOption[];

  @Column({ length: 100, nullable: false })
  name: string;

  @Column({ default: true })
  available: boolean;

  @Column({ name: 'min_selections', default: 0 })
  minSelections: number;

  @Column({ name: 'max_selections', default: 1 })
  maxSelections: number;

  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP' })
  created_at: Date;

  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP' })
  updated_at: Date;
}
