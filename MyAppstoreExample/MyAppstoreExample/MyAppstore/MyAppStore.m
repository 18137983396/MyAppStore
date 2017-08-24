//
//  MyAppStore.m
//  MyAppstoreExample
//
//  Created by 极光 on 2017/8/24.
//  Copyright © 2017年 jiguang. All rights reserved.
//

#import "MyAppStore.h"

@interface MyAppStore ()

@property (nonatomic, copy) NSString * productId;

@end

@implementation MyAppStore

static MyAppStore * appStoreIAP = nil;

+ (instancetype)shareMyAppStore {
    
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        appStoreIAP = [[MyAppStore alloc] init];
    });
    return appStoreIAP;
}

#pragma mark - 添加交易队列观察者

- (void)addMyStoreObserver {
    
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
}

#pragma mark - 移除交易队列观察者
- (void)removeMyStoreObsever {
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

#pragma  mark - 开始支付
- (void)startPayWithproductId:(NSString *)productId {
    
    self.productId = productId;
    
    if ([SKPaymentQueue canMakePayments]) {
        [self requestProducts:productId];
    } else {
        [self.delegate myPurchaseFailedAndError:@"用户不允许应用内支付。"];
    }
}

#pragma mark - 请求商品信息
- (void)requestProducts:(NSString *)productId {
    
    SKProductsRequest * productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:productId]];
    productsRequest.delegate = self;
    [productsRequest start];
}

#pragma mark - SKProductsRequestDelegate
- (void)requestDidFinish:(SKRequest *)request {
    
    NSLog(@"request finish: %@", request);
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    
    NSLog(@"request failed: %@", error);
    [self.delegate myPurchaseFailedAndError:@"请求失败，请稍后再试。"];
}

#pragma mark - appstore回调 请求商品信息回调
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    
    for (SKProduct * product in response.products) {
        NSLog(@"商品标题:%@",     product.localizedTitle);
        NSLog(@"商品价格:%@",     product.price);
        NSLog(@"商品描述:%@",     product.localizedDescription);
        NSLog(@"Product id:%@",  product.productIdentifier);
    }
    
    NSArray * products  = response.products;
    SKProduct * product = [products count] > 0 ? [response.products firstObject] : nil;
    if (product) {
        //添加付款请求到队列
        [[SKPaymentQueue defaultQueue] addPayment:[SKPayment paymentWithProduct:product]];
    } else {
        //无法获取商品信息
        [self.delegate myPurchaseFailedAndError:@"无效商品ID"];
    }
}

#pragma mark - appstore回调 付款请求回调
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transaction {
    
    for(SKPaymentTransaction * tran in transaction){
        switch (tran.transactionState) {
            case SKPaymentTransactionStatePurchasing:
                NSLog(@"正在购买中_");
                break;
            case SKPaymentTransactionStateDeferred:
                //NSLog(@"最终状态未确定_");
                break;
            case SKPaymentTransactionStateFailed:
                //NSLog(@"购买失败_");
//                [self failedTransaction:tran];
                break;
            case SKPaymentTransactionStatePurchased:
                NSLog(@"购买成功_");
//                [self completeTransaction:tran];
                break;
            case SKPaymentTransactionStateRestored:
                //NSLog(@"恢复购买_");
//                [self restoreTransaction:tran];
                break;
            default:
                break;
        }
    }
}

#pragma mark - 交易事务处理
//交易成功
- (void)completeTransaction:(SKPaymentTransaction *)transaction {
    
    NSData * receipt = [self receiptWithTransaction:transaction];
    if (receipt) {
        [self finishTransaction:transaction];
#warning 以下代码上线前记着注释掉
        //本地验证收据（首先去正式接口验证，如果返回21007则去沙盒地址验证收据）------测试代码
        //        [self localVerificationReceipt:[receipt base64EncodedStringWithOptions:0]];
        [self.delegate myPurchaseSuccessTransaction:transaction andReceiptData:receipt];
    }else {
        NSData * receipt = [self receiptWithTransaction:transaction];
        if (receipt) {
            [self finishTransaction:transaction];
            [self.delegate myPurchaseSuccessTransaction:transaction andReceiptData:receipt];
        }else {
            [self finishTransaction:transaction];
            [self.delegate myPurchaseFailedAndError:@"支付失败，请稍后再试。"];
        }
    }
}

//交易失败
- (void)failedTransaction:(SKPaymentTransaction *)transaction {
    
    [self finishTransaction:transaction];
    NSString * errorStr = @"支付取消";
    if (transaction.error.code != SKErrorPaymentCancelled) {
        errorStr = @"支付失败，请稍后再试。";
    }
    [self.delegate myPurchaseFailedAndError:errorStr];
}

//交易恢复
- (void)restoreTransaction:(SKPaymentTransaction *)transaction {
    
    [self finishTransaction:transaction];
}

//结束交易事务
- (void)finishTransaction:(SKPaymentTransaction *)transaction {
    
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

#pragma mark - 获取票据信息
- (NSData *)receiptWithTransaction:(SKPaymentTransaction *)transaction {
    
    NSData * receipt = nil;
    if ([[NSBundle mainBundle] respondsToSelector:@selector(appStoreReceiptURL)]) {
        NSURL * receiptUrl = [[NSBundle mainBundle] appStoreReceiptURL];
        receipt = [NSData dataWithContentsOfURL:receiptUrl];
    } else {
        if ([transaction respondsToSelector:@selector(transactionReceipt)]) {
            receipt = [transaction transactionReceipt];
        }
    }
    return receipt;
}

- (void)localVerificationReceipt:(NSString *)receipt {
    
    NSError * error;
    NSDictionary * requestContents = @{@"receipt-data" : receipt};
    NSData * requestData = [NSJSONSerialization dataWithJSONObject:requestContents options:0 error:&error];
    
    NSURL * storeURL = [NSURL URLWithString:@"https://buy.itunes.apple.com/verifyReceipt"];
    NSMutableURLRequest * storeRequest = [NSMutableURLRequest requestWithURL:storeURL];
    [storeRequest setHTTPMethod:@"POST"];
    [storeRequest setHTTPBody:requestData];
    
    NSOperationQueue * queue = [[NSOperationQueue alloc] init];
    [NSURLConnection sendAsynchronousRequest:storeRequest queue:queue completionHandler:^(NSURLResponse * response, NSData * data, NSError *connectionError) {
        if (connectionError) {
            /* ... Handle error ... */
        } else {
            NSError * error;
            NSDictionary * jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (!jsonResponse) {
                /* ... Handle error ...*/
            }
            //////NSLog(@"========*********** %@", jsonResponse);
            //=======具体查看官方文档=======
            //https://developer.apple.com/library/ios/releasenotes/General/ValidateAppStoreReceipt/Chapters/ValidateRemotely.html#//apple_ref/doc/uid/TP40010573-CH104-SW1
            if ([[jsonResponse valueForKey:@"status"] integerValue] == 21007 || [[jsonResponse valueForKey:@"status"] integerValue] == 21002) {
                
                NSURL * storeURL = [NSURL URLWithString:@"https://sandbox.itunes.apple.com/verifyReceipt"];
                NSMutableURLRequest * storeRequest = [NSMutableURLRequest requestWithURL:storeURL];
                [storeRequest setHTTPMethod:@"POST"];
                [storeRequest setHTTPBody:requestData];
                
                NSOperationQueue * queue = [[NSOperationQueue alloc] init];
                [NSURLConnection sendAsynchronousRequest:storeRequest queue:queue completionHandler:^(NSURLResponse * response, NSData * data, NSError * connectionError) {
                    if (connectionError) {
                        /* ... Handle error ... */
                    } else {
                        NSError * error;
                        NSDictionary * jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                        if (!jsonResponse) { /* ... Handle error ...*/ }
                        ////NSLog(@"======== %@", jsonResponse);
                        
                        if (jsonResponse) {
                            NSDictionary * receiptDict = [jsonResponse objectForKey:@"receipt"];
                            NSArray * in_app_arr = [receiptDict objectForKey:@"in_app"];
                            ////NSLog(@"====== %lu", (unsigned long)in_app_arr.count);
                        }
                        
                    }
                }];
            }
        }
    }];
}



@end
