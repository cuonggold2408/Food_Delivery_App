import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConfigModule, ConfigService } from '@nestjs/config';

@Module({
  imports: [
    ConfigModule.forRoot(),
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: (configService: ConfigService) => {
        const isProduction = process.env.NODE_ENV === 'production';

        return {
          type: 'postgres',
          host: process.env.POSTGRES_HOST || configService.get('POSTGRES_HOST'),
          port: parseInt(
            process.env.POSTGRES_PORT ||
              configService.get('POSTGRES_PORT') ||
              '5432',
            10,
          ),
          username:
            process.env.POSTGRES_USER || configService.get('POSTGRES_USER'),
          password:
            process.env.POSTGRES_PASSWORD ||
            configService.get('POSTGRES_PASSWORD'),
          database: process.env.POSTGRES_DB || configService.get('POSTGRES_DB'),
          entities: [__dirname + '/../**/*.entity{.ts,.js}'],
          synchronize: !isProduction, // Be cautious about using synchronize in production
          logging: !isProduction,
          ssl: isProduction
            ? {
                rejectUnauthorized: false,
              }
            : false,
        };
      },
      inject: [ConfigService],
    }),
  ],
})
export class DatabaseModule {}
