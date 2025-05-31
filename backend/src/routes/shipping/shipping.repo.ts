import { Injectable } from '@nestjs/common';
import { InjectEntityManager } from '@nestjs/typeorm';
import { EntityManager } from 'typeorm';

@Injectable()
export class ShippingRepository {
  constructor(
    @InjectEntityManager()
    private readonly entityManager: EntityManager,
  ) {}
  async getShippingFee(body: {
    origin: { latitude: number; longitude: number };
    destination: { latitude: number; longitude: number };
  }) {
    const { origin, destination } = body;

    // Sử dụng PostGIS để tính khoảng cách giữa 2 điểm (đơn vị: mét)
    const query = `
      SELECT ST_Distance(
        ST_SetSRID(ST_MakePoint($1, $2), 4326),
        ST_SetSRID(ST_MakePoint($3, $4), 4326),
        true
      ) AS distance
    `;

    const result = await this.entityManager.query(query, [
      origin.longitude,
      origin.latitude,
      destination.longitude,
      destination.latitude,
    ]);

    const distanceInMeters = result[0].distance;
    const distanceInKm = distanceInMeters / 1000;

    // Tính phí giao hàng dựa trên khoảng cách
    // Ví dụ: 15.000đ cho 2km đầu tiên, sau đó 5.000đ cho mỗi km tiếp theo
    const baseFee = 15000; // Phí cơ bản cho 2km đầu
    const additionalFeePerKm = 5000; // Phí cho mỗi km tiếp theo
    const baseDistance = 2; // Khoảng cách cơ bản (km)

    let shippingFee = baseFee;
    if (distanceInKm > baseDistance) {
      shippingFee +=
        Math.ceil(distanceInKm - baseDistance) * additionalFeePerKm;
    }

    return {
      distance: Math.round(distanceInKm * 10) / 10, // Làm tròn đến 1 chữ số thập phân
      fee: shippingFee,
      unit: 'VND',
    };
  }
}
