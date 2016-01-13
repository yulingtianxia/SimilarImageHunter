//
//  ImageComparator.h
//  SimilarImageHunter
//
//  Created by 杨萧玉 on 16/1/13.
//  Copyright © 2016年 杨萧玉. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageComparator : NSObject
- (NSArray<NSString *> *)collectImagePathsInRootPath:(NSString *)rootPath;
- (double)similarityBetween:(NSString *)sourceFile to:(NSString *)targetFile;

@end
