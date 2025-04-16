import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { UserProfileBodyDTO } from 'src/routes/user/user.dto';

import { UserAddressBodyType } from 'src/routes/user/user.model';
import { UserAddressRepository } from 'src/routes/user/user.repo';

@Injectable()
export class UserService {
  constructor(private readonly userAddressRepository: UserAddressRepository) {}

  async saveAddress(body: UserAddressBodyType, user_id: number) {
    const {
      address_name,
      phone_number,
      recipient_name,
      street_address,
      postal_code,
      is_default,
      apartment,
      latitude,
      longitude,
    } = body;

    // Kiểm tra xem user có tồn tại không
    const user = await this.userAddressRepository.checkUserExists(user_id);
    if (!user) throw new NotFoundException('Người dùng không tồn tại');

    const addresses =
      await this.userAddressRepository.findUserAddresses(user_id);
    if (addresses.length >= 3) {
      throw new BadRequestException(
        'Bạn đã có tối đa 3 địa chỉ, không thể thêm',
      );
    }

    // Nếu user đánh dấu địa chỉ này là mặc định, hãy bỏ cờ mặc định của các địa chỉ cũ.
    if (is_default) {
      await this.userAddressRepository.unsetDefaultAddresses(user_id);
    }

    // Tạo địa chỉ mới
    const newAddress = await this.userAddressRepository.createAddress(
      {
        address_name,
        phone_number,
        recipient_name,
        street_address,
        postal_code,
        is_default,
        apartment,
        latitude,
        longitude,
      },
      user_id,
    );

    return {
      message: 'Lưu địa chỉ thành công',
      data: {
        ...newAddress,
        user: undefined,
        user_id: newAddress.user.user_id,
      },
    };
  }

  // Lấy tất cả địa chỉ của 1 user
  async getAllAddress(userId: number) {
    // Kiểm tra xem user có tồn tại không
    const user = await this.userAddressRepository.checkUserExists(userId);
    if (!user) throw new NotFoundException('Người dùng không tồn tại');

    const addresses =
      await this.userAddressRepository.findUserAddresses(userId);
    return addresses;
  }

  async updateAddress(
    addressId: number,
    userId: number,
    body: UserAddressBodyType,
  ) {
    // Kiểm tra xem user có tồn tại không
    const user = await this.userAddressRepository.checkUserExists(userId);
    if (!user) throw new NotFoundException('Người dùng không tồn tại');

    if (!body.latitude || !body.longitude) {
      throw new BadRequestException('Cần có latitude và longitude');
    }

    return await this.userAddressRepository.updateAddressForUser(
      addressId,
      userId,
      body,
    );
  }

  async deleteAddress(addressId: number, userId: number) {
    // Kiểm tra xem user có tồn tại không
    const user = await this.userAddressRepository.checkUserExists(userId);
    if (!user) throw new NotFoundException('Người dùng không tồn tại');

    return await this.userAddressRepository.deleteAddressForUser(
      addressId,
      userId,
    );
  }

  async getUserProfile(userId: number) {
    return await this.userAddressRepository.getUserProfile(userId);
  }

  async updateUserProfile(userId: number, body: UserProfileBodyDTO) {
    return await this.userAddressRepository.updateUserProfile(userId, body);
  }
}
