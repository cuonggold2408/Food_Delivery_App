import { Entity, PrimaryGeneratedColumn, Column, ManyToOne } from 'typeorm';
import { Restaurant } from 'src/database/entities/restaurant/restaurant.entity';

@Entity('menu_items')
export class MenuItem {
  @PrimaryGeneratedColumn()
  item_id: number;

  @ManyToOne(() => Restaurant, (restaurant) => restaurant.menuItems, {
    onDelete: 'CASCADE',
  })
  restaurant: Restaurant;

  @Column({ type: 'varchar', length: 255 })
  name: string;

  @Column({ type: 'text', nullable: true })
  description: string;

  @Column({ type: 'varchar', length: 255 })
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
