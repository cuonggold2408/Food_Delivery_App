import { INestApplicationContext } from '@nestjs/common';
import { IoAdapter } from '@nestjs/platform-socket.io';
import { createAdapter } from '@socket.io/redis-adapter';
import { createClient } from 'redis';
import { Server, ServerOptions, Socket } from 'socket.io';
import envConfig from 'src/shared/config';
import { generateRoomUserId } from 'src/shared/helpers';
import { SharedWebSocketRepository } from 'src/shared/repositories/shared-websocket.repo';
import { TokenService } from 'src/shared/services/token.service';

const namespaces = ['/', 'payment', 'chat', 'chat-realtime']; // Thêm chat-realtime

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

  // createIOServer(port: number, options?: ServerOptions) {
  //   const server: Server = super.createIOServer(port, options);

  //   namespaces.forEach((namespace) => {
  //     server.of(namespace).use(this.authMiddleware);
  //   });

  //   server.adapter(this.adapterConstructor);
  //   return server;
  // }

  createIOServer(port: number, options?: ServerOptions) {
    const server: Server = super.createIOServer(port, {
      ...options,
      transports: ['websocket'], // Force websocket only, disable polling
      pingTimeout: 60000,
      pingInterval: 25000,
    });

    namespaces.forEach((namespace) => {
      server.of(namespace).use(this.authMiddleware);
    });

    if (this.adapterConstructor) {
      server.adapter(this.adapterConstructor);
    }

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
      const { user_id, user_role } =
        await this.tokenService.verifyAccessToken(accessToken);

      // Lưu thông tin user vào socket
      (socket as any).userId = user_id;
      (socket as any).userRole = user_role;

      // Join user vào room cá nhân
      await socket.join(generateRoomUserId(user_id));

      console.log(
        `User ${user_id} (${user_role}) connected to ${socket.nsp.name}`,
      );

      next();
    } catch (error) {
      console.log('WebSocket auth error: ', error);
      return next(new Error('Token không hợp lệ'));
    }
  };
}
