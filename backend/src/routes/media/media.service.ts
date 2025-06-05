import { Injectable } from '@nestjs/common';
import { unlink } from 'fs/promises';
import { generateRandomFileName } from 'src/shared/helpers';
import { S3Service } from 'src/shared/services/s3.service';

@Injectable()
export class MediaService {
  constructor(private readonly s3Service: S3Service) {}

  async uploadFile(files: Array<Express.Multer.File>) {
    const result = await Promise.all(
      files.map((file) => {
        return this.s3Service
          .uploadedFile({
            fileName: 'images/' + file.filename,
            filePath: file.path,
            contentType: file.mimetype,
          })
          .then((res) => {
            return {
              url: res.Location,
            };
          });
      }),
    );

    // Xóa file sau khi upload lên S3
    await Promise.all(
      files.map((file) => {
        return unlink(file.path);
      }),
    );
    return {
      data: result,
    };
  }

  async createPresignedUrl(body: { fileName: string }) {
    console.log(body);

    const randomFileName = generateRandomFileName(body.fileName);
    const presignedUrl =
      await this.s3Service.createPresignedUrlWithClient(randomFileName);

    const url = presignedUrl.split('?')[0];
    return {
      presignedUrl: presignedUrl,
      url: url,
    };
  }
}
