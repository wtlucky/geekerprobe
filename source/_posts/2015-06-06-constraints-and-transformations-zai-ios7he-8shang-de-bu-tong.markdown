---
layout: post
title: "Constraints &amp; Transformations 在iOS7和8上的不同"
date: 2015-06-06 09:03
comments: true
categories: [iOS development]
tags: iOS AutoLayout
---

使用`AutoLayout`时，在`iOS7`和`iOS8`上两者会有很大的不同，`iOS8`苹果优化了很多。最近看了一篇`bolg`，是`Reveal`的工程师写的介绍使用`Constraints`以及`transform`变幻之后在`iOS78`上的异同。<!-- More -->

[原文链接](http://revealapp.com/blog/constraints-and-transforms.html)


***************

先贴张图说明一下问题:

{% img http://i3.piimg.com/1cebfcf0129ca844.png %}

可以看到`iOS7`在使用了`autolayout`之后，进行`transform`变幻之后`view`并没有达到预期效果，而在`iOS8`和和纯`frame`布局的情况下是正常的。

`autolayout`使用的是`Top`和`leading`与灰色的`view`进行约束，而`frame`是通过`setCenter`来设置位置的。

这种错误的现象会发生在`iOS7`及以前的版本中，在`iOS8`之后得到了修复。

通过`Reveal`查看可以看到:

{% img http://i3.piimg.com/dc322ed71cc0d21b.png %}

使用`autolayout`的`view`跟他的参照`View`相比只移动了`（-10，-10）`,而且它的布局位置也发生了偏移`（10，10）`，在`iOS8`下查看，会发现布局位置并没有移动，跟参照`View`完全一致

{% img http://i3.piimg.com/9274b80b9704dc37.png %}

由此可以得到的结论就是，在`iOS7`和`8`上使用`autolayout`布局的`view`的`center`属性的位置发生了改变。

通过设置断点和重写`setFrame`和`setCenter`方法研究发现，在`iOS7`和`8`上`setFrame`方法都没有被`UIKit`调用到，而只有`setCenter`方法被调用。

>“If the transform property is not the identity transform, the value of this property is undefined and therefore should be ignored.”  
                           ————UIView's Class Reference

如果`transform`属性不是`identity`的，那么他的值就是不确定的而且应该被忽略。因此可以断定`setFrame`方法没有没调用，因而`view`的`transform`属性也就不是`identity`的，所以会出现问题。

至于具体的`iOS7`和`8`在`NSISLayoutEngine`里面做了什么改变，可以查看[博客原文](http://revealapp.com/blog/constraints-and-transforms.html)。

最后说一下结论：如果我们的`app`是使用`iOS8`或者以后的`SDK`编译链接的并且还要支持`iOS7`，并在没有`identity`的`transform`的`view`上使用了`AutoLayout`。那么就应该注意一下几点：

1. 如果只使用旋转和缩放的`transform`变换，那么就要使用`CenterX/CenterY`约束，来替代`Top/Bottom/Left/Right/Trailing/Leading`约束，因为如果`transform`的`view`是通过它的`centre`布局的话，那么结果就有可能是正确的。
2. 将要变换的`view`放到一个`containerView`里，然后用约束约束`containerView`好过直接约束变换的`view`。变换的`view`可以直接用代码布局，也可以用`CentreX/CenterY`约束。但是使用等宽等高与`containerView`建立约束将不会达到预期效果
3. 不要使用`constraint`来约束这些`View`，使用`autosizingMask`，然后设置这些`View`的`translatesAutoresizingMaskIntoConstraints`为`YES`。

************


PS:
最后算是做个广告吧，[`Reveal`](http://revealapp.com/)这个工具真的是很`NB`很好用，当你使用了之后就会爱不释手。它可以查看`view`的层级关系，动态的改变`UI`属性，在最近的版本还支持对`autolayout`的支持，可以查看`constraints`已经对他们进行修改，我们做`iOS`开发的更多的是做界面开发工作，那么有了这样一个神器在手，那么必然会达到事半功倍的效果，工欲善其事，必先利其器！

`Reveal`还能做更NB的事情就是当你手机越狱后，然后你就可以查看任何`app`的视图层级关系了。就说到这里了，至于接下来怎样大家自己脑补吧。

既然这个工具这么强大，我们还是支持一下作者吧，同为开发者，都知道这行挺不容易的还是支持下正版吧，好消息是Reveal对中国的开发者们有个特惠价格：`RMB249`就可以拿下了，[购买地址](http://item.taobao.com/item.htm?spm=a230r.1.14.1.kpBX7S&id=45630069705&ns=1&abbucket=4#detail)，比半价还优惠，我在知道这个消息后第一时间拿下了它，因为之前的价格确实有点贵，对我来说还是有压力的。


————————————

![Image](http://i4.buimg.com/ccadbd99b4316844.jpg)