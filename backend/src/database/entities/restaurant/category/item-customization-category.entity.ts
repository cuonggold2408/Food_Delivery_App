import { Entity, PrimaryColumn, ManyToOne, JoinColumn, Index } from 'typeorm';
import { MenuItem } from 'src/database/entities/menu-item.entity';
import { CustomizationCategory } from 'src/database/entities/restaurant/category/customization-category.entity';

@Entity({ name: 'item_customization_categories' })
@Index(['itemId', 'categoryId'], { unique: true })
export class ItemCustomizationCategory {
  /* ---------- Composite PK columns ---------- */
  @PrimaryColumn({ name: 'item_id' })
  itemId: string;

  @PrimaryColumn({ name: 'category_id' })
  categoryId: string;

  /* ---------- Relations ---------- */
  @ManyToOne(() => MenuItem, (i) => i.item_id, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'item_id' })
  item: MenuItem;

  @ManyToOne(() => CustomizationCategory, (c) => c.categoryId, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'category_id' })
  category: CustomizationCategory;
}
