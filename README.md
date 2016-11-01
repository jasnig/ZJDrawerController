# ZJDrawerController

一个使用方便的侧滑测单, 抽屉菜单, 支持四种打开和关闭的动画, 支持缩放, 可以设置打开的手势的位置, 可以设置在那些页面可以打开抽屉菜单

![drawer1.gif](http://upload-images.jianshu.io/upload_images/1271831-6766ab3ea92d787c.gif?imageMogr2/auto-orient/strip)


![drawer2.gif](http://upload-images.jianshu.io/upload_images/1271831-cab8b7bafe5dd255.gif?imageMogr2/auto-orient/strip)


```
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    ZJLeftViewController *left = [ZJLeftViewController new];
    
    ZJCenterViewController *center = [ZJCenterViewController new];
    
    UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:center];
    
    ZJRightViewController *right = [ZJRightViewController new];
    
    ZJDrawerController *drawer = [[ZJDrawerController alloc] initWithLeftController: left centerController:navi rightController:right];
    
    // 背景图片
    drawer.backgroundImage = [UIImage imageNamed:@"1"];
    // 动画类型
    drawer.drawerControllerStyle = ZJDrawerControllerStyleParallaxSlide;
    // 任何界面都能打开抽屉
    drawer.canOpenDrawerAtAnyPage = YES;
    //...
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor whiteColor];
    self.window.rootViewController = drawer;
    [self.window makeKeyAndVisible];
    
    return YES;
}
```
