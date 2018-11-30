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
@end
@implementation ImageComparator

- (instancetype)init
{
    self = [super init];
    if (self) {
        _vectorCache = [NSMutableDictionary dictionary];
        _checkExtension = YES;
    }
    return self;
}

- (NSArray<NSString *> *)collectImagePathsInRootPath:(NSString *)rootPath
{
    NSTask *imagePathsCollector;
    imagePathsCollector = [[NSTask alloc] init];
    imagePathsCollector.launchPath = @"/bin/bash";
    NSString *shellPath;

    if (self.checkExtension) {
        shellPath = [NSString stringWithFormat:@"%@%@",[NSBundle mainBundle].resourcePath,@"/find_image_with_extension"];
    }
    else {
        shellPath = [NSString stringWithFormat:@"%@%@",[NSBundle mainBundle].resourcePath,@"/find_image_without_extension"];
    }
    imagePathsCollector.arguments = @[shellPath,rootPath];
    NSPipe *pipe;
    pipe = [NSPipe pipe];
    [imagePathsCollector setStandardOutput: pipe];   //设置输出参数
    
    NSFileHandle *file;
    file = [pipe fileHandleForReading];   // 句柄
    [imagePathsCollector launch];
    NSData *data;
    data = [file readDataToEndOfFile];  // 读取数据
    
    NSString *string = [[NSString alloc] initWithData: data
                                   encoding: NSUTF8StringEncoding];
    NSArray<NSString *> *paths = [string componentsSeparatedByString:@"\n"];
    return paths;
//    NSMutableArray<NSString *> *results = [NSMutableArray array];
//    for (NSString *path in paths) {
//        if ([self checkImageFile:path]) {
//            [results addObject:path];
//        }
//    }
//    return [results copy];
}

//- (BOOL)checkImageFile:(NSString *)filePath
//{
//    __block BOOL dataCheck = NO;
//    NSTask *imageChecker = [[NSTask alloc] init];
//    imageChecker.launchPath = @"/usr/bin/file";
//    imageChecker.arguments = @[filePath];
//    NSPipe *pipe = [NSPipe pipe];
//    imageChecker.standardOutput = pipe;
//    NSFileHandle *file = [pipe fileHandleForReading];   // 句柄
//    [imageChecker launch];
//    NSData *data = [file readDataToEndOfFile];  // 读取数据
//    NSString *string = [[NSString alloc] initWithData: data
//                                             encoding: NSUTF8StringEncoding];
//    [[string componentsSeparatedByString:@" "] enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//        if ([obj isEqualToString:@"image"]) {
//            *stop = YES;
//            dataCheck = YES;
//        }
//    }];
//    
//    BOOL extensionCheck = [filePath.pathExtension isEqualToString:@"pdf"] || [filePath.pathExtension isEqualToString:@"PDF"];
//    return dataCheck||extensionCheck;
//}

- (double)similarityBetweenSourceImage:(NSImage *)sourceImage sourceFile:(NSString *)sourceFile toTargetImage:(NSImage *)targetImage targetFile:(NSString *)targetFile
{
    double result;
    double weightOfAspectRatio = 0.3;
    
    NSDictionary *sourceVector = self.vectorCache[sourceFile];
    if (!sourceVector) {
        sourceVector = [sourceImage abstractVector];
        self.vectorCache[sourceFile] = sourceVector;
    }
    
    NSDictionary *targetVector = self.vectorCache[targetFile];
    if (!targetVector) {
        targetVector = [targetImage abstractVector];
        self.vectorCache[targetFile] = targetVector;
    }
    
    double sourceAspectRatio = ((NSNumber *)sourceVector[KEY_ASPECT_RATIO]).doubleValue;
    double targetAspectRatio = ((NSNumber *)targetVector[KEY_ASPECT_RATIO]).doubleValue;
    double similarityOfAspectRatio = 1 - fabs(sourceAspectRatio - targetAspectRatio) / sourceAspectRatio;
    
    NSDictionary<NSNumber *,NSNumber *> *sourcePixelVector = sourceVector[KEY_PIXELVECTOR];
    NSDictionary<NSNumber *,NSNumber *> *targetPixelVector = targetVector[KEY_PIXELVECTOR];
    
    //向量余弦距离相似性
    __block double similarityOfPixelVector = 0;
    __block double targetRank = 0;
    __block double sourceRank = 0;
    [sourcePixelVector enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
        NSNumber *targetObj = targetPixelVector[key];
        if (targetObj) {
            similarityOfPixelVector += obj.doubleValue * targetObj.doubleValue;
        }
        sourceRank += obj.doubleValue * obj.doubleValue;
    }];
    
    sourceRank = sqrt(sourceRank);
    
    [targetPixelVector enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
        targetRank += obj.doubleValue * obj.doubleValue;
    }];
    
    targetRank = sqrt(targetRank);
    
    similarityOfPixelVector = similarityOfPixelVector / (sourceRank * targetRank);
    
    result = similarityOfAspectRatio*weightOfAspectRatio + similarityOfPixelVector*(1-weightOfAspectRatio);
    
    return result;
}

@end
