import { CustomizationCategory } from 'src/database/entities/restaurant/category/customization-category.entity';
import { Entity, Column, ManyToOne, JoinColumn, PrimaryColumn } from 'typeorm';

@Entity({ name: 'customization_options' })
export class CustomizationOption {
  @PrimaryColumn({ name: 'option_id' })
  optionId: string;

  @ManyToOne(() => CustomizationCategory, (c) => c.categoryId, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'category_id' })
  categoryId: CustomizationCategory;

  @Column({ length: 100 })
  name: string;

  @Column('numeric', {
    name: 'additional_price',
    precision: 10,
    scale: 2,
    default: 0,
  })
  additionalPrice: string;

  @Column({ default: true })
  available: boolean;

  @Column({ name: 'display_order', default: 0 })
  displayOrder: number;

  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP' })
  created_at: Date;

  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP' })
  updated_at: Date;
}
