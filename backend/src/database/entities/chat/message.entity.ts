import { User } from 'src/database/entities/user.entity';
import { Chat } from 'src/database/entities/chat/chat.entity';
import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';

export enum MessageType {
  TEXT = 'text',
  IMAGE = 'image',
  FILE = 'file',
  SYSTEM = 'system',
}

export enum SenderType {
  USER = 'user',
  ADMIN = 'admin',
  SYSTEM = 'system',
}

@Entity('messages')
export class Message {
  @PrimaryGeneratedColumn()
  message_id: number;

  @Column({ type: 'int', nullable: false })
  chat_id: number;

  @Column({ type: 'int', nullable: false })
  sender_id: number;

  @Column({
    type: 'enum',
    enum: SenderType,
    nullable: false,
  })
  sender_type: SenderType;

  @Column({
    type: 'enum',
    enum: MessageType,
    default: MessageType.TEXT,
  })
  message_type: MessageType;

  @Column({ type: 'text', nullable: false })
  content: string;

  @Column({ type: 'varchar', length: 500, nullable: true })
  attachment_url: string;

  @Column({ type: 'boolean', default: false })
  is_read: boolean;

  @Column({ type: 'timestamp', nullable: true })
  read_at: Date;

  @CreateDateColumn()
  created_at: Date;

  @ManyToOne(() => Chat, (chat) => chat.messages)
  @JoinColumn({ name: 'chat_id' })
  chat: Chat;

  @ManyToOne(() => User, (user) => user.sent_messages)
  @JoinColumn({ name: 'sender_id' })
  sender: User;
}
