import { createZodDto } from '@anatine/zod-nestjs';
import { MessageResSchema } from 'src/shared/models/response.model';

export class MessageResDTO extends createZodDto(MessageResSchema) {}
