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
@property (weak) IBOutlet NSButton *clearBtn;
@property (weak) IBOutlet NSButton *cancelBtn;
@property (weak) IBOutlet NSButton *checkExtensionBtn;
@property (weak) IBOutlet NSButton *ignoreRepeatFileBtn;

@property (nonatomic) BOOL *cancelledPtr;
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

#pragma mark - buttons

- (IBAction)selectSourcePath:(NSButton *)sender {
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    openDlg.prompt = @"Select";
    openDlg.canChooseFiles = YES;
    openDlg.canChooseDirectories = YES;
    openDlg.allowsMultipleSelection = NO;
    
    if ([openDlg runModal] == NSFileHandlingPanelOKButton)
    {
        NSURL *fileURL = [openDlg URL];
        self.sourcePathTF.stringValue = fileURL.path;
    }
}

- (IBAction)selectTargetPath:(NSButton *)sender {
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    openDlg.prompt = @"Select";
    openDlg.canChooseFiles = YES;
    openDlg.canChooseDirectories = YES;
    openDlg.allowsMultipleSelection = NO;
    
    if ([openDlg runModal] == NSFileHandlingPanelOKButton)
    {
        NSURL *fileURL = [openDlg URL];
        self.targetPathTF.stringValue = fileURL.path;
    }
}

- (IBAction)checkExtionsion:(NSButton *)sender {
    self.comparator.checkExtension = (sender.state == NSOnState);
}

- (IBAction)huntClick:(NSButton *)sender {
    sender.enabled = NO;
    __block BOOL cancelled = NO;
    self.resultData = [NSMutableArray array];
    [self.resultTable reloadData];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableDictionary<NSString *,NSNumber *> *similarityMap = [NSMutableDictionary dictionary];
        NSArray<NSString *> *sourcePaths = [self.comparator collectImagePathsInRootPath:self.sourcePathTF.stringValue];
        NSArray<NSString *> *targetPaths = [self.comparator collectImagePathsInRootPath:self.targetPathTF.stringValue];
        NSMutableArray<NSString *> *invalidFiles = [NSMutableArray array];
        for (NSString *sourcePath in sourcePaths) {
            if (cancelled) {
                break;
            }
            if (self.ignoreRepeatFileBtn.state == NSOnState) {
                continue;
            }
            NSImage *sourceImage = [[NSImage alloc] initWithContentsOfFile:sourcePath];
            if (!sourceImage) {
                [invalidFiles addObject:sourcePath];
                continue;
            }
            for (NSString *obj in targetPaths) {
                if (cancelled) {
                    break;
                }
                if ([invalidFiles containsObject:obj]) {
                    continue;
                }
                NSImage *targetImage = [[NSImage alloc] initWithContentsOfFile:obj];
                if (!targetImage) {
                    [invalidFiles addObject:obj];
                    continue;
                }
                NSNumber *similarity = @([self.comparator similarityBetweenSourceImage:sourceImage sourceFile:sourcePath toTargetImage:targetImage targetFile:obj]);
                similarityMap[obj]=similarity;
            }
            __block NSNumber *max = @0;
            __block NSString *similarist = @"";
            [similarityMap enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
                if (obj.doubleValue > max.doubleValue) {
                    max = obj;
                    similarist = key;
                }
            }];
            if (![similarist isEqualToString:@""]) {
                NSMutableArray<NSString *> *resultPaths = [NSMutableArray array];
                [similarityMap enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
                    if (obj.doubleValue == max.doubleValue) {
                        [resultPaths addObject:key];
                    }
                }];
                NSMutableArray<NSDictionary<NSString *,NSString *> *> *children = [NSMutableArray array];
                for (NSString *path in resultPaths) {
                    [children addObject:@{TARGET_PATH:path, SIMILARITY:[NSString stringWithFormat:@"%.02f%%",max.doubleValue*100]}];
                }
                [self.resultData addObject:@{SOURCE_PATH:sourcePath, CHILDREN:[children copy]}];
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            sender.enabled = YES;
            sender.highlighted = NO;
            if (!cancelled) {
                [self.resultTable reloadData];
            }
        });
    });
    self.cancelledPtr = &cancelled;
}

- (IBAction)clearClick:(NSButton *)sender {
    self.sourcePathTF.stringValue = @"";
    self.targetPathTF.stringValue = @"";
    [self.resultData removeAllObjects];
    [self.resultTable reloadData];
}

- (IBAction)cancelClick:(NSButton *)sender {
    if (self.cancelledPtr) {
        *self.cancelledPtr = YES;
    }
    self.huntBtn.enabled = YES;
}

#pragma mark - NSOutlineViewDataSource

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

- (IBAction)doubleClickOutlineAction:(NSOutlineView *)sender {
    NSDictionary *item = [sender itemAtRow:[sender clickedRow]];
    NSString *sourcePath = [item objectForKey:SOURCE_PATH];
    if (sourcePath) {
        [[NSWorkspace sharedWorkspace] openFile:sourcePath];
    }
    NSString *targetPath = [item objectForKey:TARGET_PATH];
    if (targetPath) {
        [[NSWorkspace sharedWorkspace] openFile:targetPath];
    }
}

@end
