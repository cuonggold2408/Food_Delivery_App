import { Module } from '@nestjs/common';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';
import { AdminRepository } from 'src/routes/admin/admin.repo';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Restaurant } from 'src/database/entities/restaurant/restaurant.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Restaurant])],
  controllers: [AdminController],
  providers: [AdminService, AdminRepository],
})
export class AdminModule {}
