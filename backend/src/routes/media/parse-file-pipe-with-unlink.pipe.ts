import {
  BadRequestException,
  ParseFileOptions,
  ParseFilePipe,
} from '@nestjs/common';
import { unlink } from 'fs/promises';

export class ParseFilePipeWithUnlink extends ParseFilePipe {
  constructor(options: ParseFileOptions) {
    super(options);
  }

  async transform(files: Array<Express.Multer.File>): Promise<any> {
    const result = await super.transform(files).catch(async (err) => {
      await Promise.all(
        files.map((file) => {
          return unlink(file.path);
        }),
      );
      throw new BadRequestException(err);
    });
    return result;
  }
}
