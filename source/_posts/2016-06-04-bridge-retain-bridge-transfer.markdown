---
layout: post
title: "__bridge_retain __bridge_transfer"
date: 2016-06-04 16:34:46 +0800
comments: true
categories: [iOS development]
tags: iOS
---

### CF对象与NS对象互转

在ARC下，如果我们需要操作一些底层的库，有时会用到Core Foundation的对象，简称CF对象，例如Core Graphic、Core Text。在ARC下，这些CF的对象的内存是不会被自动管理的，而是需要我们在它的生命周期结束的时候调用CFRelease()释放它。

CF对象与NS对象之间如何相互转换呢？系统提供了__bridge,__bridge_retained,__bridge_transfer 三个关键字给我们使用。

<!-- More -->

#### __bridge

__bridge只是单纯的对象类型的转换，并没有涉及到对象所有权的转移，所以需要把握好对象的生命周期，否则会出项野指针的情况。

{% codeblock lang:objc %}
void *p = 0;
do {
    id obj = [[UIActivity alloc] init];
    p = (__bridge void *)obj;  // 出了作用域，obj被释放。
} while (0);
{
    id foo = [NSObject new];  // 为了切实将释放的内存被占用。
}
NSLog(@"class=%@", [(__bridge id)p class]);  // p为野指针，crash
{% endcodeblock %}

![image](http://i3.buimg.com/4dab14936f590b88.jpg)

NS对象转为CF对象会出项野指针，逆过来CF转NS对象则有可能会出现内存泄露的问题，具体见下面的__bridge_transfer的介绍。简单来说__bridge就是类型强制转换。


#### __bridge_retained

__bridge_retained用于将NS对象转为CF对象，这其中有所有权的转移，NS对象会被retain一次再交给CF处理，这样即使原始的NS的对象在被ARC自动处理release一次之后，它的retainCount也不会为0，从而不会被销毁。

{% codeblock lang:objc %}
void *p = 0;
do {
    id obj = [[UIActivity alloc] init];
    p = (__bridge_retained void *)obj;  // 出了作用域，obj被释放。p同时也有了所有权’

} while (0);
{
    id foo = [NSObject new];  // 为了切实将释放的内存被占用。
}
NSLog(@"class=%@", [(__bridge id)p class]);  // 正确打印UIActivity
{% endcodeblock %}

看一下引用计数的变化

{% codeblock lang:objc %}
NSString *foo = [[NSString alloc] init];
NSLog(@"%lu", CFGetRetainCount((__bridge CFTypeRef)foo)); // 1152921504606846975
CFTypeRef rfoo = (__bridge_retained CFTypeRef)foo;
NSLog(@"%lu", CFGetRetainCount(rfoo)); // 1152921504606846975
{% endcodeblock %}

可以看到引用计数是一个超级大的整数，这是因为在arc下直接创建的Foundation对象的引用计数都被处理过了，无法看到具体的数值。

这一操作系统给我们提供了一个内联函数来干这件事CFBridgingRetain，

{% codeblock lang:objc %}
NS_INLINE CF_RETURNS_RETAINED CFTypeRef __nullable CFBridgingRetain(id __nullable X) {
    return (__bridge_retained CFTypeRef)X;
}
{% endcodeblock %}


#### __bridge_transfer

__bridge_transfer用于将CF对象转为NS对象，同样的这其中也有所有权的转移，CF对象会在转换为NS对象后进行一次release操作，即把所有权完全移交给NS对象来处理，看一下引用计数的变化：

{% codeblock lang:objc %}
CFStringRef ref = CFStringCreateMutable(kCFAllocatorDefault, 0);
NSLog(@"%lu", CFGetRetainCount(ref)); // 1
        
NSString *string = (__bridge_transfer NSString *)ref;
NSLog(@"%lu", CFGetRetainCount(ref));  // 1
NSLog(@"%lu", CFGetRetainCount((__bridge CFTypeRef)string)); // 1
{% endcodeblock %}

这里的对象是由Core Foundation创建的，所以它的引用计数可以被打印出来，可以看到在ARC环境下，string会被声明成strong类型，所以这个对象的retainCount会被加1，但是转换之后仍然为1，即CF对象已经放弃了它的所有权。

如果是__bridge的话

{% codeblock lang:objc %}
CFStringRef ref = CFStringCreateMutable(kCFAllocatorDefault, 0);
NSLog(@"%lu", CFGetRetainCount(ref)); // 1
        
NSString *string = (__bridge NSString *)ref;
NSLog(@"%lu", CFGetRetainCount(ref));  // 2
NSLog(@"%lu", CFGetRetainCount((__bridge CFTypeRef)string)); // 2
{% endcodeblock %}

转换之后的引用计数是2，即CF和NS对象同时有着持有权，这样在出了当前的作用域后，ARC会自动给NS对象做release，但是CF对象需要手动调用CFRelease()，如果忘记了的话，那就是内存泄露。

同样，这一操作系统给也我们提供了一个内联函数来干这件事CFBridgingRetain，
{% codeblock lang:objc %}
NS_INLINE id __nullable CFBridgingRelease(CFTypeRef CF_CONSUMED __nullable X) {
    return (__bridge_transfer id)X;
}
{% endcodeblock %}

### 总结
这其中的关系可以用下图来直接说明，记住这张图就可以了：

![Image](http://i4.buimg.com/bb1f63613160279c.jpg)

————————————

![Image](http://i4.buimg.com/ccadbd99b4316844.jpg)
