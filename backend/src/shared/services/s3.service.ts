import { PutObjectCommand, S3 } from '@aws-sdk/client-s3';
import { Upload } from '@aws-sdk/lib-storage';
import { Injectable } from '@nestjs/common';
import { readFileSync } from 'fs';
import envConfig from 'src/shared/config';
import mime from 'mime-types';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';

@Injectable()
export class S3Service {
  private s3: S3;
  constructor() {
    this.s3 = new S3({
      region: envConfig.S3_REGION,
      credentials: {
        secretAccessKey: envConfig.S3_SECRET_KEY,
        accessKeyId: envConfig.S3_ACCESS_KEY,
      },
    });
  }
  uploadedFile({
    fileName,
    filePath,
    contentType,
  }: {
    fileName: string;
    filePath: string;
    contentType: string;
  }) {
    const parallelUploads3 = new Upload({
      client: this.s3,
      params: {
        Bucket: envConfig.S3_BUCKET_NAME,
        Key: fileName,
        Body: readFileSync(filePath),
        ContentType: contentType,
      },

      // optional tags
      tags: [
        /*...*/
      ],

      queueSize: 4,

      // Chia file thành các phần nhỏ để tăng tốc độ upload
      partSize: 1024 * 1024 * 5,

      leavePartsOnError: false, // Không tự động hủy bỏ các phần upload thất bại
    });

    // parallelUploads3.on('httpUploadProgress', (progress) => {
    //   console.log(progress);
    // });

    return parallelUploads3.done();
  }

  createPresignedUrlWithClient = (fileName: string) => {
    const contentType = mime.lookup(fileName) || 'application/octet-stream';
    const command = new PutObjectCommand({
      Bucket: envConfig.S3_BUCKET_NAME,
      Key: fileName,
      ContentType: contentType,
    });
    return getSignedUrl(this.s3, command, { expiresIn: 10 });
  };
}
