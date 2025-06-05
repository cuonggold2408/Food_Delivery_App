import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import {
  CreateReviewBodyType,
  UpdateReviewBodyType,
} from 'src/routes/review/review.model';
import { OrderStatus } from 'src/database/entities/order/order.entity';
import { Review } from 'src/database/entities/review/review.entity';
import { ReviewMedia } from 'src/database/entities/review/review-media.entity';
import { Order } from 'src/database/entities/order/order.entity';

@Injectable()
export class ReviewRepository {
  constructor(
    @InjectRepository(Review)
    private readonly reviewRepository: Repository<Review>,
    @InjectRepository(ReviewMedia)
    private readonly reviewMediaRepository: Repository<ReviewMedia>,
    @InjectRepository(Order)
    private readonly orderRepository: Repository<Order>,
  ) {}

  async list(itemId: string, page: number, limit: number) {
    const skip = (page - 1) * limit;
    const take = limit;

    const [data, totalItems] = await this.reviewRepository.findAndCount({
      where: {
        menuItem: { item_id: itemId },
      },
      relations: {
        user: true,
        media: true,
        order: true,
      },
      select: {
        user: {
          user_id: true,
          name: true,
        },
      },
      skip,
      take,
      order: {
        created_at: 'DESC',
      },
    });

    if (!data) {
      throw new NotFoundException('Không tìm thấy đánh giá');
    }

    const reviews = data.map((review: Review) => {
      const items =
        typeof review.order.items === 'string'
          ? JSON.parse(review.order.items)
          : review.order.items;
      const item_id = items.find((item: any) => {
        return item.dish.dish_id === itemId;
      });

      return {
        id: review.review_id,
        content: review.review_text,
        rating: review.rating,
        orderId: review.order.order_id,
        itemId: item_id,
        updateCount: review.update_count,
        createdAt: review.created_at,
        updatedAt: review.updated_at,
        user: {
          user_id: review.user.user_id,
          name: review.user.name,
        },
        medias: review.media,
      };
    });

    return {
      data: reviews,
      totalItems,
      page: page,
      limit: limit,
      totalPages: Math.ceil(totalItems / limit),
    };
  }

  private async validateOrder({
    orderId,
    userId,
  }: {
    orderId: number;
    userId: number;
  }) {
    const order = await this.orderRepository.findOne({
      where: {
        order_id: orderId,
        user: { user_id: userId },
      },
      relations: ['user'],
    });

    // Mua hàng thì mới được review
    if (!order) {
      throw new BadRequestException(
        'Đơn hàng không tồn tại hoặc không thuộc về bạn',
      );
    }

    // Đơn hàng đã giao thì mới được review
    if (order.order_status !== OrderStatus.DELIVERED) {
      throw new BadRequestException('Đơn hàng chưa được giao');
    }
    return order;
  }

  private async validateUpdateReview({
    reviewId,
    userId,
  }: {
    reviewId: number;
    userId: number;
  }) {
    const review = await this.reviewRepository.findOne({
      where: {
        review_id: reviewId,
        user: { user_id: userId },
      },
      relations: ['user'],
    });

    if (!review) {
      throw new NotFoundException(
        'Đánh giá không tồn tại hoặc không thuộc về bạn',
      );
    }

    if (review.update_count >= 2) {
      throw new BadRequestException('Bạn chỉ được phép sửa đánh giá 1 lần');
    }
    return review;
  }

  async create(userId: number, body: CreateReviewBodyType) {
    const { content, medias, itemId, orderId, rating } = body;
    await this.validateOrder({
      orderId,
      userId,
    });

    // Kiểm tra xem user đã review sản phẩm này trong đơn hàng này chưa
    const existingReview = await this.reviewRepository.findOne({
      where: {
        user: { user_id: userId },
        menuItem: { item_id: itemId.toString() },
        order: { order_id: orderId },
      },
    });

    if (existingReview) {
      throw new ConflictException('Bạn đã đánh giá sản phẩm này rồi');
    }

    return this.reviewRepository.manager.transaction(async (manager) => {
      const review = manager.create(Review, {
        review_text: content,
        rating,
        user: { user_id: userId },
        menuItem: { item_id: itemId.toString() },
        order: { order_id: orderId },
      });

      const savedReview = await manager.save(review);

      let reviewMedias: ReviewMedia[] = [];
      if (medias && medias.length > 0) {
        reviewMedias = await Promise.all(
          medias.map(async (media) => {
            const reviewMedia = manager.create(ReviewMedia, {
              url: media.url,
              type: media.type,
              review: savedReview,
            });
            return manager.save(reviewMedia);
          }),
        );
      }

      // Load lại review với relations để trả về
      const reviewWithRelations = await manager.findOne(Review, {
        where: { review_id: savedReview.review_id },
        relations: ['user', 'media'],
        select: {
          user: {
            user_id: true,
            name: true,
          },
        },
      });

      return {
        ...reviewWithRelations,
        user: {
          user_id: reviewWithRelations?.user.user_id,
          name: reviewWithRelations?.user.name,
        },
        medias: reviewMedias,
      };
    });
  }

  async update({
    userId,
    reviewId,
    body,
  }: {
    userId: number;
    reviewId: number;
    body: UpdateReviewBodyType;
  }) {
    const { content, medias, orderId, rating } = body;
    await Promise.all([
      this.validateOrder({
        orderId,
        userId,
      }),
      this.validateUpdateReview({
        reviewId,
        userId,
      }),
    ]);

    return this.reviewRepository.manager.transaction(async (manager) => {
      // Cập nhật review
      await manager.update(Review, reviewId, {
        review_text: content,
        rating,
        update_count: () => 'update_count + 1',
        updated_at: new Date(),
      });

      // Xóa media cũ
      await manager.delete(ReviewMedia, {
        review: { review_id: reviewId },
      });

      // Tạo media mới
      let reviewMedias: ReviewMedia[] = [];
      if (medias && medias.length > 0) {
        reviewMedias = await Promise.all(
          medias.map(async (media) => {
            const reviewMedia = manager.create(ReviewMedia, {
              url: media.url,
              type: media.type,
              review: { review_id: reviewId },
            });
            return manager.save(reviewMedia);
          }),
        );
      }

      // Load lại review với relations để trả về
      const reviewWithRelations = await manager.findOne(Review, {
        where: { review_id: reviewId },
        relations: ['user', 'media'],
        select: {
          user: {
            user_id: true,
            name: true,
          },
        },
      });

      return {
        ...reviewWithRelations,
        user: {
          user_id: reviewWithRelations?.user.user_id,
          name: reviewWithRelations?.user.name,
        },
        medias: reviewMedias,
      };
    });
  }
}
