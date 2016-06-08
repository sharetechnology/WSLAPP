//
//  wslCategoryDetailViewController.m
//  壁纸
//
//  Created by qianfeng on 15/10/11.
//  Copyright (c) 2015年 WSL. All rights reserved.
//
#import "AppDelegate.h"

#import "wslCategoryDetailViewController.h"
#import "AFNetworking.h"
#import "UIImageView+WebCache.h"
#import "SVPullToRefresh.h"
#import "JGProgressHUD.h"

#import "wslCustomCollectionViewCell.h"
#import "wslPicDetailViewController.h"


@interface wslCategoryDetailViewController ()<UICollectionViewDataSource,UICollectionViewDelegate>
{
    int _limitCount;
}
@property (nonatomic,strong) UICollectionView *collectionView;
@property (nonatomic, strong) UIButton * toTopBtn ;
@property (nonatomic, strong) JGProgressHUD   *progressHUD;

@property(nonatomic,strong) NSMutableArray * picturesArray;
@property(nonatomic,strong) NSMutableArray * picIdArr;

@end

@implementation wslCategoryDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
     [self setupUI];
}
-(void)setupUI
{    self.automaticallyAdjustsScrollViewInsets = NO;
    _limitCount = 30;
    self.view.backgroundColor =  [UIColor colorWithRed:255/255.0f green:192/255.0f blue:0/255.0f alpha:1.0f];
    [self.view  addSubview:self.collectionView];
    [self downloadPictureData];
    [self.view   addSubview:self.toTopBtn];
    [self  addRightSwipGesture:self.collectionView];
    //避免强强循环引用self --> block -->self
    __weak wslCategoryDetailViewController * weakSelf = self;
    [self.collectionView addPullToRefreshWithActionHandler:^{
        [weakSelf downloadPictureData];
    }];
    [self.collectionView.pullToRefreshView setTitle:@"正在努力加载中..." forState:SVPullToRefreshStateLoading];
    // 当滚动到底部的时候会触发block(加载更多)
    [self.collectionView addInfiniteScrollingWithActionHandler:^{
        [weakSelf downloadPictureData];
    }];
    
    // 显示HUD 菊花状等待
    CGRect rect = [[UIScreen mainScreen] bounds];
    rect.origin.y -= 50;
    [self.progressHUD showInRect:rect inView:self.view animated:YES];


}
//添加手势返回上一界面
-(void)addRightSwipGesture:(UIView *)view{
    UISwipeGestureRecognizer *swip = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swip:)];
    swip.direction = UISwipeGestureRecognizerDirectionRight;
    [view addGestureRecognizer:swip];
}
-(void)swip:(UISwipeGestureRecognizer *)swipe
{
    [self.navigationController popViewControllerAnimated:YES];
}
#pragma mark ---- downloadPictureData
-(void)downloadPictureData
{
    AFHTTPSessionManager * manager = [AFHTTPSessionManager manager];
   
    NSString * urlStr = [NSString stringWithFormat:@"http://service.picasso.adesk.com/v1/wallpaper/category/%@/wallpaper?order=new&adult=false&first=1&limit=%d",self.categoryID,_limitCount];
    [manager GET:urlStr parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        
        NSArray * picArray = responseObject[@"res"][@"wallpaper"];
        for (int i = _limitCount - 30 ; i < picArray.count ; i++) {
            [self.picturesArray addObject: picArray[i][@"img"]];
            [self.picIdArr addObject:picArray[i][@"id"]];
        }
        
        //让下拉刷新的控件停掉
        [self.collectionView.pullToRefreshView stopAnimating];
        //让加载更多动画停掉
        [self.collectionView.infiniteScrollingView  stopAnimating];
        //隐藏HUD
        [self.progressHUD dismissAnimated:YES];

        _limitCount += 30;
        [self.collectionView  reloadData];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"error %@",error);
    }];
}
#pragma mark  --- UICollectionViewDataSource
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.picturesArray.count;
}
-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    wslCustomCollectionViewCell * item  = [collectionView dequeueReusableCellWithReuseIdentifier:@"itemID" forIndexPath:indexPath];
    [item.imageView  sd_setImageWithURL:[NSURL URLWithString:self.picturesArray[indexPath.item]] placeholderImage:[UIImage imageNamed:@"head"]];
    return item;
}
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    wslPicDetailViewController * picDetailVc = [[wslPicDetailViewController alloc] init];
    AppDelegate * dele = [UIApplication sharedApplication].delegate;
    picDetailVc.imgUrlStr = self.picturesArray[indexPath.row];
    picDetailVc.imgID = self.picIdArr[indexPath.row];
    [dele.rootNavc pushViewController:picDetailVc animated:YES];
}
-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGPoint  point  = scrollView.contentOffset;
    if ( point.y > self.view.frame.size.height- 158) {
        self.toTopBtn.hidden = NO;
    }else
    {
        self.toTopBtn.hidden = YES;
    }
}

#pragma mark ---- Getter
-(UICollectionView *)collectionView
{
    if(_collectionView == nil){
        UICollectionViewFlowLayout * flow = [[UICollectionViewFlowLayout alloc] init];
        flow.itemSize = CGSizeMake((self.view.frame.size.width - 30) /2.0, 150);
        flow.sectionInset = UIEdgeInsetsMake(0, 10, 0, 10);
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 70, self.view.frame.size.width,  self.view.frame.size.height-70) collectionViewLayout:flow];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.backgroundColor =    [UIColor colorWithRed:255/255.0f green:192/255.0f blue:0/255.0f alpha:1.0f];
        _collectionView.scrollEnabled = YES;
        //注册UICollectionViewcell
        [_collectionView  registerNib:[UINib nibWithNibName:@"wslCustomCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"itemID"];
    }
    return _collectionView;
}
-(UIButton *)toTopBtn
{
    if (_toTopBtn == nil) {
        
        _toTopBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 80, self.view.frame.size.height - 75, 75, 55)];
        [_toTopBtn setTitle:@"返回顶部" forState:UIControlStateNormal];
        [_toTopBtn setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
        [_toTopBtn  addTarget:self action:@selector(scrollToTopClick) forControlEvents:UIControlEventTouchUpInside];
        _toTopBtn.hidden =YES;
        
    }return _toTopBtn;
}
-(void)scrollToTopClick
{
    self.collectionView.contentOffset = CGPointMake(0, 0) ;
    self.toTopBtn.hidden = YES;
}

- (JGProgressHUD *)progressHUD
{
    if (_progressHUD == nil) {
        _progressHUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleLight];
        _progressHUD.textLabel.text = @"龙哥帮你加载数据...";
    }
    
    return _progressHUD;
}

-(NSMutableArray *)picturesArray
{
    if (_picturesArray == nil) {
        _picturesArray = [[NSMutableArray alloc] init];
    }return _picturesArray;
}
-(NSMutableArray *)picIdArr
{
    if (_picIdArr == nil) {
        _picIdArr = [[NSMutableArray alloc] init];
    }return _picIdArr;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = NO;
}
-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.hidden = YES;
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
