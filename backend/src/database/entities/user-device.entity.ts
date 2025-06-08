import { User } from 'src/database/entities/user.entity';
import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  Unique,
} from 'typeorm';

@Entity('user_devices')
@Unique(['user_id', 'device_token'])
@Index(['user_id', 'device_token'])
export class UserDevice {
  @PrimaryGeneratedColumn()
  device_id: number;

  @Column({ type: 'integer', nullable: false })
  user_id: number;

  @Column({ type: 'varchar', length: 255, nullable: false })
  device_token: string;

  @Column({ type: 'varchar', length: 50, nullable: false })
  device_type: string;

  @Column({ type: 'boolean', default: true })
  is_active: boolean;

  @CreateDateColumn()
  created_at: Date;

  @CreateDateColumn()
  updated_at: Date;

  @ManyToOne(() => User, (user) => user.user_id)
  @JoinColumn({ name: 'user_id' })
  user: User;
}

// Table user_devices {
//     device_id SERIAL [pk]
//     user_id INTEGER [not null, ref: > users.user_id]
//     device_token VARCHAR(255) [not null]
//     device_type VARCHAR(50) [not null] // android, ios, web
//     is_active BOOLEAN [default: true]
//     created_at TIMESTAMP [not null, default: CURRENT_TIMESTAMP]
//     updated_at TIMESTAMP [not null, default: CURRENT_TIMESTAMP]
//     indexes {
//       (user_id, device_token) [unique]
//     }
//   }
