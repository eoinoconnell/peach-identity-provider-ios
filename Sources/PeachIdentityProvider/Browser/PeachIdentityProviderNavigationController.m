//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "PeachIdentityProviderNavigationController.h"

#import "PeachIdentityProviderModalTransition.h"

@interface PeachIdentityProviderNavigationController ()

@property (nonatomic) PeachIdentityProviderModalTransition *interactiveTransition;

@end

@implementation PeachIdentityProviderNavigationController

#pragma mark Object lifecycle

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController
{
    if (self = [super initWithRootViewController:rootViewController]) {
        self.transitioningDelegate = self;
    }
    return self;
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Force properties to avoid overrides with UIAppearance    
    UINavigationBar *navigationBarAppearance = [UINavigationBar appearanceWhenContainedInInstancesOfClasses:@[self.class]];
    navigationBarAppearance.barStyle = UIBarStyleDefault;
    navigationBarAppearance.barTintColor = nil;
    navigationBarAppearance.tintColor = nil;
    navigationBarAppearance.titleTextAttributes = nil;
    navigationBarAppearance.translucent = YES;
    navigationBarAppearance.shadowImage = nil;
    navigationBarAppearance.backIndicatorImage = nil;
    navigationBarAppearance.backIndicatorTransitionMaskImage = nil;
    [navigationBarAppearance setTitleVerticalPositionAdjustment:0.f forBarMetrics:UIBarMetricsDefault];
    [navigationBarAppearance setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    
    if (@available(iOS 11, *)) {
        navigationBarAppearance.prefersLargeTitles = NO;
        navigationBarAppearance.largeTitleTextAttributes = nil;
    }
    
    UIScreenEdgePanGestureRecognizer *panGestureRecognizer = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(pullBack:)];
    panGestureRecognizer.edges = UIRectEdgeLeft;
    [self.view addGestureRecognizer:panGestureRecognizer];
}

#pragma mark Accessibility

- (BOOL)accessibilityPerformEscape
{
    [self dismissViewControllerAnimated:YES completion:nil];
    return YES;
}

#pragma mark UIViewControllerTransitioningDelegate protocol

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    return [[PeachIdentityProviderModalTransition alloc] initForPresentation:YES];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    return [[PeachIdentityProviderModalTransition alloc] initForPresentation:NO];
}

- (id<UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id<UIViewControllerAnimatedTransitioning>)animator
{
    return self.interactiveTransition;
}

#pragma mark Gesture recognizers

- (void)pullBack:(UIPanGestureRecognizer *)panGestureRecognizer
{
    CGFloat progress = [panGestureRecognizer translationInView:self.view].x / CGRectGetWidth(self.view.frame);
    switch (panGestureRecognizer.state) {
        case UIGestureRecognizerStateBegan: {
            // Avoid duplicate dismissal (which can make it impossible to dismiss the view controller altogether)
            if (self.interactiveTransition) {
                return;
            }
            
            // Install the interactive transition animation before triggering it
            self.interactiveTransition = [[PeachIdentityProviderModalTransition alloc] initForPresentation:NO];
            [self dismissViewControllerAnimated:YES completion:^{
                // Only stop tracking the interactive transition at the very end. The completion block is called
                // whether the transition ended or was cancelled
                self.interactiveTransition = nil;
            }];
            break;
        }
            
        case UIGestureRecognizerStateChanged: {
            [self.interactiveTransition updateInteractiveTransitionWithProgress:progress];
            break;
        }
            
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateCancelled: {
            [self.interactiveTransition cancelInteractiveTransition];
            break;
        }
            
        case UIGestureRecognizerStateEnded: {
            CGFloat velocity = [panGestureRecognizer velocityInView:self.view].x;
            if (velocity > 0.f || (velocity == 0.f && progress > 0.5f)) {
                [self.interactiveTransition finishInteractiveTransition];
            }
            else {
                [self.interactiveTransition cancelInteractiveTransition];
            }
            break;
        }
            
        default: {
            break;
        }
    }
}


@end
