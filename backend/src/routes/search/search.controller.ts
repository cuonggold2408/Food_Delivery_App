import { BadRequestException, Controller, Get, Query } from '@nestjs/common';
import { SearchService } from 'src/routes/search/search.service';
import { IsPublic } from 'src/shared/decorators/auth.decorator';

@Controller('search')
export class SearchController {
  constructor(private readonly searchService: SearchService) {}

  @Get('/')
  @IsPublic()
  @Get('/search')
  async search(
    @Query('query') query: string,
    @Query('page') page: number = 1,
    @Query('limit') limit: number = 10,
  ) {
    if (!query) throw new BadRequestException('Thiếu từ khóa tìm kiếm');
    return this.searchService.search(query, +limit, +page);
  }
}
