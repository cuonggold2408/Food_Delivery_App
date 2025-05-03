import { Module } from '@nestjs/common';
import { SearchController } from './search.controller';
import { SearchService } from './search.service';
import { TypeOrmModule } from '@nestjs/typeorm';
import { MenuItem } from 'src/database/entities/menu-item.entity';
import { SearchRepository } from 'src/routes/search/search.repo';
import { Restaurant } from 'src/database/entities/restaurant/restaurant.entity';

@Module({
  imports: [TypeOrmModule.forFeature([MenuItem, Restaurant])],
  controllers: [SearchController],
  providers: [SearchService, SearchRepository],
})
export class SearchModule {}
