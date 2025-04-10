import { Column, Entity, Index, PrimaryGeneratedColumn } from 'typeorm';

export enum TypeVerificationCode {
  REGISTER = 'REGISTER',
  FORGOT_PASSWORD = 'FORGOT_PASSWORD',
}

@Entity('verification_code')
export class VerificationCode {
  @PrimaryGeneratedColumn()
  id: number;

  @Index('idx_verification_email', { unique: true })
  @Column({ type: 'varchar', length: 255, unique: true, nullable: false })
  email: string;

  @Index('idx_verification_code')
  @Column({ type: 'varchar', length: 10, nullable: false })
  code: string;

  @Column({ type: 'timestamp', nullable: false })
  expires_at: Date;

  @Index('idx_verification_type')
  @Column({
    type: 'enum',
    enum: TypeVerificationCode,
  })
  type: TypeVerificationCode;

  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP' })
  created_at: Date;
}
