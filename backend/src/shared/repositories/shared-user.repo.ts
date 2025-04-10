import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { User } from 'src/database/entities/user.entity';
import { UserRole, UserType } from 'src/shared/models/shared-user.model';
import { Repository } from 'typeorm';

@Injectable()
export class SharedUserRepository {
  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
  ) {}

  async findUnique(
    uniqueObject: { email: string } | { user_id: number },
  ): Promise<UserType | null> {
    const user = await this.userRepository.findOne({
      where: uniqueObject,
    });

    if (!user) {
      return null;
    }
    return {
      ...user,
      user_role: user.user_role as UserRole,
    };
  }
}
