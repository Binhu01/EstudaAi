import { ApiProperty } from '@nestjs/swagger';
import { Type, Transform } from 'class-transformer';
import { ArrayMaxSize, IsArray, IsIn, IsString, Matches, MaxLength, MinLength, Validate, ValidateNested, ValidatorConstraint, ValidatorConstraintInterface } from 'class-validator';
const trim = ({value}:{value:unknown}) => typeof value==='string' ? value.trim() : value;
export class ChatMessageDto {
  @ApiProperty({enum:['user','assistant']}) @IsIn(['user','assistant']) role!:'user'|'assistant';
  @ApiProperty({maxLength:2000,minLength:1}) @Transform(trim) @IsString() @MinLength(1) @MaxLength(2000) text!:string;
}
@ValidatorConstraint()
class HistorySize implements ValidatorConstraintInterface {
  validate(value:unknown) {return Array.isArray(value) && value.every(m=>m && typeof m.text==='string') && value.reduce((sum,m)=>sum+m.text.length,0)<=12000;}
}
export class SteveInputDto {
  @ApiProperty({pattern:'^[a-z0-9-]+$',maxLength:80}) @IsString() @MaxLength(80) @Matches(/^[a-z0-9-]+$/) topicId!:string;
  @ApiProperty({minLength:1,maxLength:2000}) @Transform(trim) @IsString() @MinLength(1) @MaxLength(2000) message!:string;
  @ApiProperty({type:[ChatMessageDto],maxItems:8,description:'Até 12.000 caracteres no total.'})
  @IsArray() @ArrayMaxSize(8) @ValidateNested({each:true}) @Type(()=>ChatMessageDto) @Validate(HistorySize) history!:ChatMessageDto[];
}
class SourceDto {
  @ApiProperty() title!:string;
  @ApiProperty({format:'uri'}) url!:string;
}
class QuotaDto {
  @ApiProperty({minimum:0}) remaining!:number;
  @ApiProperty({format:'date-time'}) resetAt!:string;
}
export class SteveReplyDto {
  @ApiProperty() topicId!:string;
  @ApiProperty({enum:['completed','refused','incomplete']}) status!:string;
  @ApiProperty({maxLength:16000}) text!:string;
  @ApiProperty({type:[SourceDto]}) sources!:SourceDto[];
  @ApiProperty({type:QuotaDto}) quota!:QuotaDto;
  @ApiProperty({format:'uuid'}) requestId!:string;
}
