//
//  ViewController.m
//  SimilarImageHunter
//
//  Created by 杨萧玉 on 16/1/12.
//  Copyright © 2016年 杨萧玉. All rights reserved.
//

#import "ViewController.h"
#import "ImageComparator.h"

@interface ViewController ()
@property (nonnull,nonatomic) ImageComparator *comparator;
@property (weak) IBOutlet NSTextField *sourcePathTF;
@property (weak) IBOutlet NSButton *huntBtn;
@property (weak) IBOutlet NSTextField *resultPathTF;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.comparator = [ImageComparator new];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (IBAction)huntClick:(NSButton *)sender {
    
    NSMutableDictionary<NSString *,NSNumber *> *similarityMap = [NSMutableDictionary dictionary];
    NSArray<NSString *> *targetPaths = [self.comparator collectImagePathsInRootPath:@"/Users/yangxiaoyu/Documents/Code/Tribe"];
    NSString *sourcePath = self.sourcePathTF.stringValue;
    [targetPaths enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSNumber *similarity = @([self.comparator similarityBetween:sourcePath to:obj]);
        similarityMap[obj]=similarity;
    }];
    __block NSNumber *max = @0;
    __block NSString *similarist = @"";
    [similarityMap enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
        if (obj.doubleValue > max.doubleValue) {
            max = obj;
            similarist = key;
        }
    }];
    if (![similarist isEqualToString:@""]) {
        self.resultPathTF.stringValue = similarist;
    }
}

@end
