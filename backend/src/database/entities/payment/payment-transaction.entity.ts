import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
} from 'typeorm';

@Entity({ name: 'payment_transactions' })
export class PaymentTransaction {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ type: 'varchar', length: 100 })
  gateway: string;

  @Column({
    type: 'timestamp',
  })
  transaction_date: Date;

  @Column({ type: 'varchar', length: 100, nullable: true })
  account_number: string;

  @Column({ type: 'varchar', length: 250, nullable: true })
  sub_account: string;

  @Column({ type: 'decimal', precision: 20, scale: 2, default: 0.0 })
  amount_in: string;

  @Column({ type: 'decimal', precision: 20, scale: 2, default: 0.0 })
  amount_out: string;

  @Column({ type: 'decimal', precision: 20, scale: 2, default: 0.0 })
  accumulated: string;

  @Column({ type: 'varchar', length: 250, nullable: true })
  code: string;

  @Column({ type: 'text', nullable: true })
  transaction_content: string;

  @Column({ type: 'varchar', length: 255, nullable: true })
  reference_number: string;

  @Column({ type: 'text', nullable: true })
  body: string;

  @CreateDateColumn({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP' })
  created_at: Date;
}
