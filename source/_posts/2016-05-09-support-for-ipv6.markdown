---
layout: post
title: "Support for IPv6"
date: 2016-05-09 15:41:22 +0800
comments: true
categories: [iOS development]
tags: iOS
---

苹果于2016年5月4日告知开发者应用需要在6月1日前支持IPv6-only,也就是说在 6 月 1 日后发布的新版本是需要支持 IPv6-only。 
 
原文地址：[https://developer.apple.com/news/?id=05042016a](https://developer.apple.com/news/?id=05042016a)

首先看下图

![image](https://developer.apple.com/library/ios/documentation/NetworkingInternetWeb/Conceptual/NetworkingOverview/art/NetworkingFrameworksAndAPIs_2x.png)
 
其中蓝色部分的高级API，其实都已经帮我们做好了IPv6的支持，我们使用的大多数第三方网络库也都是基于这些高级API的，所以这里我们不需要做什么改动。
需要注意的是下面的红色部分的底层的socket API需要做出适配支持。

<!-- More -->
 
## 适配支持方案

- 不要使用硬编码的IPv4的地址，取而代之应该使用域名;
- 搜一下是否有用到下面的这些API，这些API都是只针对IPv4做处理的，删除掉就可以：
 > - inet_addr()
 > - inet_aton()
 > - inet_lnaof()
 > - inet_makeaddr()
 > - inet_netof()
 > - inet_network()
 > - inet_ntoa()
 > - inet_ntoa_r()
 > - bindresvport()
 > - getipv4sourcefilter()
 > - setipv4sourcefilter()
- 如果项目中用到了以下的IPv4的类型，那么也要支持相应的IPv6类型

 ![Image](http://i2.buimg.com/bf442d424debe2fa.jpg)
  
-  如果强制需要使用IPv4的地址，苹果官方的适配方法给出了解决方式。[Use System APIs to Synthesize IPv6 Addresses](https://developer.apple.com/library/ios/documentation/NetworkingInternetWeb/Conceptual/NetworkingOverview/UnderstandingandPreparingfortheIPv6Transition/UnderstandingandPreparingfortheIPv6Transition.html )
 
## 适配支持验证方法

测试验证方式就是通过Mac的共享网络共享一个IPv6的无线网，跟已往创建方式不同的是进入共享时需要按住`Option`键，不然`Create NAT64 Network`的选项不会出现

![image](http://i4.buimg.com/ae223a48f5345f80.jpg)

然后开启无线共享，使iPhone连接上分享出来的热点即可
注：需要将iPhone的蜂窝网络数据关掉，以保证只有通过WiFi在连接网络。


## 适配经验

在自己的项目中检查了一下，需要做出修改的都是集中在网路库的`Reachability`相关操作中。如`AFNetworking`的`AFNetworkReachabilityManager`，它已经支持了IPv6，但是在他的支持中加了个一个条件编译的选项，判断了系统的版本，一直不明白它这么做的原因是什么，因此我也提交了一个[issue](https://github.com/AFNetworking/AFNetworking/issues/3498)询问了下，等待大神给出解释。

> **UPDATE：2016年05月11日：**
> 
> 后来发现`Reachability`在iOS9以下的系统上如果适配了IPv6的话则会导致失效，网络监测状态不准，应该是苹果自身的bug，所以在这些系统上还需要使用IPv4的数据结构，`AFNetworking`的大神也对我的[issue](https://github.com/AFNetworking/AFNetworking/issues/3498)给出了解答，同时在`Alamofire`中也有对这个bug描述的[issue](https://github.com/Alamofire/Alamofire/issues/1228)。


除此之外，我们自己也用到了一个`Reachability`的类似物，这就需要对它单独做出IPv6的支持，具体方法可以参照`Apple`自己官方提供的[`Reachability`Demo](https://developer.apple.com/library/ios/samplecode/Reachability/Listings/Reachability_Reachability_h.html)，这个Demo中的ReadMe中也介绍了一些很有用的信息。

> ##### IPv6 Support
> 
> Reachability fully supports IPv6.  More specifically, each of the APIs handles IPv6 in the following way:
> 
> - reachabilityWithHostName and SCNetworkReachabilityCreateWithName:  Internally, this API works be resolving the host name to a set of IP addresses (this can be any combination of IPv4 and IPv6 addresses) and establishing separate monitors on all available addresses.
> 
> - reachabilityWithAddress and SCNetworkReachabilityCreateWithAddress:  To monitor an IPv6 address, simply pass in an IPv6 `sockaddr_in6 struct` instead of the IPv4 `sockaddr_in struct`.
> 
> - reachabilityForInternetConnection:  This monitors the address 0.0.0.0, which reachability treats as a special token that causes it to actually monitor the general routing status of the device, both IPv4 and IPv6.
> 
> 
> ##### Removal of reachabilityForLocalWiFi
> 
> Older versions of this sample included the method reachabilityForLocalWiFi. As originally designed, this method allowed apps using Bonjour to check the status of "local only" Wi-Fi (Wi-Fi without a connection to the larger internet) to determine whether or not they should advertise or browse. 
> 
> However, the additional peer-to-peer APIs that have since been added to iOS and OS X have rendered it largely obsolete.  Because of the narrow use case for this API and the large potential for misuse, reachabilityForLocalWiFi has been removed from Reachability.
> 
> Apps that have a specific requirement can use reachabilityWithAddress to monitor IN_LINKLOCALNETNUM (that is, 169.254.0.0).  
> 
> Note: ONLY apps that have a specific requirement should be monitoring IN_LINKLOCALNETNUM.  For the overwhelming majority of apps, monitoring this address is unnecessary and potentially harmful.

————————————

![Image](http://i4.buimg.com/ccadbd99b4316844.jpg)