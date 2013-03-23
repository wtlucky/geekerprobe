---
layout: post
title: "23种设计模式——单例模式"
date: 2013-03-19 19:35
comments: true
categories: [Design Pattern]
tags: iOS block GCD Design
---

本学期开了一门课程叫做《软件体系结构》，讲的主要是设计模式的东西，而我在之前也看过设计模式的书，正好借此机会来整理一下自己所学到的知识，因为自己在做`iOS`开发，所以基本上这23种设计模式我都通过`objective-C`来实现了。此系列文章的类图都是来自[《设计模式之禅》](http://book.douban.com/subject/4260618/)，有兴趣的同学可以去买这本书看。

话说，在编码编到一定的程度以后，由于代码体系的庞大，结构的复杂，自然就会上升到设计模式高度，而现在的软件设计又基本都是面向对象的，所以有了设计模式作支持，可以使软件更加的稳定安全，也更易于维护与拓展。

首先来介绍最常用最简单的单例模式（Singleton），在以后的文章中再依次介绍其他的模式。

####单例模式定义####

`Ensure a class has only one instance, and provide a global point of access to it. (确保某一个类只有一个实例，而且自行实例化并向整个系统提供这个实例。)`

<!-- More -->

####单例模式类图####

{% img http://picturemapstore.bcs.duapp.com/2013/03/singleton.jpg %}

####单例模式介绍####

单例模式确保在一个应用中只产生一个实例，这是很有必要的，因为在我们做软件设计的时候，有很多对象都是只需要一个就可以了，而不需要创建众多的对象，这样最显而易见的就是节省了内存空间。而且避免了这个类的频繁的初始化与销毁。有时为了实现某一种功能与操作而创建的类（工具类）往往也不需要多个对象，使用单例模式再合适不过。再延伸一点，有时为了节省内存对一个对象进行复用的话也可以通过单例来实现，这在手机软件的开发中用得比较多，因为手机的内存实在是少得可怜。

####单例模式优点####

1. 正如前面说的，单例模式在内存中只有一个实例，减少了内存开支。特别是一个对象需要频繁的创建、销毁时，而创建与销毁的性能有无法优化，单例模式的优势就非常明显。
2. 单例模式只生成一个实例，减少了系统性能开销，当一个对象的产生需要比较多的资源时，如读取配置、产生其他依赖对象时，则可以通过在应用启动时直接产生一个单例对象，然后永久驻留内存的方式来解决。
3. 单例模式可以避免对资源的多重占用。
4. 单例模式可以在系统设置全局的访问点，优化和共享资源访问。

####单例模式缺点####

1. 单例模式一般没有接口，扩展很困难，除了修改代码基本上没有第二种途径实现。
2. 单例模式对测试是不利的。在并行开发环境中，如果单例模式没有完成，是不能进行测试的。
3. 单例模式与单一职责原则有冲突。

####单例模式在iOS中的使用####

单例模式在`iOS`开发中的使用还是蛮多的，许多`Foundation`、`Cocoa`和`UIKit`中的类都实现了单例模式，比如应用程序本身`UIApplication`、文件操作类`NSFileManager`、消息中心`NSNotificitonCenter`等系统都已经给我们实现单例，我们只需要使用就好了。在`iOS`中使用单例模式要使用类方法，通过类方法返回该类的唯一对象。

我知道的在`iOS`开发中实现单例模式主要有以下三种方式：

#####第一种#####
该方法是苹果的官方文档中写的一种方式，通过覆盖`NSObject`的部分方法实现，使该类无法`alloc`、`retain`、`release`。这是最麻烦的一种方法，也是最不好的一种方法。
{% codeblock Singleton lang:objc %}
static Singleton *instance = nil;
 
+ (Singleton *)sharedInstance
{
    if (instance == nil) {
        instance = [[super allocWithZone:NULL] init];
    }
    return instance;
}
 
+ (id)allocWithZone:(NSZone *)zone
{
    return [[self sharedInstance] retain];
}
 
- (id)copyWithZone:(NSZone *)zone
{
    return self;
}
 
- (id)retain
{
    return self;
}
 
- (NSUInteger)retainCount
{
    return NSUIntegerMax;  //denotes an object that cannot be released
}
 
- (void)release
{
    //do nothing
}
 
- (id)autorelease
{
    return self;
}
{% endcodeblock %}

可以看到这种方式，使用静态成员维持了一个永久存在的对象，而且覆盖了`alloc`方法（`alloc`方法会调用`allocWithZone:`方法），并且也覆盖了所有与引用技术有关的方法，这都使这个对象不会被销毁。这样看上去基本实现了我们需要的，但是写起来麻烦不说，还有很大的一个问题，那就是多线程问题，如果是在多线程中那么该种方法就不能保证只产生一个对象了。所以这种方式只是介绍一下，并不推荐使用。

#####第二种#####
第二种跟第一种差不多，也是通过覆盖`NSObject`的方法实现的，但是它在第一种的基础上增加了多线程的处理，所以即使在多线程下，该种方法创建的对象也是唯一的。这种方法已经有大牛为我们写好了，全都都是通过`C`的宏定义`#define`出来了。现给出该头文件：
{% include_code designPattern/SynthesizeSingleton.h lang:c %}
使用时也非常方便，该头文件也已给出使用方法，在这里我在说一下，供那些E文不好的同学使用。

使用这种方式首先把该头文件加到我们的项目中，然后直接使用就可以了：
{% codeblock Singleton.h lang:objc %}
#import <Foundation/Foundation.h>
#import "SynthesizeSingleton.h"

@interface Singleton : NSObject

SYNTHESIZE_SINGLETON_FOR_CLASS_HEADER(Singleton);

//定义该类的属性，方法等

@end
{% endcodeblock %}

{% codeblock Singleton.m lang:objc %}
@implementation Singleton

SYNTHESIZE_SINGLETON_FOR_CLASS(Singleton);

//属性方法的实现

@end
{% endcodeblock %}

如此一来在使用时，通过`[Singleton sharedInstance]`就可以获得该类的单例对象了。
这种方法由于有了这个头文件的支持，所以使得使用单例方便多了，而且也避免了多线程的问题。

#####第三种#####
这是最后一种也是我最推荐的一种。`iOS`在4.0以后推出了`block`和`GCD`，这两个特性给`iOS`开发带来的很大的便利，也使开发变得更加趣味话。那么如何通过`GCD`+`block`来实现单例模式呢，这主要归功于`dispatch_once(dispatch_once_t *predicate, ^(void)block)`这个`GCD`的函数，他有两个参数第一参数是一个指向`dispatch_once_t`类型结构体的指针，用来测试`block`是否执行完成，该指针所指向的结构体必须是全局的或者静态的，第二个参数是一个返回值与参数均为空的`block`，在`block`体中进行对象的初始化即可。`dispatch_once`在程序的生命周期中保证只会被调用一次，所以在多线程中也不会有问题。
该种方法使用方法：
{% codeblock Singleton lang:objc %}
+ (Singleton *)sharedInstance
{
    static Singleton *instance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[Singleton alloc]init];
    });
    
    return instance;
}
{% endcodeblock %}

使用该种方法只需要这简单的几句代码就可以实现单例了。使用起来非常方便，但是这种创建单例的方法也不是完美的，它并不能阻止人们通过`alloc`方法来实例化一个对象，所以这并不是严格意义上的单例模式，但是一般程序都是我们自己写，我们自己记得就好了，这也没什么可担心的，从这一点上来说第二种方法又是比较好的，具体使用的时候呢，根据实际情况来吧，各取所需就好了。