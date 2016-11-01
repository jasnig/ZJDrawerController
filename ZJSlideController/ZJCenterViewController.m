//
//  ZJCenterViewController.m
//  ZJSlideController
//
//  Created by ZeroJ on 16/9/13.
//  Copyright © 2016年 ZeroJ. All rights reserved.
//

#import "ZJCenterViewController.h"
#import "ZJDrawerController.h"
@interface ZJCenterViewController ()

@end

@implementation ZJCenterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"%@ ---- didLoad",self);

    self.title = @"center";
    self.view.backgroundColor = [UIColor whiteColor];
    UIButton *leftbtn = [[UIButton alloc] initWithFrame:CGRectMake(200, 100, 44, 44)];
    [leftbtn setTitle:@"左边" forState:UIControlStateNormal];
    [leftbtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [leftbtn addTarget:self action:@selector(leftOnClick) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:leftbtn];
    
    UIButton *rightbtn = [[UIButton alloc] initWithFrame:CGRectMake(200, 100, 44, 44)];
    [rightbtn setTitle:@"右边" forState:UIControlStateNormal];
    [rightbtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [rightbtn addTarget:self action:@selector(rightOnClick) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:rightbtn];
//    [self exchangeCenterControllerViewMethod];

}

- (void)leftOnClick {
    [self.zj_drawerController slidingLeftDrawer];
}

- (void)rightOnClick {
//    [self.zj_slideController slidingRightDrawer];
    UIViewController *test = [UIViewController new];
    test.view.backgroundColor = [UIColor greenColor];
//    [self presentViewController:test animated:YES completion:nil];
    [self showViewController:test sender:nil];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSLog(@"%@ ---- willAppear",self);
//    [self.zj_slideController activeGestureOfCenterContentView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSLog(@"%@ ---- didAppear",self);
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    NSLog(@"%@ ---- willDisappear",self);
//    [self.zj_slideController disableGestureOfCenterContentView];
    
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    NSLog(@"%@ ---- didDisappear",self);
    
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
