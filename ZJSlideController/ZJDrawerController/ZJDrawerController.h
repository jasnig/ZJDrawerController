//
//  ZJSlideController.h
//  ZJSlideController
//
//  Created by ZeroJ on 16/9/13.
//  Copyright © 2016年 ZeroJ. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ZJDrawerController;
typedef NS_ENUM(NSInteger, ZJDrawerControllerStyle) {
    ZJDrawerControllerStyleNone, //抽屉菜单不滚动
    ZJDrawerControllerStyleNormalSlide, // 抽屉菜单和中间的controller同步滚动
    ZJDrawerControllerStyleParallaxSlide, // 抽屉菜单和中间的controller同时滚动, 但不同步
    ZJDrawerControllerStyleScale // 中间的controller滚动时缩放
};

typedef NS_ENUM(NSInteger, ZJDrawerControllerOpenStyle) {
    ZJDrawerControllerOpenStyleFromScreenEdge, // 从屏幕边缘才能触发
    ZJDrawerControllerOpenStyleFromAnyWhere // 任何地方都可以触发
};

@protocol ZJDrawerControllerDelegate <NSObject>

- (BOOL)zj_drawerController:(ZJDrawerController *)drawerController shouldBeginPanGesture: (UIPanGestureRecognizer *)panGesture;

@end


@interface ZJDrawerController : UIViewController
typedef void(^FinishHandler)(BOOL finished);

@property (weak, nonatomic) id<ZJDrawerControllerDelegate> delegate;


/** 抽屉的动画样式 默认为 ZJSlideControllerStyleParalaxSlide*/
@property (assign, nonatomic) ZJDrawerControllerStyle drawerControllerStyle;
/** 打开抽屉手势触发的方式  --- 从屏幕边缘还是全屏 默认为ZJSlideControllerOpenStyleFromAnyWhere*/
@property (assign, nonatomic) ZJDrawerControllerOpenStyle drawerControllerOpenStyle;

/** 背景图片*/
@property (strong, nonatomic) UIImage *backgroundImage;
/** 左边抽屉菜单是否打开 */
@property (assign, nonatomic, readonly) BOOL isLeftDrawerOpen;
/** 右边抽屉菜单是否打开 */
@property (assign, nonatomic, readonly) BOOL isRightDrawerOpen;
/** 是否绘制阴影--- 默认为YES */
@property (assign, nonatomic) BOOL isDrawingShadow;
/** 是否在左右的centerController的子页面中都能打开抽屉菜单 --- 默认为NO */
@property (assign, nonatomic) BOOL canOpenDrawerAtAnyPage;

/** 缩放比例 ,默认0.7*/
@property (assign, nonatomic) CGFloat minimumScale;

/** 滑动手势能够触发的区域宽度 当slideControllerOpenStyle设置为ZJSlideControllerOpenStyleFromScreenEdge的时候才生效 默认为80.0f */
@property (assign, nonatomic) CGFloat scrollEdgeWidth;
/** 左边抽屉菜单的宽度 -- 默认是 200.0f */
@property (assign, nonatomic) CGFloat maxLeftControllerWidth;
/** 右边抽屉菜单的宽度 --- 默认是 200.0f */
@property (assign, nonatomic) CGFloat maxRightControllerWidth;
/**滚动的时候松手的的最小速度 即认为滚动完成  默认为 200.0f */
@property (assign, nonatomic) CGFloat minimumHoldScrollVeloticyX;
/**滚动的时候松手的的最小的滚动距离的百分比 即认为滚动完成 默认为 0.35f */
@property (assign, nonatomic) CGFloat minimumHoldScrollTranstionXPercent;

@property (strong, nonatomic, readonly) UITapGestureRecognizer *tapGesture;
@property (strong, nonatomic, readonly) UIPanGestureRecognizer *panGesture;

@property (strong, nonatomic, readonly) UIViewController *leftController;
@property (strong, nonatomic, readonly) UIViewController *centerController;
@property (strong, nonatomic, readonly) UIViewController *rightController;
/**
 *  初始化方法
 *
 *  @param leftController       左边抽屉菜单
 *  @param centerViewController 中间页面
 *  @param rightController      右边抽屉菜单
 *
 *  @return 含有左右抽屉
 */
- (instancetype)initWithLeftController:(UIViewController *)leftController centerController:(UIViewController *)centerViewController rightController:(UIViewController *)rightController;
/**
 *  初始化方法
 *
 *  @param leftController       左边抽屉菜单
 *  @param centerViewController 中间页面
 *  @return 只有左边抽屉
 */
- (instancetype)initWithLeftController:(UIViewController *)leftController centerController:(UIViewController *)centerViewController;

/**
 *  初始化方法
 *
 *  @param rightController       右边抽屉菜单
 *  @param centerViewController 中间页面
 *  @return 只有右边抽屉
 */
- (instancetype)initWithRightController:(UIViewController *)rightController centerController:(UIViewController *)centerViewController;

/**
 *  设置新的中间页面控制器
 *
 *  @param newCenterViewController newCenterViewController
 *  @param closeDrawer              是否关闭左右抽屉菜单
 */
- (void)setupNewCenterViewController:(UIViewController *)newCenterViewController closeDrawer:(BOOL)closeDrawer finishHandler:(FinishHandler)finishHandler;
/**
 *  打开左边的抽屉菜单
 *
 *  @param animated      是否执行动画
 *  @param finishHandler 打开后的操作
 */
- (void)openLeftDrawerAnimated:(BOOL)animated finishHandler:(FinishHandler)finishHandler;
/**
 *  关闭左边的抽屉菜单
 *
 *  @param animated      是否执行动画
 *  @param finishHandler 关闭后的操作
 */
- (void)closeLeftDrawerAniamted:(BOOL)animated finishHandler:(FinishHandler)finishHandler;
/**
 *  打开右边的抽屉菜单
 *
 *  @param animated      是否执行动画
 *  @param finishHandler 打开后的操作
 */

- (void)openRightDrawerAnimated:(BOOL)animated finishHandler:(FinishHandler)finishHandler;
/**
 *  关闭右边的抽屉菜单
 *
 *  @param animated      是否执行动画
 *  @param finishHandler 关闭后的操作
 */
- (void)closeRightDrawerAnimated:(BOOL)animated finishHandler:(FinishHandler)finishHandler;
/**
 * 打开或者关闭左边抽屉
 * 当抽屉是打开状态 就关闭抽屉
 * 当抽屉是关闭状态 就打开抽屉
 */
- (void)slidingLeftDrawer;
/**
 * 打开或者关闭右边抽屉
 * 当抽屉是打开状态 就关闭抽屉
 * 当抽屉是关闭状态 就打开抽屉
 */
- (void)slidingRightDrawer;
/**
 *  禁用内部的手势
 */
- (void)disableGestureOfCenterContentView;
/**
 *  开启内部的手势
 */
- (void)activeGestureOfCenterContentView;
@end


@interface UIViewController (ZJDrawerController)

/** 抽屉菜单 -- 控制器 */
@property (weak, readonly, nonatomic) ZJDrawerController *zj_drawerController;

@end