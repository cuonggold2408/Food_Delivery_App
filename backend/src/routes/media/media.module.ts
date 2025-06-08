import { Module } from '@nestjs/common';
import { MediaController } from './media.controller';
import { MediaService } from './media.service';
import { MulterModule } from '@nestjs/platform-express';
import multer from 'multer';
import path from 'path';
import { generateRandomFileName } from 'src/shared/helpers';
import { existsSync, mkdirSync } from 'fs';

const UPLOAD_DIR = path.resolve('upload');

const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, UPLOAD_DIR);
  },
  filename: function (req, file, cb) {
    const newFileName = generateRandomFileName(file.originalname);
    cb(null, newFileName);
  },
});

@Module({
  imports: [
    MulterModule.register({
      storage,
    }),
  ],
  controllers: [MediaController],
  providers: [MediaService],
})
export class MediaModule {
  constructor() {
    if (!existsSync(UPLOAD_DIR)) {
      mkdirSync(UPLOAD_DIR, { recursive: true });
    }
  }
}
