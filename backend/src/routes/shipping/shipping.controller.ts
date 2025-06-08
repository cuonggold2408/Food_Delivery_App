import { Body, Controller, Post } from '@nestjs/common';
import { ApiBody, ApiOperation, ApiProperty } from '@nestjs/swagger';
import { ShippingService } from 'src/routes/shipping/shipping.service';
import { IsPublic } from 'src/shared/decorators/auth.decorator';
import { Type } from 'class-transformer';
import { IsNumber, ValidateNested } from 'class-validator';

class LocationDto {
  @ApiProperty({ description: 'Vĩ độ' })
  @IsNumber()
  latitude: number;

  @ApiProperty({ description: 'Kinh độ' })
  @IsNumber()
  longitude: number;
}

class ShippingFeeDto {
  @ApiProperty({ description: 'Vị trí xuất phát' })
  @ValidateNested()
  @Type(() => LocationDto)
  origin: LocationDto;

  @ApiProperty({ description: 'Vị trí đích' })
  @ValidateNested()
  @Type(() => LocationDto)
  destination: LocationDto;
}

@Controller('shipping')
export class ShippingController {
  constructor(private readonly shippingService: ShippingService) {}

  @Post('/fee')
  @ApiOperation({ summary: 'Lấy phí vận chuyển' })
  @ApiBody({ type: ShippingFeeDto })
  @IsPublic()
  getShippingFee(@Body() body: ShippingFeeDto) {
    return this.shippingService.getShippingFee(body);
  }
}
