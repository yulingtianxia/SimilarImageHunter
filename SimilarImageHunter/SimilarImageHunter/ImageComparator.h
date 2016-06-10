//
//  ImageComparator.h
//  SimilarImageHunter
//
//  Created by 杨萧玉 on 16/1/13.
//  Copyright © 2016年 杨萧玉. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageComparator : NSObject
@property (nonatomic) BOOL checkExtension;
- (NSArray<NSString *> *)collectImagePathsInRootPath:(NSString *)rootPath;
- (double)similarityBetweenSourceImage:(NSImage *)sourceImage sourceFile:(NSString *)sourceFile toTargetImage:(NSImage *)targetImage targetFile:(NSString *)targetFile;

@end
