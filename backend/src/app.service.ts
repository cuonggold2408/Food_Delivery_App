import { Injectable } from '@nestjs/common';

@Injectable()
export class AppService {
  getHello(): string {
    return 'Hello World! Cuong Nguyen cute phô mai que nhất UET';
  }
}
