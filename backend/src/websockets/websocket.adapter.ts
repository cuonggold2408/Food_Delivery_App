import { INestApplicationContext } from '@nestjs/common';
import { IoAdapter } from '@nestjs/platform-socket.io';
import { createAdapter } from '@socket.io/redis-adapter';
import { createClient } from 'redis';
import { Server, ServerOptions, Socket } from 'socket.io';
import envConfig from 'src/shared/config';
import { generateRoomUserId } from 'src/shared/helpers';
import { SharedWebSocketRepository } from 'src/shared/repositories/shared-websocket.repo';
import { TokenService } from 'src/shared/services/token.service';

const namespaces = ['/', 'payment', 'chat'];

export class WebSocketAdapter extends IoAdapter {
  private readonly sharedWebSocketRepository: SharedWebSocketRepository;
  private readonly tokenService: TokenService;
  private adapterConstructor: ReturnType<typeof createAdapter>;
  constructor(app: INestApplicationContext) {
    super(app);
    this.sharedWebSocketRepository = app.get(SharedWebSocketRepository);
    this.tokenService = app.get(TokenService);
  }
  async connectToRedis(): Promise<void> {
    const pubClient = createClient({
      url: envConfig.REDIS_URL,
    });
    const subClient = pubClient.duplicate();

    await Promise.all([pubClient.connect(), subClient.connect()]);

    this.adapterConstructor = createAdapter(pubClient, subClient);
  }

  createIOServer(port: number, options?: ServerOptions) {
    const server: Server = super.createIOServer(port, options);

    namespaces.forEach((namespace) => {
      server.of(namespace).use(this.authMiddleware);
    });
    return server;
  }
  authMiddleware = async (socket: Socket, next: (err?: any) => void) => {
    const { authorization } = socket.handshake.headers;
    if (!authorization) {
      return next(new Error('Thiếu authorization header'));
    }
    const accessToken = authorization.split(' ')[1];
    if (!accessToken) {
      return next(new Error('Thiếu access token'));
    }
    try {
      const { user_id } =
        await this.tokenService.verifyAccessToken(accessToken);

      await socket.join(generateRoomUserId(user_id));

      // await this.sharedWebSocketRepository.create(socket.id, user_id);
      // socket.on('disconnect', () => {
      //   this.sharedWebSocketRepository.delete(socket.id);
      // });

      next();
    } catch (error) {
      console.log('error: ', error);
      return next(new Error('Token không hợp lệ'));
    }
  };
}
