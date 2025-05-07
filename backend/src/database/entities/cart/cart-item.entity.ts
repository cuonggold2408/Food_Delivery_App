import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  OneToMany,
  CreateDateColumn,
  UpdateDateColumn,
  JoinColumn,
} from 'typeorm';
import { Cart } from './cart.entity';
import { CartItemCustomization } from 'src/database/entities/cart/cart-item-customization.entity';
import { MenuItem } from 'src/database/entities/menu-item.entity';

@Entity({ name: 'cart_items' })
export class CartItem {
  @PrimaryGeneratedColumn()
  cart_item_id: number;

  @ManyToOne(() => Cart, (cart) => cart.items, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'cart_id' })
  cart: Cart;

  @ManyToOne(() => MenuItem, (mi) => mi.item_id, { eager: true })
  @JoinColumn({ name: 'item_id' })
  menuItem: MenuItem;

  @Column({ type: 'int' })
  quantity: number;

  @Column({ type: 'decimal', precision: 10, scale: 2 })
  total_pay: string;

  @Column({ type: 'text', nullable: true })
  message?: string;

  @OneToMany(() => CartItemCustomization, (cic) => cic.cartItem, {
    cascade: true,
  })
  customizations: CartItemCustomization[];

  @CreateDateColumn({ type: 'timestamp' })
  created_at: Date;

  @UpdateDateColumn({ type: 'timestamp' })
  updated_at: Date;
}
