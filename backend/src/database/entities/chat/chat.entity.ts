import { Message } from 'src/database/entities/chat/message.entity';
import { User } from 'src/database/entities/user.entity';
import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  OneToMany,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

export enum ChatStatus {
  ACTIVE = 'active',
  CLOSED = 'closed',
  PENDING = 'pending',
}

@Entity('chats')
export class Chat {
  @PrimaryGeneratedColumn()
  chat_id: number;

  @Column({ type: 'int', nullable: false })
  user_id: number;

  @Column({ type: 'int', nullable: true })
  admin_id: number;

  @Column({
    type: 'enum',
    enum: ChatStatus,
    default: ChatStatus.PENDING,
  })
  status: ChatStatus;

  @Column({ type: 'varchar', length: 255, nullable: true })
  subject: string;

  @Column({ type: 'timestamp', nullable: true })
  last_message_at: Date;

  @CreateDateColumn()
  created_at: Date;

  @UpdateDateColumn()
  updated_at: Date;

  @ManyToOne(() => User, (user) => user.user_chats)
  @JoinColumn({ name: 'user_id' })
  user: User;

  @ManyToOne(() => User, (admin) => admin.admin_chats)
  @JoinColumn({ name: 'admin_id' })
  admin: User;

  @OneToMany(() => Message, (message) => message.chat)
  messages: Message[];
}
