//
//  ViewController.m
//  PullToRefreshView
//
//  Created by Christopher Pickslay on 12/19/11.
//  Copyright (c) 2011 Two Bit Labs. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController

@synthesize scrollView;
@synthesize topPull, bottomPull;

-(void)viewDidLoad {
    [super viewDidLoad];
    
    // make area scrollable
    self.scrollView.contentSize = CGSizeMake(320, 540);

    self.topPull = [[PullToRefreshView alloc] initWithScrollView:self.scrollView];
    [self.topPull setDelegate:self];
    self.topPull.loadingText = @"Refreshing stories...";
    NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
    formatter.dateStyle = NSDateFormatterShortStyle;
    formatter.timeStyle = NSDateFormatterNoStyle;
    self.topPull.dateFormatter = formatter;

    [self.scrollView addSubview:self.topPull];

    self.bottomPull = [[PullToRefreshView alloc] initWithScrollView:self.scrollView atBottom:YES];
    [self.bottomPull setDelegate:self];
    self.bottomPull.loadingText = @"Loading more stories...";
    [self.scrollView addSubview:self.bottomPull];    
}

-(void)viewDidUnload {
    [self setScrollView:nil];
    [super viewDidUnload];
}

-(IBAction)didTapFinishedLoading:(id)sender {
    [self.topPull finishedLoading];
    [self.bottomPull finishedLoading];
}

-(IBAction)didTapFinishLoadingTop:(id)sender {
    [self.topPull finishedLoading];
}

-(IBAction)didTapFinishLoadingBottom:(id)sender {
    [self.bottomPull finishedLoading];
}

-(IBAction)didTapMakeContentSizeTaller:(id)sender {
    self.scrollView.contentSize = CGSizeMake(self.scrollView.contentSize.width, self.scrollView.contentSize.height + 20);
}

#pragma mark -
#pragma mark PullToRefreshViewDelegate

-(void)pullToRefreshViewShouldRefresh:(PullToRefreshView *)view {
    
}

-(void)dealloc {
    [scrollView release];
    [super dealloc];
}

@end
