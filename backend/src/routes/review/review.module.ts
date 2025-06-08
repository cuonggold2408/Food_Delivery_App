import { Module } from '@nestjs/common';
import { ReviewController } from './review.controller';
import { ReviewService } from './review.service';
import { ReviewRepository } from 'src/routes/review/review.repo';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Review } from 'src/database/entities/review/review.entity';
import { ReviewMedia } from 'src/database/entities/review/review-media.entity';
import { Order } from 'src/database/entities/order/order.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Review, ReviewMedia, Order])],
  controllers: [ReviewController],
  providers: [ReviewService, ReviewRepository],
})
export class ReviewModule {}
