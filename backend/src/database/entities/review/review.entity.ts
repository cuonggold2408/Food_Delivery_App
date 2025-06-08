import { MenuItem } from 'src/database/entities/menu-item.entity';
import { Order } from 'src/database/entities/order/order.entity';
import { ReviewMedia } from 'src/database/entities/review/review-media.entity';
import { User } from 'src/database/entities/user.entity';
import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  OneToMany,
} from 'typeorm';

@Entity('reviews')
export class Review {
  @PrimaryGeneratedColumn()
  review_id: number;

  @ManyToOne(() => User, (user) => user.user_id)
  @JoinColumn({ name: 'user_id' })
  user: User;

  @ManyToOne(() => Order, (order) => order.order_id)
  @JoinColumn({ name: 'order_id' })
  order: Order;

  @ManyToOne(() => MenuItem, (menuItem) => menuItem.item_id)
  @JoinColumn({ name: 'item_id' })
  menuItem: MenuItem;

  @Column({ type: 'int' })
  rating: number;

  @Column('text')
  review_text: string;

  @Column('text', { nullable: true })
  review_reply: string;

  @Column({ type: 'timestamp', nullable: true })
  reply_date: Date;

  @Column({ default: true })
  is_public: boolean;

  @Column({ default: 1 })
  update_count: number;

  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP' })
  created_at: Date;

  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP' })
  updated_at: Date;

  @OneToMany(() => ReviewMedia, (reviewMedia) => reviewMedia.review)
  media: ReviewMedia[];
}
