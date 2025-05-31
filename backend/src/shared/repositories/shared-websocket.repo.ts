import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { WebSocket } from 'src/database/entities/websocket/websocket.entity';
import { Repository } from 'typeorm';

@Injectable()
export class SharedWebSocketRepository {
  constructor(
    @InjectRepository(WebSocket)
    private readonly websocketRepository: Repository<WebSocket>,
  ) {}

  create(id: string, user_id: number) {
    const websocket = this.websocketRepository.create({
      socket_id: id,
      user_id,
    });
    return this.websocketRepository.save(websocket);
  }

  delete(id: string) {
    return this.websocketRepository.delete({ socket_id: id });
  }

  findManyByUserId(user_id: number) {
    return this.websocketRepository.find({
      where: {
        user_id,
      },
    });
  }
}
