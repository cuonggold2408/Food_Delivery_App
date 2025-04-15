import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ResponseInterceptor } from 'src/shared/interceptors/response.interceptor';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  app.useGlobalInterceptors(new ResponseInterceptor());
  await app.listen(3000);
}
bootstrap();
