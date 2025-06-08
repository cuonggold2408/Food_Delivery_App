import { Review } from 'src/database/entities/review/review.entity';
import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
} from 'typeorm';

@Entity('review_media')
export class ReviewMedia {
  @PrimaryGeneratedColumn()
  media_id: number;

  @ManyToOne(() => Review, (review) => review.media)
  @JoinColumn({ name: 'review_id' })
  review: Review;

  @Column({ type: 'varchar', length: 1000 })
  url: string;

  @Column({ type: 'varchar', length: 20 })
  type: string; // Ví dụ: image, video, audio

  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP' })
  created_at: Date;
}
