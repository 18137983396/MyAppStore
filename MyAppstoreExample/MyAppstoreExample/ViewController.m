//
//  ViewController.m
//  MyAppstoreExample
//
//  Created by 极光 on 2017/8/24.
//  Copyright © 2017年 jiguang. All rights reserved.
//

#import "ViewController.h"
#import "MyAppStore.h"

@interface ViewController ()<MyAppStoreDelegate>
@property (nonatomic, copy) NSString * productIdTmp;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self payStarAction];
}

- (void)payStarAction {
   
    _productIdTmp = @"1";
    //为了解决丢单问题，本地要写检测收据流程
    //本地检测是否有遗留的收据，如果有，则提示用户去继续去服务器验证收据
    
    //第一步骤
    [[MyAppStore shareMyAppStore] removeMyStoreObsever];
    [[MyAppStore shareMyAppStore] addMyStoreObserver];
    
    //第二步
    //请求服务器创建订单
    [[MyAppStore shareMyAppStore] startPayWithproductId:_productIdTmp];
    [MyAppStore shareMyAppStore].delegate = self;
}

#pragma mark - 内购代理回调
- (void)myPurchaseFailedAndError:(NSString *)error {
    //删除本地收据
}

- (void)myPurchaseSuccessTransaction:(SKPaymentTransaction *)transaction andReceiptData:(NSData *)receipt {
    
     NSString * receiptNewBase = [receipt base64EncodedStringWithOptions:0];
    //删除本地收据
    //在这里存入本地收据_可用writeFile方式等
    //为了防止丢单，验证收据由服务器去和苹果服务器验证
    //serverVerificationReceipt请求
    //成功_发放道具_删除本地收据
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
