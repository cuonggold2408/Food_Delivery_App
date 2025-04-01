import { User } from 'src/database/entities/user.entity';
import {
  Column,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';

@Entity('auth_providers')
@Index(['user_id', 'provider_name'], { unique: true })
export class AuthProvider {
  @PrimaryGeneratedColumn()
  auth_id: number;

  @ManyToOne(() => User, (user) => user.auth_providers, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column({ type: 'int', nullable: false })
  user_id: number;

  @Column({ type: 'varchar', length: 50, nullable: false })
  provider_name: string;

  @Column({ type: 'varchar', length: 255, nullable: true })
  provider_user_id: string;

  @Column({ type: 'varchar', length: 255, nullable: true })
  refresh_token: string;

  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP' })
  created_at: Date;

  @Column({
    type: 'timestamp',
    default: () => 'CURRENT_TIMESTAMP',
    onUpdate: 'CURRENT_TIMESTAMP',
  })
  updated_at: Date;

  @Column({ type: 'timestamp', nullable: true })
  expired_at: Date;
}
