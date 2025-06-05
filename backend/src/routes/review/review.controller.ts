import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  Put,
  Query,
  Req,
} from '@nestjs/common';
import {
  CreateReviewBodyDTO,
  UpdateReviewBodyDTO,
} from 'src/routes/review/review.dto';
import { ReviewService } from 'src/routes/review/review.service';
import { IsPublic } from 'src/shared/decorators/auth.decorator';

@Controller('reviews')
export class ReviewController {
  constructor(private readonly reviewService: ReviewService) {}

  @Get('/products/:itemId')
  @IsPublic()
  async list(
    @Query('page') page: number = 1,
    @Query('limit') limit: number = 10,
    @Param('itemId') itemId: string,
  ) {
    return this.reviewService.list(itemId, page, limit);
  }

  @Post()
  async create(@Body() body: CreateReviewBodyDTO, @Req() req: any) {
    const userId = req.user.user_id;
    return this.reviewService.create(userId, body);
  }

  @Put(':reviewId')
  async update(
    @Body() body: UpdateReviewBodyDTO,
    @Req() req: any,
    @Param('reviewId') reviewId: number,
  ) {
    const userId = req.user.user_id;
    return this.reviewService.update(userId, reviewId, body);
  }
}
