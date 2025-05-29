import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ResponseInterceptor } from 'src/shared/interceptors/response.interceptor';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { WebSocketAdapter } from 'src/websockets/websocket.adapter';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  app.enableCors({
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    credentials: true,
  });

  app.useGlobalInterceptors(new ResponseInterceptor());

  // config swagger
  const config = new DocumentBuilder()
    .setTitle('Food_Delivery_APP')
    .setDescription('This is API documentation for Food Delivery App')
    .setVersion('1.0')
    .addBearerAuth()
    .build();
  const documentFactory = () => SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api', app, documentFactory, {
    swaggerOptions: {
      persistAuthorization: true,
    },
  });

  const webSocketAdapter = new WebSocketAdapter(app);
  // await webSocketAdapter.connectToRedis();

  app.useWebSocketAdapter(webSocketAdapter);

  await app.listen(3000);
}
bootstrap();
