import { Injectable } from '@nestjs/common';
import {
  CreateReviewBodyType,
  UpdateReviewBodyType,
} from 'src/routes/review/review.model';
import { ReviewRepository } from 'src/routes/review/review.repo';

@Injectable()
export class ReviewService {
  constructor(private readonly reviewRepository: ReviewRepository) {}

  async list(itemId: string, page: number, limit: number) {
    return this.reviewRepository.list(itemId, page, limit);
  }

  async create(userId: number, body: CreateReviewBodyType) {
    return this.reviewRepository.create(userId, body);
  }

  async update(userId: number, reviewId: number, body: UpdateReviewBodyType) {
    return this.reviewRepository.update({ userId, reviewId, body });
  }
}
