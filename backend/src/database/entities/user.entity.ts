import { AuthProvider } from 'src/database/entities/auth-provider.entity';
import { UserFavoriteRestaurant } from 'src/database/entities/restaurant/favorite/user-favorite.entity';
import { UserAddress } from 'src/database/entities/user-address.entity';
import { WebSocket } from 'src/database/entities/websocket/websocket.entity';
import { Column, Entity, OneToMany, PrimaryGeneratedColumn } from 'typeorm';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn()
  user_id: number;

  @Column({ type: 'varchar', length: 255, unique: true, nullable: false })
  email: string;

  @Column({ type: 'varchar', length: 255, nullable: false })
  password: string;

  @Column({ type: 'varchar', length: 50, nullable: false })
  name: string;

  @Column({ type: 'varchar', length: 20, default: 'customer' })
  user_role: string;

  @Column({ type: 'varchar', length: 255, nullable: false, default: '' })
  bio: string;

  @Column({ type: 'varchar', length: 255, nullable: false, default: '' })
  phone_number: string;

  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP' })
  created_at: Date;

  @Column({
    type: 'timestamp',
    default: () => 'CURRENT_TIMESTAMP',
    onUpdate: 'CURRENT_TIMESTAMP',
  })
  updated_at: Date;

  @OneToMany(() => AuthProvider, (authProvider) => authProvider.user)
  auth_providers: AuthProvider[];

  @OneToMany(() => UserAddress, (UserAddress) => UserAddress.user)
  user_address: UserAddress[];

  @OneToMany(() => UserFavoriteRestaurant, (favorite) => favorite.user)
  user_favorite_restaurants: UserFavoriteRestaurant[];

  @OneToMany(() => WebSocket, (websocket) => websocket.user)
  websockets: WebSocket[];
}
