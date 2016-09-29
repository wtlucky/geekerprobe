---
layout: post
title: "慎用SafeKit类似物"
date: 2016-04-24 21:06:13 +0800
comments: true
categories: [iOS development]
tags: iOS
---

SafeKit一般指那些被用来防止App crash的类库或者方案，常见的方式有通过`method swizzling`替换系统方法，或者通过消息转发机制将无法响应的方法都转发给一个可以handle任何消息的对象身上等。通过这些方式都可以将·常见数组越界、`unrecognized selector sent to instante 0xXXXXXXXX`等crash类型在App内部自身得到消化处理，从而将程序的crash率降到一个可以接受的范围内。

在我刚刚开始写Objective-C代码的时候，觉得这是一种非常好的编程方式，应该大力推崇，能够极大地降低crash率，想怎么写代码就怎么写代码，妈妈再也不担心我的程序会crash了。**但是**，后来渐渐发现这并不是一种很好的解决方案，它其实是一把双刃剑。在给我们带来便利的同时也给我们带来了一些不利的地方。这就是本次讨论的主题`慎用或者不用SafeKit类似物`。

<!-- More -->

SateKit的实现一般都是借助于Objective-C的runtime特性，但是这样实现起来就会很黑，也就是我们常说的**黑魔法**，**黑魔法**往往能给我们带来意想不到的效果，但是这样一来就将一些本该在程序的编译期就该发现的问题给滞后到了程序的运行时，甚至将本该暴露的问题而隐藏了起来。这种方式其实被我们称为`埋车头`的方案，发生了错误，没有响应机制，而是将事故车头埋藏起来，对外表现出一切良好。如此看来这种方式是我们万万不可取的，长期下去，只会产出越来越多的不稳定代码，代码中的问题不能及时暴露出来，久而久之成为编码习惯，后果可想而知。

最近工作中还遇到了一件与使用SafeKit相关的事儿，着实是踩了个坑，拿出来分享下。具体情况是这样，有一个宿主程序，他接收各个业务方以SDK的方式提供给它的静态库以供其正常运行。而我负责开发其中的一个SDK，在开发完成之后也通过了宿主程序接入验证，并由QA验证交付给宿主方后。却得到了宿主方QA的反馈说我们页面展示有问题，无数据展示。这怎么可能呢，在我们自己这里好好的，也自己接入宿主程序验证过，没有任何问题。要来宿主方的测试ipa，安装后发现确实有问题，通过抓包发现有数据请求也有正确数据返回，但是就是页面数据无法展示，真是见了鬼。只好同他们的RD要来最新的宿主程序，测试发现在新的宿主程序上确实有问题，但是老的宿主程序就没有问题，同样的是一份代码，问题肯定就出现在宿主程序上。

虽然明确知道问题出在宿主程序上，但是人家是大爷，你是不能让人家去查找修复问题的，只能用宿主程序和自己的SDK代码去Debug了，最后发现在数据解析时，见鬼了。
{% codeblock lang:objc %}
NSArray *path = @[@“this”, @“is”, @“path”, @“string”];
path = [path valueForKeyPath:NSStringFromSelector(@selector(capitalizedString))];
NSLog(@“%@”, path); // [<NSNull null>, <NSNull null>, <NSNull null>, <NSNull null>]
{% endcodeblock %}
我取首字母转大写的string，最后怎么给我一堆`NSNull`对象，也正是因为导致我数据解析失败。`KVC`返回`NSNull`，难道是我用错了？那我就不用`one line of code`，使用另外的方式试试：
{% codeblock lang:objc %}
NSArray *path = @[@“this”, @“is”, @“path”, @“string”];
NSMutableArray *paths = [NSMutableArray arrayWithCapacity:path.count];
[path enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
	NSString *str = [obj capitalizedString];
	[paths addObject:str];
}];
NSLog(@“%@”, paths); // [@“This”, @“Is”, @“Path”, @“String”]
{% endcodeblock %}

这样是正确ok的，那说明我的`KVC`没有用错啊，难道是宿主方把`KVC`禁用掉了，或者是给黑掉了？联系对方RD检查宿主工程，说没有禁用`valueForKeyPath:`，没有找到相关代码，他们自身也在用（自身也在用都没有发现问题么？我觉得随便在宿主工程里建个VC，写个KVC都是会返回NSNull的）。还是那句话人家是大爷，只能自己SDK方修改，去掉这里的`KVC`。其实我们的SDK中大量使用了`valueForKeyPath: `，只修改这一处肯定是不行的，其他地方同样会出问题，果然第二天，他们又发现的其他的问题，经确认还是`KVC`返回`NSNull`的问题。

总不能把所有的`KVC`都给改掉？最后强烈要求对方去排查，自己也通过增加符号断点`-[NSObject valueForKeyPath:]`追查，并未发现任何异常，看来只能是在runtime里干事儿了。最终宿主方通过逐个排除SDK的方式，发现问题就出在另一个业务方的SDK上。

我猜他们一定是使用了SafeKit类似的东西，将`valueForKeyPath: `进行了处理，写一段伪码大概就是：
{% codeblock lang:objc %}
- (id)fd_valueForKeyPath:(NSString *)keyPath {
	if (![keyPath isSafe]) { // 一些安全性检查
		return [NSNull null];
	}
	return [self fd_valueForKeyPath:keyPath];
}
{% endcodeblock %}
所以要么是`method swizzling`替换了实现，要么是通过`category`重写覆盖了原始的系统方法。

所以回到主题上来，SafeKit这种东西还是慎用或者别用的好，一方面把本应该暴露出的问题给隐藏了起来，这会导致开发者过于依赖SafeKit，没有了它，代码的质量将急剧下降。另一方面，如果你的代码还会融入到其他的工程中去的话，例如产品自身是一个SDK，那么使用SafeKit或者runtime Hook了系统方法，那么带来的将是毁灭性的灾难。因为这对使用你SDK的宿主方的开发带来极大的不变。因为这是侵染性的处理方式，不仅仅是在你自己的SDK中SafeKit会起作用，同样的在整个宿主App内都会起作用。如此一来不出问题还好，一旦出了问题，那排查起来简直让人崩溃。

————————————

![](https://oac67o3cg.qnssl.com/1475114982.png )
