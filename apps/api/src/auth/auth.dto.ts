import { ApiProperty } from '@nestjs/swagger';
import { IsEmail, IsNotEmpty, IsString, Matches, MaxLength, MinLength } from 'class-validator';
import { Transform } from 'class-transformer';
export class EmailDto {
  @ApiProperty({format:'email',maxLength:254})
  @Transform(({value}: {value: unknown}) => typeof value === 'string' ? value.trim() : value)
  @IsEmail() @MaxLength(254) email!: string;
}
export class LoginDto extends EmailDto {
  @ApiProperty({minLength:1,maxLength:128,writeOnly:true})
  @IsString() @MinLength(1) @MaxLength(128) password!: string;
}
export class RegisterDto extends EmailDto {
  @ApiProperty({minLength:8,maxLength:128,writeOnly:true})
  @IsString() @MinLength(8) @MaxLength(128) @Matches(/\S/) password!: string;
}
export class RefreshDto {
  @ApiProperty({maxLength:8192,writeOnly:true}) @IsString() @IsNotEmpty() @MaxLength(8192) refreshToken!: string;
}
export class AuthSessionDto {
  @ApiProperty({readOnly:true}) idToken!: string;
  @ApiProperty({readOnly:true}) refreshToken!: string;
  @ApiProperty({minimum:1,maximum:86400}) expiresInSeconds!: number;
}
export class ResetAcceptedDto { @ApiProperty({example:true}) accepted!: boolean; }
