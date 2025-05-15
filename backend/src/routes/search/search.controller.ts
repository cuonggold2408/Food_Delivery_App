import { BadRequestException, Controller, Get, Query } from '@nestjs/common';
import { ApiOperation, ApiQuery } from '@nestjs/swagger';
import { SearchService } from 'src/routes/search/search.service';
import { IsPublic } from 'src/shared/decorators/auth.decorator';

@Controller('search')
export class SearchController {
  constructor(private readonly searchService: SearchService) {}

  @Get('/')
  @IsPublic()
  @ApiOperation({ summary: 'Tìm kiếm nhà hàng, món ăn' })
  @ApiQuery({ name: 'query', required: true, description: 'Từ khóa tìm kiếm' })
  @ApiQuery({
    name: 'page',
    required: false,
    description: 'Trang',
    type: Number,
  })
  @ApiQuery({
    name: 'limit',
    required: false,
    description: 'Số lượng kết quả mỗi trang',
    type: Number,
  })
  @ApiQuery({
    name: 'minRating',
    required: false,
    description: 'Đánh giá tối thiểu (1-5)',
    type: Number,
  })
  @ApiQuery({
    name: 'latitude',
    description: 'Vĩ độ người dùng',
    type: Number,
  })
  @ApiQuery({
    name: 'longitude',
    description: 'Kinh độ người dùng',
    type: Number,
  })
  @ApiQuery({
    name: 'radius',
    required: false,
    description: 'Bán kính tìm kiếm (mét)',
    type: Number,
  })
  @ApiQuery({
    name: 'minPrice',
    required: false,
    description: 'Giá tối thiểu',
    type: Number,
  })
  @ApiQuery({
    name: 'maxPrice',
    required: false,
    description: 'Giá tối đa',
    type: Number,
  })
  @ApiQuery({
    name: 'nearMe',
    required: false,
    description: 'Tìm kiếm gần bạn',
    type: Boolean,
  })
  async search(
    @Query('latitude') latitude: number,
    @Query('longitude') longitude: number,
    @Query('query') query: string,
    @Query('page') page: number = 1,
    @Query('limit') limit: number = 10,
    @Query('minRating') minRating?: number,
    @Query('radius') radius: number = 5000,
    @Query('minPrice') minPrice?: number,
    @Query('maxPrice') maxPrice?: number,
    @Query('nearMe') nearMe?: boolean,
  ) {
    if (!query) throw new BadRequestException('Thiếu từ khóa tìm kiếm');

    if (!latitude || !longitude) {
      throw new BadRequestException('Cần cung cấp cả latitude và longitude');
    }

    if (minRating !== undefined && (minRating < 1 || minRating > 5)) {
      throw new BadRequestException('Đánh giá phải trong khoảng từ 1 đến 5');
    }

    if (minPrice !== undefined && minPrice < 0) {
      throw new BadRequestException('Giá tối thiểu không được âm');
    }

    if (maxPrice !== undefined && maxPrice < 0) {
      throw new BadRequestException('Giá tối đa không được âm');
    }

    if (
      minPrice !== undefined &&
      maxPrice !== undefined &&
      minPrice > maxPrice
    ) {
      throw new BadRequestException(
        'Giá tối thiểu không được lớn hơn giá tối đa',
      );
    }

    const radiusInMeters = radius / 111320;

    return this.searchService.search(
      latitude,
      longitude,
      query,
      +limit,
      +page,
      radiusInMeters,
      minRating,
      minPrice,
      maxPrice,
      nearMe,
    );
  }
}
