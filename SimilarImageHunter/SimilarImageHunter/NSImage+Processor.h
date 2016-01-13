//
//  NSImage+Processor.h
//  SimilarImageHunter
//
//  Created by 杨萧玉 on 16/1/12.
//  Copyright © 2016年 杨萧玉. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define KEY_ASPECT_RATIO @"aspect ratio"
#define KEY_PIXELVECTOR @"pixel vector" 
@interface NSImage (Processor)
- (NSDictionary *)abstractVector;
@end
