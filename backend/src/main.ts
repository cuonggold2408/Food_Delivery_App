import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { LoggingInterceptor } from 'src/shared/interceptors/logging.interceptor';
import { TransformInterceptor } from 'src/shared/interceptors/transform.interceptor';
import { UnprocessableEntityException, ValidationPipe } from '@nestjs/common';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true, // Tự động loại bỏ các field không được định nghĩa decorator trong DTO
      forbidNonWhitelisted: true, // Tự động trả về lỗi nếu có field không được định nghĩa trong DTO, client truyền lên thì sẽ báo lỗi
      transform: true, // Tự động chuyển đổi dữ liệu sang kiểu dữ liệu trong DTO
      transformOptions: {
        enableImplicitConversion: true, // Tự động chuyển đổi kiểu dữ liệu từ string sang number, boolean, ... nếu có thể
      },
      exceptionFactory(errors) {
        const formattedErrors = errors.map((error) => {
          // Chuyển đổi tên trường thành dạng thân thiện (ví dụ: firstName -> First Name)
          const fieldName = error.property
            .replace(/([A-Z])/g, ' $1') // Thêm khoảng trắng trước các chữ cái viết hoa
            .replace(/^./, (str) => str.toUpperCase()); // Viết hoa chữ cái đầu

          if (
            error.value === undefined ||
            error.value === null ||
            error.value === ''
          ) {
            return {
              field: error.property,
              errors: [`${fieldName} không được để trống`],
            };
          }

          return {
            field: error.property,
            errors: Object.values(error.constraints || {}),
          };
        });
        return new UnprocessableEntityException(formattedErrors);
      },
    }),
  );

  app.useGlobalInterceptors(new LoggingInterceptor());
  app.useGlobalInterceptors(new TransformInterceptor());
  await app.listen(3000);
}
bootstrap();
