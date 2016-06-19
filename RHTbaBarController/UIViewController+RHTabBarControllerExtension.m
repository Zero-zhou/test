//
//  UIViewController+RHTabBarControllerExtension.m
//  CYLTabBarController
//
//  Created by zero on 16/6/11.
//  Copyright © 2016年 微博@iOS程序犭袁. All rights reserved.
//

#import "UIViewController+RHTabBarControllerExtension.h"
#import "RHTabBarController.h"
@implementation UIViewController (RHTabBarControllerExtension)


- (UIViewController *)rh_popSelectTabBarChildViewControllerAtIndex:(NSUInteger)index {
    [self checkTabBarChildControllerValidityAtIndex:index];
    [self.navigationController popToRootViewControllerAnimated:NO];
    RHTabBarController *tabBarController = [self rh_tabBarController];
    tabBarController.selectedIndex = index;
    UIViewController *selectedTabBarChildViewController = tabBarController.selectedViewController;
    BOOL isNavigationController = [[selectedTabBarChildViewController class] isSubclassOfClass:[UINavigationController class]];
    if (isNavigationController) {
        return ((UINavigationController *)selectedTabBarChildViewController).viewControllers[0];
    }
    return selectedTabBarChildViewController;
}

- (void)rh_popSelectTabBarChildViewControllerAtIndex:(NSUInteger)index
                                           completion:(RHPopSelectTabBarChildViewControllerCompletion)completion {
    UIViewController *selectedTabBarChildViewController = [self rh_popSelectTabBarChildViewControllerAtIndex:index];
    dispatch_async(dispatch_get_main_queue(), ^{
        !completion ?: completion(selectedTabBarChildViewController);
    });
}

- (UIViewController *)rh_popSelectTabBarChildViewControllerForClassType:(Class)classType {
    RHTabBarController *tabBarController = [self rh_tabBarController];
    __block NSInteger atIndex = NSNotFound;
    [tabBarController.viewControllers enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        id obj_ = nil;
        BOOL isNavigationController = [[tabBarController.viewControllers[idx] class] isSubclassOfClass:[UINavigationController class]];
        if (isNavigationController) {
            obj_ = ((UINavigationController *)obj).viewControllers[0];
        } else {
            obj_ = obj;
        }
        if ([obj_ isKindOfClass:classType]) {
            atIndex = idx;
            *stop = YES;
            return;
        }
    }];
    
    return [self rh_popSelectTabBarChildViewControllerAtIndex:atIndex];
}

- (void)rh_popSelectTabBarChildViewControllerForClassType:(Class)classType
                                                completion:(RHPopSelectTabBarChildViewControllerCompletion)completion {
    UIViewController *selectedTabBarChildViewController = [self rh_popSelectTabBarChildViewControllerForClassType:classType];
    dispatch_async(dispatch_get_main_queue(), ^{
        !completion ?: completion(selectedTabBarChildViewController);
    });
}

- (void)checkTabBarChildControllerValidityAtIndex:(NSUInteger)index {
    RHTabBarController *tabBarController = [self rh_tabBarController];
    @try {
        UIViewController *viewController;
        viewController = tabBarController.viewControllers[index];
    } @catch (NSException *exception) {
        NSString *formatString = @"\n\n\
        ------ BEGIN NSException Log ---------------------------------------------------------------------\n \
        class name: %@                                                                                    \n \
        ------line: %@                                                                                    \n \
        ----reason: The Class Type or the index or its NavigationController you pass in method `-cyl_popSelectTabBarChildViewControllerAtIndex` or `-cyl_popSelectTabBarChildViewControllerForClassType` is not the item of CYLTabBarViewController \n \
        ------ END ---------------------------------------------------------------------------------------\n\n";
        NSString *reason = [NSString stringWithFormat:formatString,
                            @(__PRETTY_FUNCTION__),
                            @(__LINE__)];
        @throw [NSException exceptionWithName:NSGenericException
                                       reason:reason
                                     userInfo:nil];
    }
}

@end
