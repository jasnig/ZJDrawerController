//
//  ZJLeftViewController.m
//  ZJSlideController
//
//  Created by ZeroJ on 16/9/13.
//  Copyright © 2016年 ZeroJ. All rights reserved.
//

#import "ZJLeftViewController.h"
#import "ZJDrawerController.h"
@interface ZJLeftViewController ()<UITableViewDelegate, UITableViewDataSource>
@property (strong, nonatomic) UITableView *tableView;
@end

@implementation ZJLeftViewController


- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.rowHeight = 44.0f;
        _tableView.backgroundColor = [UIColor clearColor];
    }
    return _tableView;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 10;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *const kCellID = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellID];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellID];
    }
    cell.textLabel.text = [NSString stringWithFormat:@"这是第%ld行", (long)indexPath.row];
    cell.contentView.backgroundColor = [UIColor clearColor];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UIViewController *new = [UIViewController new];
    if (indexPath.row %2 == 0) {
        new.view.backgroundColor = [UIColor greenColor];
    }
    else {
        new.view.backgroundColor = [UIColor blueColor];

    }
    
    [self.zj_drawerController setupNewCenterViewController:new closeDrawer:NO finishHandler:^(BOOL finished) {
        NSLog(@"切换完成");
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.tableView];
    NSLog(@"%@ ---- didLoad",self);
}

- (void)viewWillLayoutSubviews {
    CGRect frame = CGRectMake(0.0f, 200.0f, self.view.bounds.size.width, self.view.bounds.size.height - 200.0f);

    self.tableView.frame = frame;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSLog(@"%@ ---- willAppear",self);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSLog(@"%@ ---- didAppear",self);

}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    NSLog(@"%@ ---- willDisappear",self);

}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    NSLog(@"%@ ---- didDisappear",self);

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
