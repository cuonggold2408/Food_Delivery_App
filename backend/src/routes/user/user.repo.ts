import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { UserAddress } from 'src/database/entities/user-address.entity';
import { User } from 'src/database/entities/user.entity';
import {
  UserProfileBodyDTO,
  UserProfileResDTO,
} from 'src/routes/user/user.dto';
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

  /*
    UserAddress
    - Tạo địa chỉ
    - Cập nhật địa chỉ
    - Xoá địa chỉ
    - Lấy danh sách địa chỉ của user

  */

  // Kiểm tra xem user có tồn tại không
  async checkUserExists(user_id: number) {
    const user = await this.userRepository.findOne({
      where: { user_id },
    });
    return !!user; // Trả về true nếu tồn tại, false nếu không
  }

  // Tạo address
  async createAddress(data: UserAddressBodyType, user_id: number) {
    const newAddress = this.userAddressRepository.create({
      ...data,
      user: { user_id },
    });
    await this.userAddressRepository.save(newAddress);

    return newAddress; // trả về entity vừa lưu
  }

  // Cập nhật toàn bộ address của user thành is_default = false
  async unsetDefaultAddresses(user_id: number) {
    await this.userAddressRepository.update(
      { user: { user_id }, is_default: true }, // điều kiện
      { is_default: false },
    );
  }

  // Cập nhật địa chỉ làm mặc định
  async updateDefaultAddress(addressId: number, userId: number) {
    // Cập nhật tất cả địa chỉ của user thành is_default = false
    await this.unsetDefaultAddresses(userId);
    await this.userAddressRepository.update(
      { address_id: addressId, user: { user_id: userId } },
      { is_default: true },
    );
    return {
      message: 'Cập nhật địa chỉ làm mặc định thành công',
    };
  }

  // Tuỳ chọn: Lấy danh sách địa chỉ user (nếu cần check)
  async findUserAddresses(user_id: number) {
    return this.userAddressRepository.find({
      where: { user: { user_id } },
      order: { created_at: 'DESC' },
    });
  }

  // Cập nhật địa chỉ
  async updateAddressForUser(
    addressId: number,
    userId: number,
    body: Omit<UserAddressBodyType, 'user_id'>,
  ) {
    // Kiểm tra xem địa chỉ có tồn tại không
    const address = await this.userAddressRepository.findOne({
      where: { address_id: addressId, user: { user_id: userId } },
    });
    if (!address) throw new NotFoundException('Địa chỉ không tồn tại');

    // Cập nhật địa chỉ
    await this.userAddressRepository.update(
      { address_id: addressId, user: { user_id: userId } },
      { ...body },
    );
    return {
      message: 'Cập nhật địa chỉ thành công',
      data: body,
    };
  }

  // Xoá địa chỉ
  async deleteAddressForUser(addressId: number, userId: number) {
    // Kiểm tra xem địa chỉ có tồn tại không
    const address = await this.userAddressRepository.findOne({
      where: { address_id: addressId, user: { user_id: userId } },
    });
    if (!address) throw new NotFoundException('Địa chỉ không tồn tại');

    // Xoá địa chỉ
    await this.userAddressRepository.delete({
      address_id: addressId,
      user: { user_id: userId },
    });
    return {
      message: 'Xoá địa chỉ thành công',
    };
  }

  /*
    UserProfile
    - Lấy thông tin user
    - Cập nhật thông tin user
  */

  async getUserProfile(userId: number): Promise<UserProfileResDTO> {
    const user = await this.userRepository.findOne({
      where: { user_id: userId },
    });
    if (!user) throw new NotFoundException('Người dùng không tồn tại');

    return {
      name: user.name,
      email: user.email,
      phone_number: user.phone_number,
      bio: user.bio,
    };
  }

  async updateUserProfile(userId: number, body: UserProfileBodyDTO) {
    const user = await this.userRepository.findOne({
      where: { user_id: userId },
    });

    if (!user) throw new NotFoundException('Người dùng không tồn tại');

    if (user.email !== body.email) {
      throw new BadRequestException('Không thể cập nhật email');
    }

    await this.userRepository.update(userId, body);

    return {
      message: 'Cập nhật thông tin thành công',
    };
  }
}
