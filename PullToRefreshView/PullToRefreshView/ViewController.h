//
//  ViewController.h
//  PullToRefreshView
//
//  Created by Christopher Pickslay on 12/19/11.
//  Copyright (c) 2011 Two Bit Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PullToRefreshView.h"

@interface ViewController : UIViewController<PullToRefreshViewDelegate>

@property(retain)IBOutlet UIScrollView *scrollView;
@property(assign)PullToRefreshView *topPull;
@property(assign)PullToRefreshView *bottomPull;

-(IBAction)didTapFinishedLoading:(id)sender;
-(IBAction)didTapFinishLoadingTop:(id)sender;
-(IBAction)didTapFinishLoadingBottom:(id)sender;
-(IBAction)didTapMakeContentSizeTaller:(id)sender;

@end
