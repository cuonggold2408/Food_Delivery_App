import { Injectable } from '@nestjs/common';
import { SearchRepository } from 'src/routes/search/search.repo';

@Injectable()
export class SearchService {
  constructor(private readonly serviceRepository: SearchRepository) {}

  async search(
    latitude: number,
    longitude: number,
    query: string,
    limit: number,
    page: number,
    radiusInMeters: number,
    minRating?: number,
    minPrice?: number,
    maxPrice?: number,
    nearMe?: boolean,
  ) {
    const skip = (page - 1) * limit;
    return this.serviceRepository.search(
      latitude,
      longitude,
      query,
      limit,
      skip,
      radiusInMeters,
      minRating,
      minPrice,
      maxPrice,
      nearMe,
    );
  }
}
