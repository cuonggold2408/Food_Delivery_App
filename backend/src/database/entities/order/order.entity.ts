import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  CreateDateColumn,
  UpdateDateColumn,
  JoinColumn,
} from 'typeorm';
import { Restaurant } from 'src/database/entities/restaurant/restaurant.entity';
import { Payment } from 'src/database/entities/payment/payment.entity';
import { User } from 'src/database/entities/user.entity';

export enum OrderStatus {
  PENDING_PAYMENT = 'PENDING_PAYMENT',
  PENDING_PICKUP = 'PENDING_PICKUP',
  PENDING_DELIVERY = 'PENDING_DELIVERY',
  DELIVERED = 'DELIVERED',
  CANCELLED = 'CANCELLED',
}

export enum DeliveryMethod {
  STANDARD = 'STANDARD',
  EXPRESS = 'EXPRESS',
  ECONOMY = 'ECONOMY',
}

export enum PaymentMethod {
  COD = 'COD',
  BANK_TRANSFER = 'BANK_TRANSFER',
}

@Entity({ name: 'orders' })
export class Order {
  @PrimaryGeneratedColumn()
  order_id: number;

  @ManyToOne(() => Restaurant)
  @JoinColumn({ name: 'restaurant_id' })
  restaurant: Restaurant;

  @Column({ type: 'jsonb' })
  receiver: JSON;

  @Column({ type: 'jsonb' })
  items: JSON;

  @Column({
    type: 'varchar',
    length: 50,
    default: OrderStatus.PENDING_PAYMENT,
  })
  order_status: OrderStatus;

  @ManyToOne(() => Payment)
  @JoinColumn({ name: 'payment_id' })
  payment: Payment;

  @Column({ type: 'varchar', length: 255 })
  subtotal: string; // Tổng tiền sản phẩm

  @Column({ type: 'varchar', length: 255 })
  delivery_fee: string; // Phí vận chuyển

  @Column({ type: 'varchar', length: 255, default: '0' })
  discount: string; // Giảm giá

  @Column({ type: 'varchar', length: 255 })
  total_amount: string; // Tổng tiền đơn hàng

  @Column({ type: 'varchar', length: 50, default: PaymentMethod.BANK_TRANSFER })
  payment_method: PaymentMethod;

  @Column({ type: 'timestamp', nullable: true })
  estimated_delivery_time: Date;

  @Column({ type: 'varchar', length: 20, default: DeliveryMethod.STANDARD })
  delivery_method: DeliveryMethod;

  // @ManyToOne(() => User, { nullable: true })
  // @JoinColumn({ name: 'driver_id' })
  // driver: User;
  @ManyToOne(() => User)
  @JoinColumn({ name: 'user_id' })
  user: User;

  @CreateDateColumn({ type: 'timestamp' })
  created_at: Date;

  @UpdateDateColumn({ type: 'timestamp' })
  updated_at: Date;
}
