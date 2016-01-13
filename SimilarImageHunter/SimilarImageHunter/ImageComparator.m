//
//  ImageComparator.m
//  SimilarImageHunter
//
//  Created by 杨萧玉 on 16/1/13.
//  Copyright © 2016年 杨萧玉. All rights reserved.
//

#import "ImageComparator.h"
#import "NSImage+Processor.h"

@interface ImageComparator ()
@property (nonatomic,nonnull) NSMutableDictionary<NSString *,NSDictionary *> *vectorCache;
@property (nonatomic,nonnull) NSTask *imagePathsCollector;
@end
@implementation ImageComparator

- (instancetype)init
{
    self = [super init];
    if (self) {
        _vectorCache = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSArray<NSString *> *)collectImagePathsInRootPath:(NSString *)rootPath
{
    _imagePathsCollector = [[NSTask alloc] init];
    _imagePathsCollector.launchPath = @"/bin/bash";
    NSString *shellPath = [NSString stringWithFormat:@"%@%@",[NSBundle mainBundle].resourcePath,@"/cacheimages"];
    _imagePathsCollector.arguments = @[shellPath,rootPath];
    NSPipe *pipe;
    pipe = [NSPipe pipe];
    [_imagePathsCollector setStandardOutput: pipe];   //设置输出参数
    
    NSFileHandle *file;
    file = [pipe fileHandleForReading];   // 句柄
    [_imagePathsCollector launch];
    NSData *data;
    data = [file readDataToEndOfFile];  // 读取数据
    
    NSString *string = [[NSString alloc] initWithData: data
                                   encoding: NSUTF8StringEncoding];
    return [string componentsSeparatedByString:@"\n"];
}

- (double)similarityBetween:(NSString *)sourceFile to:(NSString *)targetFile
{
    double result;
    double weightOfAspectRatio = 0.5;
    
    NSImage *source = [[NSImage alloc] initWithContentsOfFile:sourceFile];
    NSImage *target = [[NSImage alloc] initWithContentsOfFile:targetFile];
    
    NSDictionary *sourceVector = self.vectorCache[sourceFile];
    if (!sourceVector) {
        sourceVector = [source abstractVector];
        self.vectorCache[sourceFile]=sourceVector;
    }
    
    NSDictionary *targetVector = self.vectorCache[targetFile];
    if (!targetVector) {
        targetVector = [target abstractVector];
        self.vectorCache[targetFile]=targetVector;
    }
    
    double sourceAspectRatio = ((NSNumber *)sourceVector[KEY_ASPECT_RATIO]).doubleValue;
    double targetAspectRatio = ((NSNumber *)targetVector[KEY_ASPECT_RATIO]).doubleValue;
    double similarityOfAspectRatio = 1-fabs(sourceAspectRatio-targetAspectRatio)/sourceAspectRatio;
    
    NSDictionary<NSNumber *,NSNumber *> *sourcePixelVector = sourceVector[KEY_PIXELVECTOR];
    NSDictionary<NSNumber *,NSNumber *> *targetPixelVector = targetVector[KEY_PIXELVECTOR];
    
    //向量余弦相似性
    __block double similarityOfPixelVector = 0;
    __block double targetRank = 0;
    __block double sourceRank = 0;
    [sourcePixelVector enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
        NSNumber *targetObj = targetPixelVector[key];
        if (targetObj) {
            similarityOfPixelVector += obj.doubleValue*targetObj.doubleValue;
        }
        sourceRank += obj.doubleValue * obj.doubleValue;
    }];
    
    sourceRank = sqrt(sourceRank);
    
    [targetPixelVector enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
        targetRank += obj.doubleValue * obj.doubleValue;
    }];
    
    targetRank = sqrt(targetRank);
    
    similarityOfPixelVector = similarityOfPixelVector/(sourceRank*targetRank);
    
    result = similarityOfAspectRatio*weightOfAspectRatio + similarityOfPixelVector*(1-weightOfAspectRatio);
    
    return result;
}

@end
