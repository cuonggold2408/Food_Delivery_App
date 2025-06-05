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
import { ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
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
  @ApiOperation({ summary: 'Lấy danh sách đánh giá của sản phẩm' })
  @IsPublic()
  async list(
    @Query('page') page: number = 1,
    @Query('limit') limit: number = 10,
    @Param('itemId') itemId: string,
  ) {
    return this.reviewService.list(itemId, page, limit);
  }

  @Post()
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Tạo đánh giá cho sản phẩm' })
  async create(@Body() body: CreateReviewBodyDTO, @Req() req: any) {
    const userId = req.user.user_id;
    return this.reviewService.create(userId, body);
  }

  @Put(':reviewId')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Cập nhật đánh giá cho sản phẩm' })
  async update(
    @Body() body: UpdateReviewBodyDTO,
    @Req() req: any,
    @Param('reviewId') reviewId: number,
  ) {
    const userId = req.user.user_id;
    return this.reviewService.update(userId, reviewId, body);
  }
}
