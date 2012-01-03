//
//  PullToRefreshView.m
//  Grant Paul (chpwn)
//
//  (based on EGORefreshTableHeaderView)
//
//  Created by Devin Doty on 10/14/09October14.
//  Copyright 2009 enormego. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "PullToRefreshView.h"

#define TEXT_COLOR	 [UIColor colorWithRed:(87.0/255.0) green:(108.0/255.0) blue:(137.0/255.0) alpha:1.0]
#define FLIP_ANIMATION_DURATION 0.18f


@interface PullToRefreshView (Private)

@property (nonatomic, assign) PullToRefreshViewState state;

- (void)startTimer;
- (void)dismissView;
- (BOOL)isScrolledToVisible;
- (BOOL)isScrolledToLimit;
- (void)parkVisible;
- (void)hide;

@end

@implementation PullToRefreshView
@synthesize delegate;
@synthesize scrollView;
@synthesize lastUpdatedLabel, statusLabel, arrowImage, activityView;
@synthesize timeout;
@synthesize isBottom;
@synthesize pullToRefreshText, releaseToRefreshText, loadingText;

static const CGFloat kViewHeight = 60.0f;
static const CGFloat kScrollLimit = 65.0f;

- (void)showActivity:(BOOL)shouldShow animated:(BOOL)animated {
    if (shouldShow) [self.activityView startAnimating];
    else [self.activityView stopAnimating];
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:(animated ? 0.1f : 0.0)];
    self.arrowImage.opacity = (shouldShow ? 0.0 : 1.0);
    [UIView commitAnimations];
}

- (void)setImageFlipped:(BOOL)flipped {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.1f];
    self.arrowImage.transform = (flipped ? CATransform3DMakeRotation(M_PI * 2, 0.0f, 0.0f, 1.0f) : CATransform3DMakeRotation(M_PI, 0.0f, 0.0f, 1.0f));
    [UIView commitAnimations];
}

- (id)initWithScrollView:(UIScrollView *)scroll {
    return [self initWithScrollView:scroll atBottom:NO];
}

- (id)initWithWebView:(UIWebView *)webView {
    return [self initWithWebView:webView atBottom:NO];
}

- (id)initWithScrollView:(UIScrollView *)scroll atBottom:(BOOL)atBottom {
    CGFloat offset = atBottom ? scroll.contentSize.height : 0.0f - scroll.bounds.size.height;
    CGRect frame = CGRectMake(0.0f, offset, scroll.bounds.size.width, scroll.bounds.size.height);
    
    if ((self = [super initWithFrame:frame])) {
        CGFloat visibleBottom = atBottom ? kViewHeight : self.frame.size.height;
        isBottom = atBottom;
        self.scrollView = scroll;
        [scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:NULL];
        
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		self.backgroundColor = [UIColor colorWithRed:226.0/255.0 green:231.0/255.0 blue:237.0/255.0 alpha:1.0];
        
		self.lastUpdatedLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0.0f, visibleBottom - 30.0f, self.frame.size.width, 20.0f)] autorelease];
		self.lastUpdatedLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		self.lastUpdatedLabel.font = [UIFont systemFontOfSize:12.0f];
		self.lastUpdatedLabel.textColor = TEXT_COLOR;
		self.lastUpdatedLabel.shadowColor = [UIColor colorWithWhite:0.9f alpha:1.0f];
		self.lastUpdatedLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
		self.lastUpdatedLabel.backgroundColor = [UIColor clearColor];
		self.lastUpdatedLabel.textAlignment = UITextAlignmentCenter;
		[self addSubview:self.lastUpdatedLabel];
        
		self.statusLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0.0f, visibleBottom - 48.0f, self.frame.size.width, 20.0f)] autorelease];
		self.statusLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		self.statusLabel.font = [UIFont boldSystemFontOfSize:13.0f];
		self.statusLabel.textColor = TEXT_COLOR;
		self.statusLabel.shadowColor = [UIColor colorWithWhite:0.9f alpha:1.0f];
		self.statusLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
		self.statusLabel.backgroundColor = [UIColor clearColor];
		self.statusLabel.textAlignment = UITextAlignmentCenter;
		[self addSubview:self.statusLabel];
        
		self.arrowImage = [[[CALayer alloc] init] autorelease];
        UIImage *arrow = [UIImage imageNamed:@"arrow"];
		self.arrowImage.contents = (id) arrow.CGImage;
		self.arrowImage.frame = CGRectMake(25.0f, visibleBottom - kViewHeight + 5.0f, arrow.size.width, arrow.size.height);
		self.arrowImage.contentsGravity = kCAGravityResizeAspect;
        
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 40000
		if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
			self.arrowImage.contentsScale = [[UIScreen mainScreen] scale];
		}
#endif
        
		[self.layer addSublayer:self.arrowImage];
        
        self.activityView = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] autorelease];
		self.activityView.frame = CGRectMake(30.0f, visibleBottom - 38.0f, 20.0f, 20.0f);
		[self addSubview:self.activityView];
        
		[self setState:PullToRefreshViewStateNormal];
    }
    
    return self;     
}

- (id)initWithWebView:(UIWebView *)webView atBottom:(BOOL)atBottom {
    UIScrollView *currentScrollView = nil;
    for (UIView *subView in webView.subviews) {
        if ([subView isKindOfClass:[UIScrollView class]]) {
            currentScrollView = (UIScrollView*)subView;
            break;
        }
    }    
    return [self initWithScrollView:currentScrollView atBottom:atBottom];
}

#pragma mark -
#pragma mark Setters

- (NSDateFormatter *)dateFormatter {
    static NSDateFormatter *defaultFormatter;

    if (dateFormatter) {
        return dateFormatter;
    } else if (!defaultFormatter) {
        defaultFormatter = [[NSDateFormatter alloc] init];
        [defaultFormatter setAMSymbol:@"AM"];
        [defaultFormatter setPMSymbol:@"PM"];
        [defaultFormatter setDateFormat:@"MM/dd/yy hh:mm a"];
    }

    return defaultFormatter;
}

- (void)setDateFormatter:(NSDateFormatter *)formatter {
    if (dateFormatter != formatter) {
        [dateFormatter release];
        dateFormatter = [formatter retain];
        [self refreshLastUpdatedDate];
    }
}

- (void)refreshLastUpdatedDate {
    NSDate *date = [NSDate date];
    
	if ([delegate respondsToSelector:@selector(pullToRefreshViewLastUpdated:)])
		date = [delegate pullToRefreshViewLastUpdated:self];
    
    self.lastUpdatedLabel.text = [NSString stringWithFormat:@"Last Updated: %@", [[self dateFormatter] stringFromDate:date]];
}

- (void)setState:(PullToRefreshViewState)state_ {
    state = state_;
    
	switch (state) {
		case PullToRefreshViewStateReady:
			self.statusLabel.text = self.releaseToRefreshText ? self.releaseToRefreshText : @"Release to refresh...";
			[self showActivity:NO animated:NO];
            [self setImageFlipped:YES];
			break;
            
		case PullToRefreshViewStateNormal:
			self.statusLabel.text = self.pullToRefreshText ? self.pullToRefreshText :
                [NSString stringWithFormat:@"Pull %@ to refresh...", isBottom ? @"up" : @"down"];
			[self showActivity:NO animated:NO];
            [self setImageFlipped:NO];
			[self refreshLastUpdatedDate];
			break;
            
		case PullToRefreshViewStateLoading:
			self.statusLabel.text = self.loadingText ? self.loadingText : @"Loading...";
			[self showActivity:YES animated:YES];
            [self setImageFlipped:NO];
            [self parkVisible];
            [self startTimer];
			break;
            
		default:
			break;
	}
}

#pragma mark -
#pragma mark UIScrollView

- (BOOL)isScrolledToVisible {
    if (isBottom) {
        BOOL scrolledBelowContent = scrollView.contentOffset.y > (scrollView.contentSize.height - scrollView.frame.size.height);
        return scrolledBelowContent && ![self isScrolledToLimit];
    } else {
        BOOL scrolledAboveContent = scrollView.contentOffset.y < 0.0f;
        return scrolledAboveContent && ![self isScrolledToLimit];
    }
}

- (BOOL)isScrolledToLimit {
    if (isBottom) {
        return scrollView.contentOffset.y >= (scrollView.contentSize.height - scrollView.frame.size.height) + kScrollLimit;
    } else {
        return scrollView.contentOffset.y <= -kScrollLimit;
    }
}

- (void)parkVisible {
    if (isBottom) {
        scrollView.contentInset = UIEdgeInsetsMake(0.0f, 0.0f, kViewHeight, 0.0f);
    } else {
        scrollView.contentInset = UIEdgeInsetsMake(kViewHeight, 0.0f, 0.0f, 0.0f);
    }
}

- (void)hide {
    if (isBottom) {
        scrollView.contentInset = UIEdgeInsetsMake(scrollView.contentInset.top, 0.0f, 0.0f, 0.0f);
    } else {
        scrollView.contentInset = UIEdgeInsetsMake(0.0f, 0.0f, scrollView.contentInset.bottom, 0.0f);
    }
}

- (void)handleDragWhileLoading {
    if ([self isScrolledToLimit] || [self isScrolledToVisible]) {
        // allow scrolled portion of view to display
        if (isBottom) {
            CGFloat visiblePortion = scrollView.contentOffset.y - (scrollView.contentSize.height - scrollView.frame.size.height);
            scrollView.contentInset = UIEdgeInsetsMake(0, 0, MIN(visiblePortion, kViewHeight), 0);
        } else {
            scrollView.contentInset = UIEdgeInsetsMake(MIN(-scrollView.contentOffset.y, kViewHeight), 0, 0, 0);
        }
    }    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"contentOffset"]) {
        if (scrollView.isDragging) {
            if (state == PullToRefreshViewStateReady) {
                if ([self isScrolledToVisible]) {
                    NSLog(@"scrolled to visible: %@", isBottom ? @"bottom" : @"top");
                    // dragging from "release to refresh" back down (didn't release at top)
                    [self setState:PullToRefreshViewStateNormal];
                }
            } else if (state == PullToRefreshViewStateNormal) {
                // hit the upper limit, change to "release to refresh"
                if ([self isScrolledToLimit]) {
                    NSLog(@"scrolled to limit: %@", isBottom ? @"bottom" : @"top");
                    [self setState:PullToRefreshViewStateReady];
                }
            } else if (state == PullToRefreshViewStateLoading) {
                [self handleDragWhileLoading];
            }
        } else {
            if (state == PullToRefreshViewStateReady) {
                [UIView beginAnimations:nil context:NULL];
                [UIView setAnimationDuration:0.2f];
                [self setState:PullToRefreshViewStateLoading];
                [UIView commitAnimations];
                
                if ([delegate respondsToSelector:@selector(pullToRefreshViewShouldRefresh:)])
                    [delegate pullToRefreshViewShouldRefresh:self];
            }
        }
    }
}

- (void)finishedLoading {
    if (state == PullToRefreshViewStateLoading) {
        [timer invalidate];
        [self dismissView];
    }
}

- (void)dismissView {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3f];
    [self setState:PullToRefreshViewStateNormal];
    [self hide];
    [UIView commitAnimations];    
}

#pragma mark -
#pragma mark Timeout

- (void)startTimer {
    if (self.timeout > 0) {
        timer = [[NSTimer scheduledTimerWithTimeInterval:self.timeout target:self selector:@selector(timerExpired:) userInfo:nil repeats:NO] retain];
    }
}

- (void)timerExpired:(NSTimer*)theTimer {
    [self dismissView];
}

#pragma mark -
#pragma mark Dealloc

- (void)dealloc {
	[scrollView removeObserver:self forKeyPath:@"contentOffset"];
	[scrollView release];
    [arrowImage release];
    [activityView release];
    [statusLabel release];
    [lastUpdatedLabel release];
    [timer invalidate];
    [timer release];
    [pullToRefreshText release];
    [releaseToRefreshText release];
    [loadingText release];
    [dateFormatter release];
    [super dealloc];
}

@end
