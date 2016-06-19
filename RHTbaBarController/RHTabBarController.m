//
//  RHTabBarController.m
//  CYLTabBarController
//
//  Created by zero on 16/6/11.
//  Copyright © 2016年 微博@iOS程序犭袁. All rights reserved.
//

#import "RHTabBarController.h"
#import "RHTabBar.h"
#import "RHPlusButton.h"
#import <objc/runtime.h>

NSString *const RHTabBarItemTitle = @"RHTabBarItemTitle";
NSString *const RHTabBarItemImage = @"RHTabBarItemImage";
NSString *const RHTabBarItemSelectedImage = @"RHTabBarItemSelectedImage";

NSUInteger RHTabbarItemsCount = 0;
NSUInteger RHPlusButtonIndex = 0;
CGFloat RHTabBarItemWidth = 0.0f;
NSString *const RHTabBarItemWidthDidChangeNotification = @"RHTabBarItemWidthDidChangeNotification";

static void * const RHSwappableImageViewDefaultOffsetContext = (void*)&RHSwappableImageViewDefaultOffsetContext;

@interface NSObject (RHTabBarControllerItemInternal)

- (void)rh_setTabBarController:(RHTabBarController *)tabBarController;

@end


@interface RHTabBarController ()

@end

@implementation RHTabBarController
@synthesize viewControllers = _viewControllers;

- (void)viewDidLoad {
    [super viewDidLoad];
    // 处理tabBar，使用自定义 tabBar 添加 发布按钮
    [self setUpTabBar];
    // KVO注册监听
    [self.tabBar addObserver:self forKeyPath:@"swappableImageViewDefaultOffset" options:NSKeyValueObservingOptionNew context:RHSwappableImageViewDefaultOffsetContext];
    self.delegate = self;
}

- (void)viewWillLayoutSubviews {
    if (!self.tabBarHeight) {
        return;
    }
    self.tabBar.frame = ({
        CGRect frame = self.tabBar.frame;
        CGFloat tabBarHeight = self.tabBarHeight;
        frame.size.height = tabBarHeight;
        frame.origin.y = self.view.frame.size.height - tabBarHeight;
        frame;
    });
}

- (void)dealloc {
    // KVO反注册
    [self.tabBar removeObserver:self forKeyPath:@"swappableImageViewDefaultOffset"];
}

#pragma mark -
#pragma mark - public Methods

- (instancetype)initWithViewControllers:(NSArray<UIViewController *> *)viewControllers tabBarItemsAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes {
    if (self = [super init]) {
        _tabBarItemsAttributes = tabBarItemsAttributes;
        self.viewControllers = viewControllers;
    }
    return self;
}

+ (instancetype)tabBarControllerWithViewControllers:(NSArray<UIViewController *> *)viewControllers tabBarItemsAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes {
    RHTabBarController *tabBarController = [[RHTabBarController alloc] initWithViewControllers:viewControllers tabBarItemsAttributes:tabBarItemsAttributes];
    return tabBarController;
}

+ (BOOL)havePlusButton {
    if (RHExternPlusButton) {
        return YES;
    }
    return NO;
}

+ (NSUInteger)allItemsInTabBarCount {
    NSUInteger allItemsInTabBar = RHTabbarItemsCount;
    if ([RHTabBarController havePlusButton]) {
        allItemsInTabBar += 1;
    }
    return allItemsInTabBar;
}

- (id<UIApplicationDelegate>)appDelegate {
    return [UIApplication sharedApplication].delegate;
}

- (UIWindow *)rootWindow {
    UIWindow *result = nil;
    
    do {
        if ([self.appDelegate respondsToSelector:@selector(window)]) {
            result = [self.appDelegate window];
        }
        
        if (result) {
            break;
        }
    } while (NO);
    
    return result;
}

#pragma mark -
#pragma mark - Private Methods

/**
 *  利用 KVC 把系统的 tabBar 类型改为自定义类型。
 */
- (void)setUpTabBar {
    [self setValue:[[RHTabBar alloc] init] forKey:@"tabBar"];
}

- (void)setViewControllers:(NSArray *)viewControllers {
    if (_viewControllers && _viewControllers.count) {
        for (UIViewController *viewController in _viewControllers) {
            [viewController willMoveToParentViewController:nil];
            [viewController.view removeFromSuperview];
            [viewController removeFromParentViewController];
        }
    }
    if (viewControllers && [viewControllers isKindOfClass:[NSArray class]]) {
        if ((!_tabBarItemsAttributes) || (_tabBarItemsAttributes.count != viewControllers.count)) {
            [NSException raise:@"CYLTabBarController" format:@"The count of CYLTabBarControllers is not equal to the count of tabBarItemsAttributes.【Chinese】设置_tabBarItemsAttributes属性时，请确保元素个数与控制器的个数相同，并在方法`-setViewControllers:`之前设置"];
        }
        
        if (RHPlusChildViewController) {
            NSMutableArray *viewControllersWithPlusButton = [NSMutableArray arrayWithArray:viewControllers];
            [viewControllersWithPlusButton insertObject:RHPlusChildViewController atIndex:RHPlusButtonIndex];
            _viewControllers = [viewControllersWithPlusButton copy];
        } else {
            _viewControllers = [viewControllers copy];
        }
        RHTabbarItemsCount = [viewControllers count];
        RHTabBarItemWidth = ([UIScreen mainScreen].bounds.size.width - RHPlusButtonWidth) / (RHTabbarItemsCount);
        NSUInteger idx = 0;
        for (UIViewController *viewController in _viewControllers) {
            NSString *title = nil;
            NSString *normalImageName = nil;
            NSString *selectedImageName = nil;
            if (viewController != RHPlusChildViewController) {
                title = _tabBarItemsAttributes[idx][RHTabBarItemTitle];
                normalImageName = _tabBarItemsAttributes[idx][RHTabBarItemImage];
                selectedImageName = _tabBarItemsAttributes[idx][RHTabBarItemSelectedImage];
            } else {
                idx--;
            }
            
            [self addOneChildViewController:viewController
                                  WithTitle:title
                            normalImageName:normalImageName
                          selectedImageName:selectedImageName];
            [viewController rh_setTabBarController:self];
            idx++;
        }
    } else {
        for (UIViewController *viewController in _viewControllers) {
            [viewController rh_setTabBarController:nil];
        }
        _viewControllers = nil;
    }
}

/**
 *  添加一个子控制器
 *
 *  @param viewController    控制器
 *  @param title             标题
 *  @param normalImageName   图片
 *  @param selectedImageName 选中图片
 */
- (void)addOneChildViewController:(UIViewController *)viewController
                        WithTitle:(NSString *)title
                  normalImageName:(NSString *)normalImageName
                selectedImageName:(NSString *)selectedImageName {
    viewController.tabBarItem.title = title;
    if (normalImageName) {
        UIImage *normalImage = [UIImage imageNamed:normalImageName];
        normalImage = [normalImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        viewController.tabBarItem.image = normalImage;
    }
    if (selectedImageName) {
        UIImage *selectedImage = [UIImage imageNamed:selectedImageName];
        selectedImage = [selectedImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        viewController.tabBarItem.selectedImage = selectedImage;
    }
    if (self.shouldCustomizeImageInsets) {
        viewController.tabBarItem.imageInsets = self.imageInsets;
    }
    if (self.shouldCustomizeTitlePositionAdjustment) {
        viewController.tabBarItem.titlePositionAdjustment = self.titlePositionAdjustment;
    }
    [self addChildViewController:viewController];
}

- (BOOL)shouldCustomizeImageInsets {
    BOOL shouldCustomizeImageInsets = self.imageInsets.top != 0.f || self.imageInsets.left != 0.f || self.imageInsets.bottom != 0.f || self.imageInsets.right != 0.f;
    return shouldCustomizeImageInsets;
}

- (BOOL)shouldCustomizeTitlePositionAdjustment {
    BOOL shouldCustomizeTitlePositionAdjustment = self.titlePositionAdjustment.horizontal != 0.f || self.titlePositionAdjustment.vertical != 0.f;
    return shouldCustomizeTitlePositionAdjustment;
}

#pragma mark -
#pragma mark - KVO Method

// KVO监听执行
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if(context != RHSwappableImageViewDefaultOffsetContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    if(context == RHSwappableImageViewDefaultOffsetContext) {
        CGFloat swappableImageViewDefaultOffset = [change[NSKeyValueChangeNewKey] floatValue];
        [self offsetTabBarSwappableImageViewToFit:swappableImageViewDefaultOffset];
    }
}

- (void)offsetTabBarSwappableImageViewToFit:(CGFloat)swappableImageViewDefaultOffset {
    if (self.shouldCustomizeImageInsets) {
        return;
    }
    NSArray<UITabBarItem *> *tabBarItems = [self rh_tabBarController].tabBar.items;
    [tabBarItems enumerateObjectsUsingBlock:^(UITabBarItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        UIEdgeInsets imageInset = UIEdgeInsetsMake(swappableImageViewDefaultOffset, 0, -swappableImageViewDefaultOffset, 0);
        obj.imageInsets = imageInset;
        if (!self.shouldCustomizeTitlePositionAdjustment) {
            obj.titlePositionAdjustment = UIOffsetMake(0, MAXFLOAT);
        }
    }];
}

#pragma mark - delegate

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController*)viewController {
    NSUInteger selectedIndex = tabBarController.selectedIndex;
    UIButton *plusButton = RHExternPlusButton;
    if (RHPlusChildViewController) {
        if ((selectedIndex == RHPlusButtonIndex) && (viewController != RHPlusChildViewController)) {
            plusButton.selected = NO;
        }
    }
    return YES;
}

@end

#pragma mark - NSObject+CYLTabBarControllerItem

@implementation NSObject (CYLTabBarControllerItemInternal)

- (void)rh_setTabBarController:(RHTabBarController *)tabBarController {
    objc_setAssociatedObject(self, @selector(rh_tabBarController), tabBarController, OBJC_ASSOCIATION_ASSIGN);
}

@end

@implementation NSObject (CYLTabBarController)

- (RHTabBarController *)cyl_tabBarController {
    RHTabBarController *tabBarController = objc_getAssociatedObject(self, @selector(rh_tabBarController));
    if (tabBarController) {
        return tabBarController;
    }
    if ([self isKindOfClass:[UIViewController class]] && [(UIViewController *)self parentViewController]) {
        tabBarController = [[(UIViewController *)self parentViewController] cyl_tabBarController];
        return tabBarController;
    }
    id<UIApplicationDelegate> delegate = ((id<UIApplicationDelegate>)[[UIApplication sharedApplication] delegate]);
    UIWindow *window = delegate.window;
    if ([window.rootViewController isKindOfClass:[RHTabBarController class]]) {
        tabBarController = (RHTabBarController *)window.rootViewController;
    }
    return tabBarController;
}

@end
