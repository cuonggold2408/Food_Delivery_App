import { Injectable } from '@nestjs/common';
import { SearchRepository } from 'src/routes/search/search.repo';

@Injectable()
export class SearchService {
  constructor(private readonly serviceRepository: SearchRepository) {}

  async search(query: string, limit: number, page: number) {
    const skip = (page - 1) * limit;
    return this.serviceRepository.search(query, limit, skip);
  }
}
