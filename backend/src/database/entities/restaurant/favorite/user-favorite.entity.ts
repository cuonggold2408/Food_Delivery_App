import {
  Entity,
  PrimaryColumn,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
} from 'typeorm';
import { User } from 'src/database/entities/user.entity';
import { Restaurant } from 'src/database/entities/restaurant/restaurant.entity';

@Entity('user_favorite_restaurants')
export class UserFavoriteRestaurant {
  @PrimaryColumn()
  user_id: number;

  @PrimaryColumn()
  restaurant_id: number;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user: User;

  @ManyToOne(() => Restaurant, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'restaurant_id' })
  restaurant: Restaurant;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}
