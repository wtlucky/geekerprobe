---
layout: post
title: "一个特殊的iPhone6 Plus适配问题"
date: 2015-01-29 21:13
comments: true
categories: [iOS development]
tags: iOS AutoLayout SizeClasses
---

最近项目在搞适配，目前的适配原则是不改变既有的设计图的设计样式，使用`@3x`的图片去进行完美适配。即不涉及到某一个模块在`iPhone5`及以下的设备上是一个展示样式，在`iPhone6`或着`iPhone6 Plus`上是另外的一个展示样式。单纯是这样的需求通过`Auto Resizing`和`AutoLayout`就完全可以应付的了。以前硬编码写的view的frame通过乘上一个屏幕放大的比例系数也可以搞定。

可是目前设计同学提出在一个使用`collection view`的页面中，之前是通过各种设备使用同一个大小的`cell`，不同的屏幕上拉大的是`cell`之间的间距来进行适配。现如今要改成只有在`6 Plus`上要将`cell`上半部分等比例放大，`cell`中下半部分的文字的字号也放大。目前的需求就是这个样子，其实我觉得这样适配就不是苹果的设计规范，按道理说屏幕大了看的内容多才对，这样搞个等比例放大，跟没有适配在兼容模式下运行的效果似地。不过需求来了还是得搞。

<!-- More -->

这个`cell`本来就是使用`AutoLayout`做的，但是之前是定高定宽的，图片的宽度被限制死了，即使是在`collocation view`的代理方法中将`cell`设大，`cell`的图片也不会变大。而且还需要把字体一并放大，以及图片左上和右下的两个图片的位置是要成比例设置的，这样之前设置的`heading space` 和 `trailing space`是固定值，也不能达到要求。先来看一下这个`cell`，因为项目的保密性我没有展示全部的内容，只是列举了一部分，但足以说明问题。

{% img http://i13.tietuku.com/f775dffce0a50a8b.jpg %}

因为使用的是`xcode6`，苹果提供了`Size Classes`这样强大的一个功能，为的是制作`adaptive UI`。就是只制作一套UI，但是可以适配多个屏幕尺寸以及选装方向，之前没有仔细研究过这个新特性，只是觉得他应该能应付当前的需求，因为使用它可以为每一种`size`设置一套`constraint`和字体大小。很好很强大！

但是当开始使用时发现，没有一个`size`是能够单独区分出`6 Plus`的`portrait`模式的，到时能区分出`landscape`模式。`6 Plus`的`portrait`模式使用的是`Regular height`和`Compact width`，其他的设备的`portrait`模式使用的也是`Regular height`和`Compact width`。但是`Any height`和`Compact width`这个`size`对应的是`6 Plus`以外其他设备的`portrait`和`landscape`模式。如图所示，

{% img http://i13.tietuku.com/aeca38ae1498eb0b.jpg %}

这里正好不包括`6 Plus`，分别设置了这两种`size`发现不是预期的效果，所有的手机都使用了`Regular height`和`Compact width`的这个`size`。后来有看见了这个优先级的表格，

{% img http://i13.tietuku.com/2dcd34dae7d1d8bb.jpg %}

一旦设置了这个`size`那么就会优先加载这个`size`，所以这条路目前是行不通的，我觉得一定有其他的方法来通过`Size Classes`解决，或者通过代码修改优先级，或者使用某种方法标识`6 Plus`。由于我时间比较紧急，所以就没有继续使用这种方式，有知道的大神求告知啊，感激不尽！

`Size Classes`行不通，又想了其他两种方案，一个是为`6 Plus`单独制作一个xib，让collection view在`6 Plus`上加载这个xib上的`cell`；另外一个是修改现有的`cell`上的`constraints`把固定图片的大小`constraint`干掉搞成自适应的，自适应不了的`constraint`通过`IBOutlet`在代码中进行修改。权衡了一下这两个方案，第一个目前的工作量比较小，但是后期维护很恶心，而且这种做法实在是太low。而第二种虽然开始开上去很复杂，工作量很大，但是搞定之后，维护修改起来也容易很多，毕竟只有一个UI。

所以选择第二种开工，自适应很好搞，把最大的那个圆圈与父view的`heading`和`trailing`设为`0`即可，难的是等比例，虽然用`AutoLayout`有几个月了但是用得都是`heading`、`trailing`、`vertical`、`horizontal`、`top`、`bottom` 还有`width`和`height`这几个`constraint`，他们就能解决我之前遇到的所有布局问题，连`alignment`的那几个`constraint`我都很少使用。但是这次需要用到`Aspect ratio`了，之前一直不知道这咋用，感谢这次需求让我知道了如何用他，最大的那个圆圈是正方形设置了左右间距就确定了宽度，而高度的确定就用`Aspect ratio`设置为`1:1`即可，同样圆圈左上和右下的图也是需要等比例放大的，他们的比例也是通过`Aspect ratio`来设置，这里的比例按照设计图写一下即可。这里发现`xcode`一个很奇怪的问题，就是按住`ctrl`从一个view拖向另外一个view选择`Aspect ratio`的时候，`xcode`为你生成的是一个view的`height`与另一个view的`width`的比，这个我一直不是很理解，虽然如果你在设置`Aspect ratio`之前把他们的`frame`设为正确的话，生成的比例是正确的，但是这样真的很奇怪，可读性特别差，为什么要一个高比上另外一个的宽呢？我承认我数学学的不好，这里可能有其他的深刻含义，但是我觉得好奇怪，如果有人知道欢迎留言评论！所以这里我又手动的把一个view的`height`改为`width`，即宽比上宽，按照设计图修改一下比例。还有一个问题是圆圈的左上有右下的view的位置是要相应改变的，也是按照比例，设置固定的值肯定是不行的，因为值也是会变得，这里再次感谢这个需求，让我又一次加深的`AutoLayout`的理解，`AutoLayout`中的约束其实是一个二元一次方程，如图所示

{% img http://i13.tietuku.com/d6877a02ea1a04f3.jpg %}

`First item = Second item * Multiplier + Constant`，
一个值是可以通过另外一个值通过这个方程式计算出来的，而我们所加的约束就是设置了`Multiplier`和`Constant`，再加上优先级，两者的属性（上下左右宽高等）以及两者的关系（大于小于等于），这些共同组成了一个`constraint`。 xcode默认创建的`constraint`的`Multiplier`为`1`，我之前使用的所有`constraint`也都是使用的是`1`，从没有改变过他，从方程式来看这里是可以按比例设置的。不得不说`AutoLayout`真的很强大，自己用到的仅仅是冰山一角。

那圆圈右下角的view举例子，首先设置他的x轴距离，据父view一个是`heading`一个是`trailing`，因为父view的`heading`是`0`，无论`Multiplier`设置什么相乘都是零，所以只能用`trailing`，因为我们事先已经按照设计图将一个尺寸的界面拼出来了，当设置了`trailing`之后，`xcode`生成了一个`Multiplier`为`1`，`Constant`为一个固定值的`constraint`，这样不对，不能够按比例移动x轴位置，所以我们把`Constant`设为`0`，由公式算出`Multiplier`为`First item / Second item`并进行设置。确定了x方向的位置还需要y方向的位置，y这里又出现了另外一个坑，y方向父view的`top`为`0`不能这是比例，`bottom`由于有`Label`所以`bottom`的值是不确定的，所以就不能与父view做约束了，只能选择与圆圈做约束，这里使用的是`align bottom`。同理因为是按比例放大，这个`constraint`也不能使用定值，所以`Constant`设为`0`，公式算出`Multiplier`并设置。同样圆圈左上的view也这样设置即可。如此一来`cell`上半部分等比例放大的问题就搞定了。

`cell`下半部分`Label`之间的间距这个是不能自适应的，`6 Plus`和其他设备是两个不同的值，这样就只能把他们的`constraint`拿到代码中去进行修改，label上字体也是只能在代码中`cell`第一次加载时判断为`6 Plus`就将他们的字体放大。将这一部分逻辑放在了`aweakFromNib`中

{% codeblock lang:objc %}
- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (fequal(ScreenWidth, 414.0f)) {
        self.titleLabel.font = [UIFont systemFontOfSize:16.0f];
        self.memberNumLabel.font = [UIFont systemFontOfSize:15.0f];
        self.infoLabel.font = [UIFont systemFontOfSize:13.0f];
        
        self.icoTopConstraint.constant = 8.0f;
        self.nameTopConstraint.constant = 33.0f;
        self.memberCountTopConstraint.constant = 7.0f;
        self.infoTopConstraint.constant = 10.0f;
    }
}
{% endcodeblock %}

这里要说一下，判断`6 Plus`不能通过设备号去判断,`iPhone7,1`和`iPhone7,2`虽然是`iPhone6`和`iPhone6 Plus`没错，但是我们是在渲染界面，`iPhone6`和`iPhone6 Plus`是有一个放大模式的，在放大模式下`iPhone6 Plus`的屏幕尺寸是`iPhone6`的，`iPhone6`的屏幕尺寸是`iPhone5`的，所以如果通过设备号去判读那么渲染出来就是错误的，正确的方式是通过屏幕的尺寸来判断即`[UIScreen mainScreen].bounds.size`。

-----
写的很乱，因为是当天搞的，当天就记录下来，怕以后忘了，文笔不好，就凑合看吧，最后总结一下：

1. `Size Classes`还有待研究，如何区分出`iPhone6 Plus`
2. 学会了使用`Aspect ratio`，用于标记一个view的宽高比或者两个view的宽高比
3. 在`AutoLayout`中使用`Multiplier`进行数值成比例改变的需求
4. 在界面布局是不要使用设备号进行判别，要使用屏幕尺寸进行判断


##参考资料##

>[Adaptivity and Layout][1]

>[Size Classes Design Help][2]

>[ADAPTIVE LAYOUTS FOR iPHONE 6][3]

[1]: https://developer.apple.com/library/ios/documentation/UserExperience/Conceptual/MobileHIG/LayoutandAppearance.html
[2]: https://developer.apple.com/library/ios/recipes/xcode_help-IB_adaptive_sizes/_index.html#//apple_ref/doc/uid/TP40014436
[3]: http://mathewsanders.com/designing-adaptive-layouts-for-iphone-6-plus
