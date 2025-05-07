import {
  Entity,
  Column,
  ManyToOne,
  JoinColumn,
  OneToMany,
  Index,
  PrimaryColumn,
} from 'typeorm';
import { Restaurant } from 'src/database/entities/restaurant/restaurant.entity';
import { MenuCategory } from 'src/database/entities/restaurant/category/menu-categories.entity';
import { ItemCustomizationCategory } from 'src/database/entities/restaurant/category/item-customization-category.entity';

@Entity('menu_items')
export class MenuItem {
  @PrimaryColumn()
  item_id: string;

  @ManyToOne(() => Restaurant, (restaurant) => restaurant.menuItems, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'restaurant_id' })
  restaurant: Restaurant;

  @ManyToOne(() => MenuCategory, (category) => category.menuItems, {
    onDelete: 'SET NULL',
    nullable: true,
  })
  @JoinColumn({ name: 'menu_category_id' })
  menuCategory: MenuCategory;

  @OneToMany(() => ItemCustomizationCategory, (icc) => icc.item)
  customizationMappings: ItemCustomizationCategory[];

  @Index('item_name_index')
  @Column({ type: 'varchar', length: 255 })
  name: string;

  @Column({ type: 'text', nullable: true })
  description: string;

  @Column({ type: 'varchar', length: 255, default: '0' })
  price: string;

  @Column({ type: 'varchar', length: 255, nullable: true })
  image_url: string;

  @Column({ type: 'boolean', default: true })
  is_available: boolean;

  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP' })
  created_at: Date;

  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP' })
  updated_at: Date;
}
