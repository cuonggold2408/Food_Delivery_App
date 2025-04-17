import { User } from 'src/database/entities/user.entity';
import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

export enum AddressLabel {
  HOME = 'home',
  WORK = 'work',
  OTHER = 'other',
}

@Entity('user_addresses')
export class UserAddress {
  @PrimaryGeneratedColumn()
  address_id: number;

  @ManyToOne(() => User, (user) => user.user_address, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column({ type: 'varchar', length: 100 })
  address_name: string;

  @Column({ enum: AddressLabel, length: 20 })
  label: AddressLabel;

  @Column({ type: 'varchar', length: 20 })
  phone_number: string;

  @Column({ type: 'varchar', length: 100 })
  recipient_name: string;

  @Column({ type: 'varchar', length: 255, nullable: true })
  street_address: string;

  @Column({ type: 'varchar', length: 50, nullable: true })
  apartment: string;

  // @Column({ type: 'boolean', default: false })
  // is_default: boolean;

  @Column('decimal', { precision: 10, scale: 8 })
  latitude: number;

  @Column('decimal', { precision: 11, scale: 8 })
  longitude: number;

  @CreateDateColumn({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP' })
  created_at: Date;

  @UpdateDateColumn({
    type: 'timestamp',
    default: () => 'CURRENT_TIMESTAMP',
    onUpdate: 'CURRENT_TIMESTAMP',
  })
  updated_at: Date;
}
