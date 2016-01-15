//
//  ViewController.m
//  SimilarImageHunter
//
//  Created by 杨萧玉 on 16/1/12.
//  Copyright © 2016年 杨萧玉. All rights reserved.
//

#import "ViewController.h"
#import "ImageComparator.h"

#define SOURCE_PATH @"SOURCE_PATH"
#define CHILDREN @"children"
#define TARGET_PATH @"targetpath"
#define SIMILARITY @"similarity"

@interface ViewController ()<NSOutlineViewDelegate, NSOutlineViewDataSource>
@property (nonnull,nonatomic) ImageComparator *comparator;
@property (weak) IBOutlet NSTextField *sourcePathTF;
@property (weak) IBOutlet NSTextField *targetPathTF;
@property (weak) IBOutlet NSButton *huntBtn;
@property (weak) IBOutlet NSOutlineView *resultTable;

@property (nonnull,nonatomic) NSMutableArray<NSDictionary<NSString *,id> *> *resultData;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.comparator = [ImageComparator new];
    self.resultTable.delegate = self;
    self.resultTable.dataSource = self;
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (IBAction)huntClick:(NSButton *)sender {
    
    self.resultData = [NSMutableArray array];
    NSMutableDictionary<NSString *,NSNumber *> *similarityMap = [NSMutableDictionary dictionary];
    NSArray<NSString *> *sourcePaths = [self.comparator collectImagePathsInRootPath:self.sourcePathTF.stringValue];
    NSArray<NSString *> *targetPaths = [self.comparator collectImagePathsInRootPath:self.targetPathTF.stringValue];
    
    for (NSString *sourcePath in sourcePaths) {
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
            __block BOOL hasPath = NO;
            [self.resultData enumerateObjectsUsingBlock:^(NSDictionary<NSString *,id> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj[SOURCE_PATH] isEqualToString:sourcePath]) {
                    *stop = YES;
                    hasPath = YES;
                    NSMutableDictionary *dic = [obj mutableCopy];
                    NSMutableArray *arr = [dic[CHILDREN] mutableCopy];
                    if (!arr) {
                        arr = [NSMutableArray array];
                    }
                    [arr addObject:@{TARGET_PATH:similarist, SIMILARITY:max}];
                    dic[CHILDREN] = [arr copy];
                    obj = [dic copy];
                }
            }];
            if (!hasPath) {
                [self.resultData addObject:@{SOURCE_PATH:sourcePath, CHILDREN:@[@{TARGET_PATH:similarist, SIMILARITY:max}]}];
            }
        }
    }
    
    [self.resultTable reloadData];
}

#pragma mark NSOutlineViewDataSource

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if (item == nil) {
        return self.resultData.count;
    }
    
    if ([item isKindOfClass:[NSDictionary class]]) {
        return [[item objectForKey:CHILDREN] count];
    }
    
    return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    if (item == nil) {
        return self.resultData[index];
    }
    
    if ([item isKindOfClass:[NSDictionary class]]) {
        return [[item objectForKey:CHILDREN] objectAtIndex:index];
    }
    
    return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    if ([item isKindOfClass:[NSDictionary class]]) {
        return YES;
    }else {
        return NO;
    }
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    if ([[tableColumn identifier] isEqualToString:CHILDREN]) {
        return [item objectForKey:SIMILARITY];
    }else{
        if ([item isKindOfClass:[NSDictionary class]]) {
            NSString *sourcePath = [item objectForKey:SOURCE_PATH];
            if (sourcePath) {
                return sourcePath;
            }
            return [item objectForKey:TARGET_PATH];
        }
    }
    
    return nil;
}

@end
