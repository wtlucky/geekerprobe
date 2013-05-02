---
layout: post
title: "苹果禁止使用UDID的解决方案"
date: 2013-03-23 16:42
comments: true
categories: [iOS development]
tags: iOS
---

`UDID`之前在`iOS`开发中广泛使用的一串字符串，用来标示唯一的设备，它本身并不包含用户信息，但是广告商却可以利用他获取到个人信息，从而发送广告，因为他涉及到隐私问题，所以苹果早在2011年就提出了将不再使用它。然而就在前天，苹果的开发者网站，发出新闻：
>Starting May 1, the App Store will no longer accept new apps or app updates that access UDIDs. Please update your apps and servers to associate users with the Vendor or Advertising identifiers introduced in iOS 6. You can find more details in the [UIDevice Class Reference](https://developer.apple.com/library/ios/#documentation/uikit/reference/UIDevice_Class/DeprecationAppendix/AppendixADeprecatedAPI.html).

“自5月1日起，App Store将不再接受任何使用UDID的app，苹果建议开发者转用iOS 6 引进的Vendor 或者 Adverstising Identifier（‘广告标识符’）”
这次苹果打出了强制通知，再使用`UDID`的话，那么应用将不会审核通过，也就无法发布。

不过俗话说的好“上有政策，下有对策”。虽然苹果自己也给出了替代的方法，但他们都不是最好的，`UUID`每次获取都不同，所以使用时必须要把他们存文件，存数据库或者存`UserDefault`。当应用被删除重装，那么这个`UUID`也就不同了。`Vendor`更是同一个设备上的同一个开发商的应用的`id`都是相同的，也没有办法使用。`Advertising identifier`也并不是固定的。那要如何才能达到我们的需求呢，既能方便获取又能保证唯一呢？

<!-- More -->

答案就是`MAC`地址，`MAC`地址在网络上用来区分设备的唯一性，接入网络的设备都有一个`MAC`地址，他们肯定都是不同的，是唯一的。一部`iPhone`上可能有多个`MAC`地址，包括`WIFI`的、`SIM`的等，但是`iTouch`和`iPad`上就有一个`WIFI`的，因此只需获取`WIFI`的`MAC`地址就好了，也就是`en0`的地址。直接把`MAC`地址拿出来使用是不安全的，因此对他们做一次`hash`计算，`MD5`就是一种哈希算法，对得到的`MAC`地址计算一下他的`MD5`值就好了，那么这样拿到的就是这个设备唯一的`ID`了。有时我们为了区分设备上的应用，也可以获取到应用的`bundleID`，在和`MAC`地址结合起来计算一下`MD5`，那么该值就是可以区分设备上应用的ID了。

首先是`MD5`，为`NSString`添加`MD5`方法：
{% codeblock NSString+MD5 lang:objc %}
//
//  NSString+MD5.h
//
//  Created by wtlucky on 12-12-2.
//
//

#import <Foundation/Foundation.h>

@interface NSString (MD5)

- (NSString *)MD5;
+ (NSString *)MD5ByAStr:(NSString *)aSourceStr;

@end

#import <CommonCrypto/CommonDigest.h>

@implementation NSString (MD5)

- (NSString *)MD5
{
    return [NSString MD5ByAStr:self];
}

+ (NSString *)MD5ByAStr:(NSString *)aSourceStr
{
    const char* cStr = [aSourceStr UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, strlen(cStr), result);
    
    NSMutableString *ret = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i ++)
    {
        [ret appendFormat:@"%02x",result[i]];
    }
    
    return ret;
}

@end
{% endcodeblock %}

接下来是获得唯一ID，为`UIDevice`添加方法：
{% codeblock UIDevice+UniqueIdentifier lang:objc %}
//
//  UIDevice+UniqueIdentifier.h
//
//  Created by wtlucky on 13-3-22.
//  Copyright (c) 2013年 AlphaStudio. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIDevice (UniqueIdentifier)

/**
 *	返回针对与一个应用的唯一ID
 *
 *	@return	针对与一个应用的唯一ID
 */
- (NSString *)uniqueDeviceIdentifier;


/**
 *	返回设备的唯一ID
 *
 *	@return	设备的唯一ID
 */
- (NSString *)uniqueGlobalDeviceIdentifier;


@end

#import "NSString+MD5.h"

#include <sys/socket.h> 
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>

@interface UIDevice (private)

- (NSString *)macAddress;

@end

@implementation UIDevice (UniqueIdentifier)

- (NSString *)macAddress
{
    int                 mib[6];
    size_t              len;
    char                *buf;
    unsigned char       *ptr;
    struct if_msghdr    *ifm;
    struct sockaddr_dl  *sdl;
    
    mib[0] = CTL_NET;
    mib[1] = AF_ROUTE;
    mib[2] = 0;
    mib[3] = AF_LINK;
    mib[4] = NET_RT_IFLIST;
    
    if ((mib[5] = if_nametoindex("en0")) == 0) {
        printf("Error: if_nametoindex error\n");
        return NULL;
    }
    
    if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0) {
        printf("Error: sysctl, take 1\n");
        return NULL;
    }
    
    if ((buf = malloc(len)) == NULL) {
        printf("Could not allocate memory. error!\n");
        return NULL;
    }
    
    if (sysctl(mib, 6, buf, &len, NULL, 0) < 0) {
        printf("Error: sysctl, take 2");
        free(buf);
        return NULL;
    }
    
    ifm = (struct if_msghdr *)buf;
    sdl = (struct sockaddr_dl *)(ifm + 1);
    ptr = (unsigned char *)LLADDR(sdl);
    NSString *outstring = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X",
                           *ptr, *(ptr+1), *(ptr+2), *(ptr+3), *(ptr+4), *(ptr+5)];
    free(buf);
    
    return outstring;
}

- (NSString *)uniqueDeviceIdentifier
{
    NSString *macAddress = [[UIDevice currentDevice] macAddress];
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    
    NSString *stringToHash = [NSString stringWithFormat:@"%@%@", macAddress, bundleIdentifier];
    NSString *uniqueIdentifier = [stringToHash MD5];
    
    return uniqueIdentifier;
}

- (NSString *)uniqueGlobalDeviceIdentifier
{
    NSString *macAddress = [[UIDevice currentDevice] macAddress];
    
    NSString *uniqueGlobalIdentifier = [macAddress MD5];
    
    return uniqueGlobalIdentifier;
}

@end
{% endcodeblock %}

如此一来，在使用时就相当方便了。