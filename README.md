# MyAppStore
封装苹果内购，仅仅两句代码就能完成内购。

//第一步骤
[[MyAppStore shareMyAppStore] removeMyStoreObsever];
[[MyAppStore shareMyAppStore] addMyStoreObserver];

//第二步
//请求服务器创建订单
[[MyAppStore shareMyAppStore] startPayWithproductId:_productIdTmp];
[MyAppStore shareMyAppStore].delegate = self;
