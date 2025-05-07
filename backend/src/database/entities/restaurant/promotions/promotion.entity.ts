import { MenuItem } from 'src/database/entities/menu-item.entity';
import { Restaurant } from 'src/database/entities/restaurant/restaurant.entity';
import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
} from 'typeorm';

@Entity({ name: 'promotions' })
export class Promotion {
  @PrimaryGeneratedColumn({ name: 'promotion_id' })
  promotionId: number;

  @Column({ type: 'varchar', length: 255 })
  title: string;

  @Column({ type: 'text', nullable: true })
  description?: string;

  @Column({
    name: 'promo_code',
    type: 'varchar',
    length: 50,
    nullable: true,
  })
  promoCode?: string;

  @Column({ name: 'discount_type', type: 'varchar', length: 20 })
  discountType: string; // 'percentage' or 'fixed_amount'

  @Column('numeric', { name: 'discount_value', precision: 10, scale: 2 })
  discountValue: string;

  @Column('numeric', {
    name: 'min_order_value',
    precision: 10,
    scale: 2,
    default: 0,
  })
  minOrderValue: string;

  @Column('numeric', {
    name: 'max_discount_amount',
    precision: 10,
    scale: 2,
    nullable: true,
  })
  maxDiscountAmount?: string;

  @Column({ name: 'start_date', type: 'timestamp' })
  startDate: Date;

  @Column({ name: 'end_date', type: 'timestamp' })
  endDate: Date;

  @Column({ name: 'usage_limit', type: 'int', nullable: true })
  usageLimit?: number;

  @Column({ name: 'times_used', type: 'int', default: 0 })
  timesUsed: number;

  @Column({ name: 'is_active', type: 'boolean', default: true })
  isActive: boolean;

  @ManyToOne(() => Restaurant, (r) => r.restaurant_id, { onDelete: 'SET NULL' })
  @JoinColumn({ name: 'restaurant_id' })
  restaurant?: Restaurant;

  @ManyToOne(() => MenuItem, (i) => i.item_id, { onDelete: 'SET NULL' })
  @JoinColumn({ name: 'item_id' })
  item?: MenuItem;

  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP' })
  created_at: Date;

  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP' })
  updated_at: Date;
}
