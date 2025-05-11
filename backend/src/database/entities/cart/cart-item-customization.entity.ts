import { Column, Entity, JoinColumn, ManyToOne, PrimaryColumn } from 'typeorm';
import { CustomizationOption } from 'src/database/entities/restaurant/category/customization-option.entity';
import { CartItem } from 'src/database/entities/cart/cart-item.entity';

@Entity({ name: 'cart_item_customizations' })
export class CartItemCustomization {
  @PrimaryColumn()
  cart_item_id: number;

  @PrimaryColumn()
  option_id: number;

  @Column({ type: 'varchar', length: 255, default: '0' })
  price_option: string;

  @ManyToOne(() => CartItem, (ci) => ci.customizations, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'cart_item_id' })
  cartItem: CartItem;

  @ManyToOne(() => CustomizationOption, (co) => co.optionId)
  @JoinColumn({ name: 'option_id' })
  option: CustomizationOption;
}
