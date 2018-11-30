//
//  NSImage+Processor.m
//  SimilarImageHunter
//
//  Created by 杨萧玉 on 16/1/12.
//  Copyright © 2016年 杨萧玉. All rights reserved.
//

#import "NSImage+Processor.h"

#define Mask8(x) ( (x) & 0xFF )
#define A(x) ( Mask8(x) )
#define B(x) ( Mask8(x >> 8 ) )
#define G(x) ( Mask8(x >> 16) )
#define R(x) ( Mask8(x >> 24) )
#define RGBAMake(r, g, b, a) ( Mask8(a) | Mask8(b) << 8 | Mask8(g) << 16 | Mask8(r) << 24 )

@implementation NSImage (Processor)

- (NSDictionary *)abstractVector {
    // 1. Get pixels of image
    NSData *imageData = self.TIFFRepresentation;
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, NULL);
    CGImageRef inputCGImage =  CGImageSourceCreateImageAtIndex(source, 0, NULL);
    NSUInteger width = CGImageGetWidth(inputCGImage);
    NSUInteger height = CGImageGetHeight(inputCGImage);
    
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    
    UInt32 * pixels;
    pixels = (UInt32 *) calloc(height * width, sizeof(UInt32));
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pixels, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast|kCGBitmapByteOrder32Big);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), inputCGImage);
    
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    
    // 2. Iterate and calculate!
    NSMutableDictionary<NSNumber *,NSNumber *> *pixelBucket = [NSMutableDictionary dictionary];
    UInt32 *currentPixel = pixels;
    for (NSUInteger j = 0; j < height; j++) {
        for (NSUInteger i = 0; i < width; i++) {
            UInt32 color = *currentPixel;
            NSUInteger fingerprint = RGBAMake([self downsampleComponent:R(color)],
                                              [self downsampleComponent:G(color)],
                                              [self downsampleComponent:B(color)],
                                              [self downsampleX:i y:j w:width h:height]);
            pixelBucket[@(fingerprint)] = @(pixelBucket[@(fingerprint)].intValue + 1);
            currentPixel++;
        }
    }
    
    free(pixels);
    
    [pixelBucket enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
        pixelBucket[key] = @(obj.doubleValue/(height * width));
    }];
    
    NSDictionary *bucket = @{KEY_ASPECT_RATIO:@((float)width/height),KEY_PIXELVECTOR:[pixelBucket copy]};
    return bucket;
}

- (UInt32)downsampleComponent:(UInt8)component
{
    return (UInt32)component / 32;
}

- (UInt32)downsampleX:(NSInteger)x y:(NSInteger)y w:(NSInteger)width h:(NSInteger)height
{
    NSInteger rowCount = MIN(4, height);
    NSInteger countPerRow = MIN(4, width);
    NSInteger hStep = width / countPerRow;
    NSInteger vStep = height / rowCount;
    NSInteger row = y / vStep;
    NSInteger col = x / hStep;
    return (UInt32)(row * countPerRow + col);
}

@end
