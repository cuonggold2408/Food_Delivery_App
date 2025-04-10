import { createZodDto } from 'nestjs-zod';
import { UserAddressBodySchema } from 'src/routes/user/user.model';

export class UserAddressBodyDTO extends createZodDto(UserAddressBodySchema) {}
