import { MenuItem } from 'src/database/entities/menu-item.entity';
import { Restaurant } from 'src/database/entities/restaurant/restaurant.entity';
import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  OneToMany,
  Index,
  PrimaryColumn,
} from 'typeorm';

@Entity({ name: 'menu_categories' })
export class MenuCategory {
  @PrimaryColumn({ name: 'category_id' })
  categoryId: string;
  @PrimaryGeneratedColumn({ name: 'category_id' })
  categoryId: number;

  @Index()
  @Column({ length: 100, nullable: false })
  name: string;

  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP' })
  created_at: Date;

  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP' })
  updated_at: Date;

  @ManyToOne(() => Restaurant, (restaurant) => restaurant.menuCategories, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'restaurant_id' })
  restaurant: Restaurant;

  @OneToMany(() => MenuItem, (item) => item.menuCategory)
  menuItems: MenuItem[];
}
