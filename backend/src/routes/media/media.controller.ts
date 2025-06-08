import {
  Body,
  Controller,
  MaxFileSizeValidator,
  Post,
  UploadedFiles,
  UseInterceptors,
} from '@nestjs/common';
import { FilesInterceptor } from '@nestjs/platform-express';
import { MediaService } from 'src/routes/media/media.service';
import { ParseFilePipeWithUnlink } from 'src/routes/media/parse-file-pipe-with-unlink.pipe';

@Controller('media')
export class MediaController {
  constructor(private readonly mediaService: MediaService) {}
  @Post('images/upload')
  @UseInterceptors(
    FilesInterceptor('files', 3, {
      limits: {
        fileSize: 2 * 1024 * 1024, // 2MB
      },
    }),
  )
  async uploadFile(
    @UploadedFiles(
      new ParseFilePipeWithUnlink({
        validators: [
          new MaxFileSizeValidator({ maxSize: 2 * 1024 * 1024 }), // 2MB
        ],
      }),
    )
    files: Array<Express.Multer.File>,
  ) {
    return this.mediaService.uploadFile(files);
  }

  @Post('images/upload/presigned-url')
  async createPresignedUrl(@Body() body: { fileName: string }) {
    return this.mediaService.createPresignedUrl(body);
  }
}
