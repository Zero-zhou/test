//
//  RHPlusButton.m
//  CYLTabBarController
//
//  Created by zero on 16/6/11.
//  Copyright © 2016年 微博@iOS程序犭袁. All rights reserved.
//

#import "RHPlusButton.h"
#import "RHTabBarController.h"

CGFloat RHPlusButtonWidth = 0.0f;
UIButton<RHPlusButtonSubclassing> *RHExternPlusButton = nil;
UIViewController *RHPlusChildViewController = nil;

@implementation RHPlusButton

+ (void)registerSubclass {
    if (![self conformsToProtocol:@protocol(RHPlusButtonSubclassing)]) {
        return;
    }
    Class<RHPlusButtonSubclassing> class = self;
    UIButton<RHPlusButtonSubclassing> *plusButton = [class plusButton];
    RHExternPlusButton = plusButton;
    RHPlusButtonWidth = plusButton.frame.size.width;
    if ([[self class] respondsToSelector:@selector(plusChildViewController)]) {
        RHPlusChildViewController = [class plusChildViewController];
        [[self class] addSelectViewControllerTarget:plusButton];
        if ([[self class] respondsToSelector:@selector(indexOfPlusButtonInTabBar)]) {
            RHPlusButtonIndex = [[self class] indexOfPlusButtonInTabBar];
        } else {
            [NSException raise:@"CYLTabBarController" format:@"If you want to add PlusChildViewController, you must realizse `+indexOfPlusButtonInTabBar` in your custom plusButton class.【Chinese】如果你想使用PlusChildViewController样式，你必须同时在你自定义的plusButton中实现 `+indexOfPlusButtonInTabBar`，来指定plusButton的位置"];
        }
    }
}

- (void)plusChildViewControllerButtonClicked:(UIButton<RHPlusButtonSubclassing> *)sender {
    sender.selected = YES;
    [self rh_tabBarController].selectedIndex = RHPlusButtonIndex;
}

#pragma mark -
#pragma mark - Private Methods

+ (void)addSelectViewControllerTarget:(UIButton<RHPlusButtonSubclassing> *)plusButton {
    id target = self;
    NSArray<NSString *> *selectorNamesArray = [plusButton actionsForTarget:target forControlEvent:UIControlEventTouchUpInside];
    if (selectorNamesArray.count == 0) {
        target = plusButton;
        selectorNamesArray = [plusButton actionsForTarget:target forControlEvent:UIControlEventTouchUpInside];
    }
    [selectorNamesArray enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        SEL selector =  NSSelectorFromString(obj);
        [plusButton removeTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];
    }];
    [plusButton addTarget:plusButton action:@selector(plusChildViewControllerButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
}


@end
