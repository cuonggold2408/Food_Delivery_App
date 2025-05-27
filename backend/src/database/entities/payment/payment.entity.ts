import { Order } from 'src/database/entities/order/order.entity';
import { PaymentStatus } from 'src/shared/constants/payment.constant';
import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  OneToMany,
} from 'typeorm';

@Entity({ name: 'payments' })
export class Payment {
  @PrimaryGeneratedColumn()
  payment_id: number;

  @OneToMany(() => Order, (order) => order.payment)
  orders: Order[];

  @Column({ type: 'varchar', length: 50, default: PaymentStatus.PENDING })
  payment_status: PaymentStatus;

  @CreateDateColumn({ type: 'timestamp' })
  created_at: Date;

  @UpdateDateColumn({ type: 'timestamp' })
  updated_at: Date;
}
