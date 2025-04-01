import { AuthProvider } from 'src/database/entities/auth-provider.entity';
import { Column, Entity, OneToMany, PrimaryGeneratedColumn } from 'typeorm';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn()
  user_id: number;

  @Column({ type: 'varchar', length: 255, unique: true, nullable: false })
  email: string;

  @Column({ type: 'varchar', length: 20, unique: true, nullable: true })
  phone_number: string;

  @Column({ type: 'varchar', length: 255, nullable: false })
  password: string;

  @Column({ type: 'varchar', length: 50, nullable: false })
  name: string;

  @Column({ type: 'varchar', length: 255, nullable: true })
  profile_image_url: string;

  @Column({ type: 'varchar', length: 20, default: 'customer' })
  user_role: string;

  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP' })
  created_at: Date;

  @Column({
    type: 'timestamp',
    default: () => 'CURRENT_TIMESTAMP',
    onUpdate: 'CURRENT_TIMESTAMP',
  })
  updated_at: Date;

  @Column({ type: 'boolean', default: false })
  is_email_verified: boolean;

  @Column({ type: 'varchar', length: 10, nullable: true })
  otp_code: string;

  @Column({ type: 'timestamp', nullable: true })
  otp_expiry: Date;

  @OneToMany(() => AuthProvider, (authProvider) => authProvider.user)
  auth_providers: AuthProvider[];
}
