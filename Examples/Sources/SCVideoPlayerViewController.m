//
//  SCVideoPlayerViewController.m
//  SCAudioVideoRecorder
//
//  Created by Simon CORSIN on 8/30/13.
//  Copyright (c) 2013 rFlex. All rights reserved.
//

#import "SCVideoPlayerViewController.h"
#import "SCEditVideoViewController.h"
#import "SCAssetExportSession.h"

@interface SCVideoPlayerViewController () {
    SCPlayer *_player;
}

@end

@implementation SCVideoPlayerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	
    if (self) {
        // Custom initialization
    }
	
    return self;
}

- (void)dealloc {
    self.filterSwitcherView = nil;
    [_player pause];
    _player = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.filterSwitcherView.refreshAutomaticallyWhenScrolling = NO;
    self.filterSwitcherView.contentMode = UIViewContentModeScaleAspectFit;
    
    self.filterSwitcherView.filterGroups = @[
                                             [NSNull null],
                                             [SCFilterGroup filterGroupWithFilter:[SCFilter filterWithName:@"CIPhotoEffectNoir"]],
                                             [SCFilterGroup filterGroupWithFilter:[SCFilter filterWithName:@"CIPhotoEffectChrome"]],
                                             [SCFilterGroup filterGroupWithFilter:[SCFilter filterWithName:@"CIPhotoEffectInstant"]],
                                             [SCFilterGroup filterGroupWithFilter:[SCFilter filterWithName:@"CIPhotoEffectTonal"]],
                                             [SCFilterGroup filterGroupWithFilter:[SCFilter filterWithName:@"CIPhotoEffectFade"]],
                                             // Adding a filter created using CoreImageShop
                                             [SCFilterGroup filterGroupWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"a_filter" withExtension:@"cisf"]]
                                             ];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStyleBordered target:self action:@selector(saveToCameraRoll)];
    
	_player = [SCPlayer player];
    _player.CIImageRenderer = self.filterSwitcherView;
    
	_player.loopEnabled = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [_player setItemByAsset:_recordSession.assetRepresentingRecordSegments];
	[_player play];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [_player pause];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[SCEditVideoViewController class]]) {
        SCEditVideoViewController *editVideo = segue.destinationViewController;
        editVideo.recordSession = self.recordSession;
    }
}

- (void)saveToCameraRoll {
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    SCFilterGroup *currentFilter = self.filterSwitcherView.selectedFilterGroup;
    
    void(^completionHandler)(NSError *error) = ^(NSError *error) {
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        if (error == nil) {
            [self.recordSession saveToCameraRoll];
            [[[UIAlertView alloc] initWithTitle:@"Saved to camera roll" message:@"" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        } else {
            [[[UIAlertView alloc] initWithTitle:@"Failed to save" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        }
    };
    
    if (currentFilter == nil) {
        [self.recordSession mergeRecordSegments:completionHandler];
    } else {
        SCAssetExportSession *exportSession = [[SCAssetExportSession alloc] initWithAsset:self.recordSession.assetRepresentingRecordSegments];
        exportSession.filterGroup = currentFilter;
        exportSession.sessionPreset = SCAssetExportSessionPresetHighestQuality;
        exportSession.outputUrl = self.recordSession.outputUrl;
        exportSession.outputFileType = AVFileTypeMPEG4;
        exportSession.keepVideoSize = YES;
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            completionHandler(exportSession.error);
        }];
    }
}

@end
