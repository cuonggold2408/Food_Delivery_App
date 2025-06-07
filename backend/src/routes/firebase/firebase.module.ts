import { Module } from '@nestjs/common';
import { FirebaseController } from './firebase.controller';
import { FirebaseService } from './firebase.service';
import * as admin from 'firebase-admin';
import envConfig from 'src/shared/config';
import { FirebaseRepository } from 'src/routes/firebase/firebase.repo';
import { UserDevice } from 'src/database/entities/user-device.entity';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Order } from 'src/database/entities/order/order.entity';
@Module({
  imports: [TypeOrmModule.forFeature([UserDevice, Order])],
  providers: [
    {
      provide: 'FIREBASE_ADMIN',
      useFactory: () => {
        // 1. Lấy biến môi trường (string JSON)
        const serviceAccountJson = envConfig.FIREBASE_SERVICE_ACCOUNT_KEY;
        if (!serviceAccountJson) {
          throw new Error(
            'Missing FIREBASE_SERVICE_ACCOUNT_KEY in environment variables',
          );
        }

        // 2. Parse chuỗi JSON thành object
        let serviceAccount: admin.ServiceAccount;
        try {
          serviceAccount = JSON.parse(serviceAccountJson);
        } catch (err) {
          console.log('err: ', err);
          throw new Error('Invalid JSON in FIREBASE_SERVICE_ACCOUNT_KEY');
        }

        // 3. Khởi tạo Firebase App
        admin.initializeApp({
          credential: admin.credential.cert(serviceAccount),
        });

        return admin;
      },
    },
    FirebaseService,
    FirebaseRepository,
  ],
  exports: ['FIREBASE_ADMIN', FirebaseService, FirebaseRepository],
  controllers: [FirebaseController],
})
export class FirebaseModule {}
