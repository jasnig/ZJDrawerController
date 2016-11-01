//
//  ZJSlideController.m
//  ZJSlideController
//
//  Created by ZeroJ on 16/9/13.
//  Copyright © 2016年 ZeroJ. All rights reserved.
//

#import "ZJDrawerController.h"
#import <objc/runtime.h>

typedef NS_ENUM(NSInteger, ZJDrawerControllerType) {
    ZJDrawerControllerTypeNone,
    ZJDrawerControllerTypeCloseLeft,
    ZJDrawerControllerTypeOpenLeft,
    ZJDrawerControllerTypeOpenRight,
    ZJDrawerControllerTypeCloseRight
};

@interface ZJDrawerController ()<UIGestureRecognizerDelegate, UINavigationControllerDelegate> {
    CGRect _beginCenterContentViewFrame;
    CGRect _beginDrawerContentViewFrame;
    CGFloat kPalaxPercent; // 同步滚动的视差比例 1.0
    CGFloat _beginningScale;
}
@property (assign, nonatomic) ZJDrawerControllerType operationType;

// 左边抽屉菜单的控制器
@property (strong, nonatomic) UIViewController *leftController;
// 中间菜单的控制器
@property (strong, nonatomic) UIViewController *centerController;
// 右边抽屉菜单的控制器
@property (strong, nonatomic) UIViewController *rightController;
// 管理中间菜单view
@property (strong, nonatomic) UIView *centerContentView;
// 管理左右抽屉菜单的view
@property (strong, nonatomic) UIView *drawerContentView;

/** 设置image时才会加载 */
@property (strong, nonatomic) UIImageView *backgroundImageView;
//点击(tap)手势, 用来关闭打开的抽屉菜单
@property (strong, nonatomic) UITapGestureRecognizer *tapGesture;
//拖拽手势(pan), 用来滑动打开和关闭抽屉菜单.
@property (strong, nonatomic) UIPanGestureRecognizer *panGesture;

@property (assign, nonatomic) BOOL isLeftDrawerOpen;
@property (assign, nonatomic) BOOL isRightDrawerOpen;
@property (assign, nonatomic) BOOL isAnimating;

@end

@implementation ZJDrawerController


- (instancetype)initWithLeftController:(UIViewController *)leftController centerController:(UIViewController *)centerViewController rightController:(UIViewController *)rightController {
    if (self = [super initWithNibName:nil bundle:nil]) {
        // 赋值
        _leftController = leftController;
        _centerController = centerViewController;
        _rightController = rightController;
        // 需要的初始化 -- 初始化常量, 添加手势, 添加必要的view
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithLeftController:(UIViewController *)leftController centerController:(UIViewController *)centerViewController {
    return [self initWithLeftController:leftController centerController:centerViewController rightController:nil];
}

- (instancetype)initWithRightController:(UIViewController *)rightController centerController:(UIViewController *)centerViewController {
    return [self initWithLeftController:nil centerController:centerViewController rightController:rightController];

}

- (void)commonInit {
    _maxLeftControllerWidth = _leftController ? 200.0f : 0.0f;
    _maxRightControllerWidth = _rightController ? 200.0f : 0.0f;
    _minimumHoldScrollVeloticyX = 200.0f;
    _minimumHoldScrollTranstionXPercent = 0.35f;
    kPalaxPercent = 1.0f;
    _scrollEdgeWidth = 80.0f;
    _minimumScale = 0.7f;
    _isDrawingShadow = YES;
    _canOpenDrawerAtAnyPage = NO;
    _drawerControllerStyle = ZJDrawerControllerStyleParallaxSlide;
    _drawerControllerOpenStyle = ZJDrawerControllerOpenStyleFromAnyWhere;
    self.isAnimating = NO;
    
//    if ([self.centerController isKindOfClass:[UINavigationController class]]) {
//        UINavigationController *centerNavi = (UINavigationController *)self.centerController;
//        // 使用代理来处理很危险, 因为在其他地方可能更改代理(自定义转场动画)
//        // 那么我们这里的在代理方法里面的判断就不生效了
//        // 所以直接在手势接受点击的地方判断是否要响应点击手势
//        centerNavi.delegate = self;
//    }

    [self.view addSubview:self.drawerContentView];
    [self.view addSubview:self.centerContentView];
    // 添加手势到centerContentView上面, 因为我们希望只有内容的vie上面能够响应手势
    // 手势的初始化我们使用了懒加载
    [self.centerContentView addGestureRecognizer:self.panGesture];
    [self.centerContentView addGestureRecognizer:self.tapGesture];
    /// 添加子控制器
    [self addDrawerViewController:_leftController];
    [self addDrawerViewController:_rightController];
    [self addCenterViewController:_centerController];

}


/// 返回NO 手动控制controller的生命周期方法的调用
- (BOOL)shouldAutomaticallyForwardAppearanceMethods {
    return NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (_centerController) {
        // 设置为YES, _centerController 的viewWillAppear方法将会调用
        [_centerController beginAppearanceTransition:YES animated:animated];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (_centerController) {
        // _centerController的viewDidAppear方法将会调用
        [_centerController endAppearanceTransition];
    }

}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (_centerController) {
        [_centerController beginAppearanceTransition:NO animated:animated];
    }
    

}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (_centerController) {
        [_centerController endAppearanceTransition];
    }

}

/// 设置约束 --- 自动适配
- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    if (self.isAnimating) {
        return;
    }
    if (_backgroundImageView) {
        self.backgroundImageView.frame = self.view.bounds;
    }
    // 旋转的时重置transfrom --- 并且一下的frame设置会关闭已经打开的抽屉
    self.centerContentView.transform = CGAffineTransformIdentity;
    // 中间控制器的view因为是全屏显示,初始frame设置为和当前控制器的view的尺寸一样
    self.centerContentView.frame = self.view.bounds;
    // drawerContentView 的frame设置需要注意
    // drawerContentView 的 x == -_maxLeftControllerWidth(屏幕左边的外面)
    // drawerContentView 的 width = self.view.bounds.size.width + (_maxLeftControllerWidth + _maxRightControllerWidth)
    self.drawerContentView.frame = [self getHideFrame];
    // 中间控制器的view因为是全屏显示,初始frame设置为和centerContentView的尺寸一样
    _centerController.view.frame = self.centerContentView.bounds;
    
    if (_leftController) {
        // 左边抽屉菜单在drawerContentView 的左边, 宽度为_maxLeftControllerWidth
        _leftController.view.frame = CGRectMake(0.0f, 0.0f, _maxLeftControllerWidth, self.view.bounds.size.height);
    }
    if (_rightController) {
        // 右边抽屉菜单在drawerContentView 的右边, 宽度为_maxRightControllerWidth
        _rightController.view.frame = CGRectMake(self.drawerContentView.bounds.size.width - _maxRightControllerWidth, 0.0f, _maxRightControllerWidth, self.view.bounds.size.height);
        
    }
    
    // 这个时候重新绘制shadow
    self.centerContentView.layer.shadowPath = NULL;
    [self setupShadowForCenterContentView];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)slidingLeftDrawer {
    if (self.isLeftDrawerOpen) {// 已经打开
        [self closeLeftDrawerAniamted:YES finishHandler:nil];
    }
    else {
        [self openLeftDrawerAnimated:YES finishHandler:nil];
    }

}

- (void)slidingRightDrawer {
    if (self.isRightDrawerOpen) {// 已经打开
        [self closeRightDrawerAnimated:YES finishHandler:nil];
    }
    else {
        [self openRightDrawerAnimated:YES finishHandler:nil];
    }
    
}


- (void)openLeftDrawerAnimated:(BOOL)animated finishHandler:(FinishHandler)finishHandler {
    if (_leftController) {
        CGFloat duration = animated ? 0.25 : 0.0f;
        [_leftController beginAppearanceTransition:YES animated:YES];
        self.isAnimating = YES;
        [self hideRightShowLeft];
        
        [self setupShadowForCenterContentView];
        [UIView animateWithDuration:duration animations:^{
            self.drawerContentView.frame = [self getLeftShowFrame];
            if (self.drawerControllerStyle == ZJDrawerControllerStyleScale) {
                self.centerContentView.transform = CGAffineTransformMakeScale(_minimumScale, _minimumScale);
            }

            CGRect centerFrame = self.centerContentView.frame;
            centerFrame.origin.x = _maxLeftControllerWidth;
            self.centerContentView.frame = centerFrame;

        } completion:^(BOOL finished) {
            self.isAnimating = NO;
            [_leftController endAppearanceTransition];
            if (finishHandler) {
                finishHandler(finished);
            }
        }];
    }
}

- (void)closeLeftDrawerAniamted:(BOOL)animated finishHandler:(FinishHandler)finishHandler {
    if (_leftController) {
        CGFloat duration = animated ? 0.25 : 0.0f;
 
        [_leftController beginAppearanceTransition:NO animated:YES];
        self.isAnimating = YES;
        [self hideRightShowLeft];

        [UIView animateWithDuration:duration animations:^{
            self.drawerContentView.frame = [self getHideFrame];
            // 先缩放在设置frame 否则不能同步动画效果
            self.centerContentView.transform = CGAffineTransformIdentity;
            self.centerContentView.frame = self.view.bounds;
        } completion:^(BOOL finished) {
            self.isAnimating = NO;
            [_leftController endAppearanceTransition];
            if (finishHandler) {
                finishHandler(finished);
            }
        }];
    }
}

- (void)openRightDrawerAnimated:(BOOL)animated finishHandler:(FinishHandler)finishHandler {
    if (_rightController) {
        CGFloat duration = animated ? 0.25 : 0.0f;
        [_rightController beginAppearanceTransition:YES animated:YES];
        self.isAnimating = YES;
        [self hideLeftShowRight];
        [self setupShadowForCenterContentView];

        [UIView animateWithDuration:duration animations:^{
            self.drawerContentView.frame = [self getRightShowFrame];
            if (self.drawerControllerStyle == ZJDrawerControllerStyleScale) {
                self.centerContentView.transform = CGAffineTransformMakeScale(_minimumScale, _minimumScale);
            }

            CGRect centerFrame = self.centerContentView.frame;
            centerFrame.origin.x = self.view.bounds.size.width - _maxRightControllerWidth - centerFrame.size.width;
            self.centerContentView.frame = centerFrame;
            NSLog(@"%f",self.centerContentView.frame.origin.x);

        } completion:^(BOOL finished) {
            self.isAnimating = NO;
            [_rightController endAppearanceTransition];
            if (finishHandler) {
                finishHandler(finished);
            }
        }];
    }


}

- (void)closeRightDrawerAnimated:(BOOL)animated finishHandler:(FinishHandler)finishHandler {
    if (_rightController) {
        CGFloat duration = animated ? 0.25 : 0.0f;
        [_rightController beginAppearanceTransition:NO animated:YES];
        self.isAnimating = YES;
        [self hideLeftShowRight];
        [UIView animateWithDuration:duration animations:^{
            self.drawerContentView.frame = [self getHideFrame];
            self.centerContentView.transform = CGAffineTransformIdentity;

            self.centerContentView.frame = self.view.bounds;
        } completion:^(BOOL finished) {
            self.isAnimating = NO;
            [_rightController endAppearanceTransition];
            if (finishHandler) {
                finishHandler(finished);
            }
        }];
    }

}

- (void)handleTap:(UITapGestureRecognizer *)tapGesture {
    if (self.isLeftDrawerOpen) {
        [self closeLeftDrawerAniamted:YES finishHandler:nil];
    }
    if (self.isRightDrawerOpen) {
        [self closeRightDrawerAnimated:YES finishHandler:nil];
    }
}

- (void)handlePan:(UIPanGestureRecognizer *)panGesture {
    CGPoint transtion = [panGesture translationInView:self.view];
    CGFloat velocityX = [panGesture velocityInView:self.view].x;
    /**
     *  以下的手势中的条件判断中 加上 &&_rightController 或者 &&_leftController
     *  是因为 当他们为 nil的时候 对应的_maxRightControllerWidth和_maxLeftControllerWidth
     *  为 0, 那么在之后的处理中的除法操作就是不正确的 会crash (transtion.x)/0
     *  当然, 只需要在打开左右抽屉的时候判断就可以了, 因为既然能调用关闭, 说明之前打开时已经判断不为nil
     */
    
    switch (panGesture.state) {
        case UIGestureRecognizerStateBegan:
            [self setupShadowForCenterContentView];

            if (self.isAnimating) {// 正在动画就停止pan手势
                panGesture.enabled = NO;
            }
            else {
                /// 主控制器的frame
                _beginCenterContentViewFrame = self.centerContentView.frame;
                _beginDrawerContentViewFrame = self.drawerContentView.frame;
                if (_beginCenterContentViewFrame.origin.x == 0) {
                    _beginningScale = 1.0;
                    if (velocityX < 0 && _rightController) {
                        self.operationType = ZJDrawerControllerTypeOpenRight;
                    }
                    else if  (velocityX > 0 && _leftController) {
                        self.operationType = ZJDrawerControllerTypeOpenLeft;
                    }
                    else {
                        
                        self.operationType = ZJDrawerControllerTypeNone;
                    }
                }
                else {
                    _beginningScale = _minimumScale;
                    if (self.centerContentView.center.x > self.view.center.x && velocityX < 0 && _leftController) {
                        self.operationType = ZJDrawerControllerTypeCloseLeft;
                    }
                    else if (self.centerContentView.center.x < self.view.center.x && velocityX > 0 && _rightController) {
                        self.operationType = ZJDrawerControllerTypeCloseRight;
                    }
                    else {
                        
                        self.operationType = ZJDrawerControllerTypeNone;
                    }

                }
                
            }
            break;
            
        case UIGestureRecognizerStateChanged: {
            self.isAnimating = YES;
            CGRect drawerContentViewFrame = _beginDrawerContentViewFrame;
            drawerContentViewFrame.origin.x += transtion.x*kPalaxPercent;
            
            CGRect centerContentViewFrame = _beginCenterContentViewFrame;
            centerContentViewFrame.origin.x += transtion.x;
            
            CGFloat scale = _beginningScale;

            // transtion.x == 0 的情况我们不处理
            
            if (transtion.x < 0) {//左滑
                
                if (self.drawerControllerStyle == ZJDrawerControllerStyleScale) {
                    
                    if (self.operationType == ZJDrawerControllerTypeOpenLeft && _leftController) {
                        // 之前是打开左边抽屉的操作, 但是没有松手的情况下, 返回去, 成为打开右边抽屉的操作
                        _beginCenterContentViewFrame.origin.x = 0.0f;
                        _beginDrawerContentViewFrame = [self getHideFrame];
                        _beginningScale = 1.0;

                        self.operationType = ZJDrawerControllerTypeOpenRight;
                    }

                    
                    if (self.operationType == ZJDrawerControllerTypeCloseLeft && _leftController) {  // 关闭左边抽屉
                        [self hideRightShowLeft];
                        if (transtion.x <= -_maxLeftControllerWidth) {// 关闭完成
                            [panGesture setTranslation:CGPointZero inView:self.centerContentView];
                            _beginCenterContentViewFrame.origin.x = 0.0f;
                            _beginDrawerContentViewFrame = [self getHideFrame];
                            _beginningScale = 1.0f;
                            self.operationType = ZJDrawerControllerTypeOpenRight;
                        }
                        
                        CGFloat progress = transtion.x/_maxLeftControllerWidth;
                        scale = scale - (1-_minimumScale)*progress;
                        NSLog(@"关闭左边抽屉 %f ---- %f -- *  %f", transtion.x, scale, -_maxLeftControllerWidth);
                        
                        scale = MIN(scale, 1.0f); // 最大恢复为1.0
                        self.centerContentView.transform = CGAffineTransformMakeScale(scale, scale);
                        // 置为0
                        transtion.x = 0.0f;

                        
                    }
                    if(self.operationType == ZJDrawerControllerTypeOpenRight && _rightController) {// 打开右边抽屉
                        [self hideLeftShowRight];

                        CGFloat progress = transtion.x/_maxRightControllerWidth;
                        scale = scale + (1-_minimumScale)*progress;
                        scale = MAX(scale, _minimumScale); // 最小缩小为_minimumScale
                        NSLog(@"打开右边抽屉 %f ---- %f -- *  %f", transtion.x, scale, centerContentViewFrame.origin.x);
                        
                        self.centerContentView.transform = CGAffineTransformMakeScale(scale, scale);
                        
                        centerContentViewFrame.origin.x = self.view.bounds.size.width - self.centerContentView.frame.size.width - ABS(transtion.x);
                        
                    }
                        
                    
                    
                    CGRect scaledFrame = self.centerContentView.frame;
                    scaledFrame.origin.x = centerContentViewFrame.origin.x;
                    centerContentViewFrame = scaledFrame;
                }
                else {
                    if (self.isLeftDrawerOpen) {  // 关闭左边抽屉
                        if (transtion.x <= -_maxLeftControllerWidth) {// 关闭完成
                            [panGesture setTranslation:CGPointZero inView:self.centerContentView];
                            _beginCenterContentViewFrame.origin.x = 0;
                            _beginDrawerContentViewFrame = [self getHideFrame];
                        }
                        [self hideRightShowLeft];
                        
                    }
                    if(self.isRightDrawerOpen) {// 打开右边抽屉
                        [self hideLeftShowRight];
                    }
                }
                // 固定最大左移距离 (右边完全打开)
                drawerContentViewFrame.origin.x = MAX([self getRightShowFrame].origin.x, drawerContentViewFrame.origin.x);
                centerContentViewFrame.origin.x = MAX(self.view.bounds.size.width - _maxRightControllerWidth - centerContentViewFrame.size.width, centerContentViewFrame.origin.x);
                self.drawerContentView.frame = drawerContentViewFrame;
                self.centerContentView.frame = centerContentViewFrame;
            }
            if (transtion.x > 0) {

                
                if (self.drawerControllerStyle == ZJDrawerControllerStyleScale) {
                    
                    if (self.operationType == ZJDrawerControllerTypeOpenRight) {
                        // 之前是打开右边抽屉的操作, 但是没有松手的情况下, 返回去, 成为打开左边抽屉的操作
                        _beginCenterContentViewFrame.origin.x = 0.0f;
                        _beginDrawerContentViewFrame = [self getHideFrame];
                        _beginningScale = 1.0;
                        self.operationType = ZJDrawerControllerTypeOpenLeft;
                    }
                    
                    if (self.operationType == ZJDrawerControllerTypeOpenLeft && _leftController) { // 打开左边抽屉
                        [self hideRightShowLeft];
                        CGFloat progress = transtion.x/_maxLeftControllerWidth;
                        scale = scale - (1-_minimumScale)*progress;
                        scale = MAX(scale, _minimumScale);
                        NSLog(@"打开左边抽屉 %f----  %f --", scale, transtion.x);
                        
                        self.centerContentView.transform = CGAffineTransformMakeScale(scale, scale);
                        
                    }
                    if(self.operationType == ZJDrawerControllerTypeCloseRight && _rightController) {// 关闭右边抽屉
                        [self hideLeftShowRight];
                        if (transtion.x >= _maxRightControllerWidth) {
                            [panGesture setTranslation:CGPointZero inView:self.centerContentView];
                            _beginCenterContentViewFrame.origin.x = 0.0f;
                            _beginDrawerContentViewFrame = [self getHideFrame];
                            _beginningScale = 1.0f;
                            self.operationType = ZJDrawerControllerTypeOpenLeft;
                        }
                        CGFloat progress = transtion.x/_maxRightControllerWidth;
                        scale = scale + (1-_minimumScale)*progress;
                        scale = MIN(scale, 1.0f);
                        
                        NSLog(@"关闭右边抽屉 %f ---- %f -- *  %f", transtion.x, scale, -_maxLeftControllerWidth);
                        
                        
                        self.centerContentView.transform = CGAffineTransformMakeScale(scale, scale);
                        // 缩放之后再设置frame才准确
                        CGFloat right = self.view.bounds.size.width - _maxRightControllerWidth + transtion.x;
                        centerContentViewFrame.origin.x = right - self.centerContentView.frame.size.width;
                        transtion.x = 0;
                    }
                    
                    CGRect scaledFrame = self.centerContentView.frame;
                    scaledFrame.origin.x = centerContentViewFrame.origin.x;
                    centerContentViewFrame = scaledFrame;

                }
                else {
                    if (self.isLeftDrawerOpen) { // 打开左边抽屉
                        [self hideRightShowLeft];
                        
                    }
                    if(self.isRightDrawerOpen) {// 关闭右边抽屉
                        if (transtion.x >= _maxRightControllerWidth) {// 关闭完成
                            [panGesture setTranslation:CGPointZero inView:self.centerContentView];
                            _beginCenterContentViewFrame.origin.x = 0.0f;
                            _beginDrawerContentViewFrame = [self getHideFrame];
                        }
                        [self hideLeftShowRight];
                    }
                }
                // 固定最大右移距离(左边完全打开)
                drawerContentViewFrame.origin.x = MIN([self getLeftShowFrame].origin.x, drawerContentViewFrame.origin.x);
                centerContentViewFrame.origin.x = MIN(_maxLeftControllerWidth, centerContentViewFrame.origin.x);
                self.drawerContentView.frame = drawerContentViewFrame;
                self.centerContentView.frame = centerContentViewFrame;
            }

        }
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            self.isAnimating = NO;
            if (self.operationType == ZJDrawerControllerTypeNone) break;

            CGPoint velocity = [panGesture velocityInView:panGesture.view];
            CGFloat velocityX = ABS(velocity.x);
            CGFloat deltaX = ABS(transtion.x);
//            NSLog(@"%f--------",deltaX);
            if (self.centerContentView.center.x > self.view.center.x) {

                if (deltaX < _maxLeftControllerWidth*_minimumHoldScrollTranstionXPercent) {// 移动距离很少
                    if (velocityX > _minimumHoldScrollVeloticyX) {// 由松开手的速度决定
                        if (transtion.x > 0) {
                            [self openLeftDrawerAnimated:YES finishHandler:nil];
                        }
                        else {
                            [self closeLeftDrawerAniamted:YES finishHandler:nil];
                            
                        }
                    }
                    else {
                        if (transtion.x > 0) {
                            [self closeLeftDrawerAniamted:YES finishHandler:nil];
                        }
                        else {
                            [self openLeftDrawerAnimated:YES finishHandler:nil];
                            
                        }
                    }
                }
                else {
                    if (transtion.x > 0) {
                        [self openLeftDrawerAnimated:YES finishHandler:nil];
                    }
                    else {
                        [self closeLeftDrawerAniamted:YES finishHandler:nil];
                        
                    }
                }
            }
            
            if (self.centerContentView.center.x < self.view.center.x) {

                if (deltaX < _maxRightControllerWidth*_minimumHoldScrollTranstionXPercent) {// 移动距离很少
                    if (velocityX > _minimumHoldScrollVeloticyX) {// 由松开手的速度决定
                        if (transtion.x > 0) {
                            [self closeRightDrawerAnimated:YES finishHandler:nil];
                        }
                        else {
                            [self openRightDrawerAnimated:YES finishHandler:nil];
                            
                        }
                    }
                    else {
                        if (transtion.x > 0) {
                            [self openRightDrawerAnimated:YES finishHandler:nil];
                        }
                        else {
                            [self closeRightDrawerAnimated:YES finishHandler:nil];
                            
                        }
                    }
                }
                else {
                    if (transtion.x > 0) {
                        [self closeRightDrawerAnimated:YES finishHandler:nil];
                    }
                    else {
                        [self openRightDrawerAnimated:YES finishHandler:nil];
                        
                    }
                }

            }
        }
            break;

        default:
            self.isAnimating = NO;
            break;
    }
}

- (void)hideLeftShowRight {
    _leftController.view.hidden = YES;
    _rightController.view.hidden = NO;
}
- (void)hideRightShowLeft {
    _leftController.view.hidden = NO;
    _rightController.view.hidden = YES;
}

- (void)setupNewCenterViewController:(UIViewController *)newCenterViewController closeDrawer:(BOOL)closeDrawer finishHandler:(FinishHandler)finishHandler{
    if (newCenterViewController && newCenterViewController != _centerController) {
        /// 移除旧的
        removeCenterViewController(_centerController);
        /// 设置新的
        _centerController = newCenterViewController;
        /// 添加新的
        [_centerController beginAppearanceTransition:YES animated:YES];
        [self addCenterViewController:_centerController];
        [_centerController endAppearanceTransition];
    }
    if (closeDrawer) {
        [self handleTap:nil];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (finishHandler) {
            finishHandler(YES);
        }
    });
}

- (void)addCenterViewController:(UIViewController *)centerViewController {
    if (centerViewController) {
        [self addChildViewController:centerViewController];
        centerViewController.view.frame = self.view.bounds;
        [self.centerContentView addSubview:centerViewController.view];
        [centerViewController didMoveToParentViewController:self];
    }
}

- (void)addDrawerViewController:(UIViewController *)drawerViewController {
    if (drawerViewController) {
        //① 添加子控制器, 这个方法会默认调[drawerViewController willMoveToParentViewController:self]
        // 所以在添加的时候不需要我们手动调用这个方法
        [self addChildViewController:drawerViewController];
        //② 设置子控制器的view, 在新的控制器的view种的frame
        // 因为我们会在viewWillLayoutSubviews重新设置他的frame, 所以这里设置为了CGRectZero
        drawerViewController.view.frame = CGRectZero;
        //③ 添加子控制器的view到容器控制器中的view来, 这里把左右抽屉菜单的view
        // 都添加到了drawerContentView中统一管理
        [self.drawerContentView addSubview:drawerViewController.view];
        //④ 在添加完成后, 必须要调用这个方法通知系统, 添加的操作已经完成
        [drawerViewController didMoveToParentViewController:self];
    }
}

static inline void removeCenterViewController(UIViewController *centerViewController) {
    if (centerViewController) {
        [centerViewController beginAppearanceTransition:NO animated:YES];
        [centerViewController willMoveToParentViewController:nil];
        [centerViewController.view removeFromSuperview];
        /// 在移除之前调用, 否则为nil
        [centerViewController endAppearanceTransition];
        [centerViewController removeFromParentViewController];
    }
}

- (void)setupShadowForCenterContentView {
    if (!self.isDrawingShadow) {
        return;
    }
    if (self.centerContentView.layer.shadowPath == NULL) {

        self.centerContentView.layer.shadowColor = [[UIColor blackColor] CGColor];
        self.centerContentView.layer.shadowRadius = 10;
        self.centerContentView.layer.shadowOffset = CGSizeZero;
        self.centerContentView.layer.masksToBounds = NO;
        self.centerContentView.layer.shadowPath = [[UIBezierPath bezierPathWithRect:self.centerContentView.bounds] CGPath];
        self.centerContentView.layer.shadowOpacity = 1.0;
    }
    
}

- (void)disableGestureOfCenterContentView {

    self.tapGesture.enabled = NO;
    self.panGesture.enabled = NO;
}

- (void)activeGestureOfCenterContentView {
    self.tapGesture.enabled = YES;
    self.panGesture.enabled = YES;

}

- (void)setIsAnimating:(BOOL)isAnimating {
    _isAnimating = isAnimating;
    self.view.userInteractionEnabled = !isAnimating;
}

- (BOOL)isLeftDrawerOpen { /// 以中心准确(在缩放中使用frame.x是不准确)
    return (_leftController && self.centerContentView.center.x > self.view.center.x);
}

- (BOOL)isRightDrawerOpen {
    return (_rightController && self.centerContentView.center.x < self.view.center.x);
}


- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    
    if (self.isLeftDrawerOpen || self.isRightDrawerOpen) {
        return YES;
    }
    
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        UIPanGestureRecognizer *pan = (UIPanGestureRecognizer *)gestureRecognizer;
        CGFloat locationX = [gestureRecognizer locationInView:self.centerContentView].x;
        CGFloat transtionX = [pan translationInView:self.centerContentView].x;

        
        if (!_rightController && !self.isLeftDrawerOpen) {// 没有右边抽屉, 并且左边抽屉是关闭状态的时候 不允许打开右边抽屉
            if (transtionX < 0) {
                return NO;
            }
        }
        else if (!_leftController && !self.isRightDrawerOpen) {// 没有左边抽屉, 并且右边抽屉是关闭状态的时候 不允许打开左边抽屉
            if (transtionX > 0) {
                return NO;
            }

        }
        
        if (self.drawerControllerOpenStyle == ZJDrawerControllerOpenStyleFromScreenEdge) {
            
            if ((locationX < _scrollEdgeWidth && transtionX > 0)
                || ((locationX > self.view.bounds.size.width - _scrollEdgeWidth) && transtionX < 0)
                || self.isLeftDrawerOpen
                || self.isRightDrawerOpen
                ) { // 手势开始的位置在区域内并且滑动的方向正确才返回yes
                return YES;
            }
            else {
                return NO;
            }
        }
        
        if (self.delegate && [_delegate respondsToSelector:@selector(zj_drawerController:shouldBeginPanGesture:)]) {
            return [self.delegate zj_drawerController:self shouldBeginPanGesture:self.panGesture];
        }

    }

    
    if (gestureRecognizer == _tapGesture) {
        if (self.isLeftDrawerOpen || self.isRightDrawerOpen) return YES;
        else return NO;
    }
    
    return YES;
}


//- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
////    NSLog(@"--------------show");
//    
//// 如果项目中设置了中间控制器(navigationController)的代理为其他对象
//    if ([self.centerController isKindOfClass:[UINavigationController class]]) {
//        UINavigationController *centerNavi = (UINavigationController *)self.centerController;
//        if (centerNavi.childViewControllers.count == 1) {
//            [self activeGestureOfCenterContentView];
//        }
//        else {
//            [self disableGestureOfCenterContentView];
//        }
//        
//    }
//
//}


- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    
    if (self.isLeftDrawerOpen || self.isRightDrawerOpen) {
        return YES; // 抽屉打开的时候接受手势
    }
    if (self.centerController && [self.centerController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *centerNavi = (UINavigationController *)self.centerController;
        if (gestureRecognizer == self.tapGesture && centerNavi.childViewControllers.count != 1) {// 在其他界面禁用tap手势, 因为tap手势会和系统的返回点击手势冲突
            return NO;
        }
        if (gestureRecognizer == self.panGesture && centerNavi.childViewControllers.count != 1) {
            return _canOpenDrawerAtAnyPage;
        }
    }
    return YES;
}

- (void)setDrawerControllerStyle:(ZJDrawerControllerStyle)drawerControllerStyle {
    _drawerControllerStyle = drawerControllerStyle;
    switch (drawerControllerStyle) {
        case ZJDrawerControllerStyleParallaxSlide:
            kPalaxPercent = 0.7f;
            break;
        case ZJDrawerControllerStyleNone:
            kPalaxPercent = 0.0f;
            break;
        case ZJDrawerControllerStyleScale:
            kPalaxPercent = 0.0f;
            break;
        default:
            kPalaxPercent = 1.0f;
            break;
    }
}

- (CGRect)getHideFrame {
    return CGRectMake(-_maxLeftControllerWidth*kPalaxPercent, 0.0f, self.view.bounds.size.width + (_maxLeftControllerWidth + _maxRightControllerWidth)*kPalaxPercent, self.view.bounds.size.height);

}

- (CGRect)getLeftShowFrame {
    return CGRectMake(0.0f, 0.0f, self.view.bounds.size.width + (_maxLeftControllerWidth + _maxRightControllerWidth)*kPalaxPercent, self.view.bounds.size.height);
}

- (CGRect)getRightShowFrame {
    return CGRectMake(-(_maxRightControllerWidth+_maxLeftControllerWidth)*kPalaxPercent, 0.0f, self.view.bounds.size.width + (_maxLeftControllerWidth + _maxRightControllerWidth)*kPalaxPercent, self.view.bounds.size.height);

}

- (UITapGestureRecognizer *)tapGesture {
    if (!_tapGesture) {
        _tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        _tapGesture.numberOfTapsRequired = 1;
        _tapGesture.delegate = self;
    }
    return  _tapGesture;
}

- (UIPanGestureRecognizer *)panGesture {
    if (!_panGesture) {
        _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        _panGesture.delegate = self;
    }
    return _panGesture;
}

- (UIView *)centerContentView {
    if (!_centerContentView) {
        _centerContentView = [UIView new];
        _centerContentView.backgroundColor = [UIColor clearColor];
        _centerContentView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    }
    return _centerContentView;
}

- (UIView *)drawerContentView {
    if (!_drawerContentView) {
        _drawerContentView = [UIView new];
        _drawerContentView.backgroundColor = [UIColor clearColor];
        _drawerContentView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    }
    return _drawerContentView;

}

- (UIImageView *)backgroundImageView {
    if (!_backgroundImage) {
        return nil;
    }
    
    if (!_backgroundImageView) {
        _backgroundImageView = [[UIImageView alloc] init];
        _backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
        [self.view insertSubview:_backgroundImageView atIndex:0];
    }
    
    return _backgroundImageView;
}

- (void)setBackgroundImage:(UIImage *)backgroundImage {
    _backgroundImage = backgroundImage;
    if (backgroundImage) {
        self.backgroundImageView.image = backgroundImage;
    }
}

@end

@implementation UIViewController (ZJDrawerController)


- (ZJDrawerController *)zj_drawerController {
    UIViewController *drawerController = self;
    while (drawerController) {
        if ([drawerController isKindOfClass:[ZJDrawerController class]]) {
            break;
        }
        drawerController = drawerController.parentViewController;
    }
    
    return (ZJDrawerController *)drawerController;
}

@end
