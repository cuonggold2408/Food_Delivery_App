import { MenuItem } from 'src/database/entities/menu-item.entity';
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

  @Column({ type: 'varchar', length: 255 })
  street_address: string;

  @Column({ type: 'varchar', length: 100 })
  city: string;

  @Column({ type: 'varchar', length: 255, nullable: true })
  shop_image_url: string;

  @Column({ type: 'boolean', default: true })
  is_active: boolean;

  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP' })
  created_at: Date;

  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP' })
  updated_at: Date;

  @OneToMany(() => MenuItem, (menuItem) => menuItem.restaurant, {
    cascade: true,
  })
  menuItems: MenuItem[];
}
