import { createZodDto } from 'nestjs-zod';
import { UserAddressBodySchema } from 'src/routes/user/user.model';
import { UserProfileSchema } from 'src/shared/models/shared-user.model';

export class UserAddressBodyDTO extends createZodDto(UserAddressBodySchema) {}

export class UserProfileBodyDTO extends createZodDto(UserProfileSchema) {}
export class UserProfileResDTO extends createZodDto(UserProfileSchema) {}
