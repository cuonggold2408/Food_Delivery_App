import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { UserAddress } from 'src/database/entities/user-address.entity';
import { User } from 'src/database/entities/user.entity';
import { UserAddressBodyType } from 'src/routes/user/user.model';
import { Repository } from 'typeorm';

@Injectable()
export class UserAddressRepository {
  constructor(
    @InjectRepository(UserAddress)
    private readonly userAddressRepository: Repository<UserAddress>,

    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
  ) {}

  // Kiểm tra xem user có tồn tại không
  async checkUserExists(user_id: UserAddressBodyType['user_id']) {
    const user = await this.userRepository.findOne({
      where: { user_id },
    });
    return !!user; // Trả về true nếu tồn tại, false nếu không
  }

  // Tạo address
  async createAddress(data: UserAddressBodyType) {
    const newAddress = this.userAddressRepository.create({
      ...data,
      user: { user_id: data.user_id },
    });
    await this.userAddressRepository.save(newAddress);

    return newAddress; // trả về entity vừa lưu
  }

  // Cập nhật toàn bộ address của user thành is_default = false
  async unsetDefaultAddresses(user_id: UserAddressBodyType['user_id']) {
    await this.userAddressRepository.update(
      { user: { user_id }, is_default: true }, // điều kiện
      { is_default: false },
    );
  }

  // Tuỳ chọn: Lấy danh sách địa chỉ user (nếu cần check)
  async findUserAddresses(user_id: UserAddressBodyType['user_id']) {
    return this.userAddressRepository.find({
      where: { user: { user_id } },
      order: { created_at: 'DESC' },
    });
  }
}
