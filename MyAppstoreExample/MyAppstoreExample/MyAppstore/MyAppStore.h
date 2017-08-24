//
//  MyAppStore.h
//  MyAppstoreExample
//
//  Created by 极光 on 2017/8/24.
//  Copyright © 2017年 jiguang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@protocol MyAppStoreDelegate <NSObject>

- (void)myPurchaseFailedAndError:(NSString *)error;

- (void)myPurchaseSuccessTransaction:(SKPaymentTransaction *)transaction andReceiptData:(NSData *)receipt;

@end

@interface MyAppStore : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver>

@property (nonatomic, weak) id<MyAppStoreDelegate>delegate;


+ (instancetype)shareMyAppStore;

/**
 *  添加通知
 */
- (void)addMyStoreObserver;

/**
 *  开始支付
 *
 *  @param productId 商品ID
 */

- (void)startPayWithproductId:(NSString *)productId;

/**
 *  移除通知
 */
- (void)removeMyStoreObsever;

@end
