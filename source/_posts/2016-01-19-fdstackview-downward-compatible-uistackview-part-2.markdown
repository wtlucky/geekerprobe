---
layout: post
title: "FDStackView —— Downward Compatible UIStackView (Part 2)"
date: 2016-01-19 14:44:53 +0800
comments: true
categories: [iOS development]
tags: iOS AutoLayout forkingdog 
---

写完了`Part 1`就被接踵而至的新项目和新版本忙的不可开交，转眼间一个季度就已经过去了，而这篇`Part 2`却迟迟还没有出现。实在是抱歉没有及时更新。不过有一个好消息就是`FDStackView`已经被使用在我们自己的项目中，并且我们的项目也已经经过了两个版本的迭代，`FDStackView`可以说还是相当稳定的，并且可以顺利的通过苹果的审核机制，对这方面有顾虑的小伙伴们可以放心大胆的使用了。同时我们也将它的版本号从`1.0-alpha`升级到`1.0`。在此感谢一下各位热心的小伙伴们在`Github`上提出的`issue`,以及着重感谢下[@里脊串](http://weibo.com/ljc1986?is_all=1)对`FDStackView`的重度使用及提出的各种隐晦的`bug`。后续我们将会对性能的优化做出改进，以及对`Layout Margins`的支持。

回到主题，这篇文章主要介绍`StackView`的实现，即如何通过现有`AutoLayout`技术实现`StackView`这样的一个控件。这里说明一下，当初我们编写`FDStackView`的时候，`UIStackView`还没有支持`Layout Margins`，所以我们也没有添加`Layout Margins`的支持，不过目前的`iOS SDK`已经增加了这一部分的支持，所以在打开`layoutMarginsRelativeArrangement`属性的情况下，`StackView`创建出的约束会与我后面所介绍的内容有一些出入，不过问题不大，仅仅是部分约束的`firstItem`由`StackView`本身变成`UILayoutGuide`的区别。

 实现`StackView`主要包括这几个技术点：

- **`alignment`和`distribution`的约束如何添加和管理；**
- **`spacing`和`distribution`的关系及约束的创建；**
- **子视图的隐藏显示如何处理；**
- **子视图的`intrinsicContentSize`发生变化时如何处理。**

<!-- More -->

> 我们对`UIStackView`进行了详细的研究，包括`dump`出所有`UIStackView`的相关私有类，各个类的方法，实例变量等。还需要添加符号断点来跟踪各个方法的调用顺序及各个实例变量的值得变化情况。同时还需要分析各个状态下`UIStackView`的约束`constraints`的情况，包括约束的个数，连接的方式，及约束所添加到的视图等。经过以上的各种分析之后，我们又通过在`IB`中借助`UIView`手动连接约束的方式，连出每一个`UIStackView`所对应的状态。经过这一番调查与研究我们已经大概摸清的`UIStackView`的工作原理与实现方式。

如上篇文章所说，在进行了详尽的研究之后，总结出大概需要攻克的是这几个技术点，以尽可能的与`UIStackView`的实现保持一致，在难以完成的地方通过自己的方式实现。在这之前先介绍一下我们使用到的几个私有类。

##### `CATransformLayer`
`StackView`是一个透明不可见的容器，主要就是因为这个`layer`，我们继承了它并重载了两个方法，`setOpaque:`和`setOpaque:`，用于避免产生警告⚠️。也就是项目中的`FDTransformLayer`。
##### `_UILayoutSpacer`
这是一个私有类，它的主要作用是用了辅助`StackView`创建`alignment`方向上的约束，它的父类是`UILayoutGuide`，并不是一个UIView的子类，所以我们并不能以熟悉的方式对它添加约束。但是在知道了它的作用之后，我们完全可以使用一个`UIView`来代替它，同时它也是不可见的，所以它的`layer`自然也是`FDTransformLayer`。这是项目中的`FDLayoutSpacer`。
##### `_UIOLAGapGuide`
与`_UILayoutSpacer`相同是`UILayoutGuide`的子类，用来辅助`distribution`方向上的约束创建，并且只有`UIStackViewDistributionEqualSpacing`和`UIStackViewDistributionEqualCentering`两种模式下它才会出现。在项目中我们通过`UIView`的子类`FDGapLayoutGuide`来实现它。
##### `_UILayoutArrangement`
同样是一个私有类，用来管理`StackView`及其子视图的约束的创建。它是一个父类，在`FDStackView`中我们使用`FDStackViewLayoutArrangement`来与之对应。
##### `_UIAlignedLayoutArrangement`
该类是`_UILayoutArrangement`的子类，用来控制`alignment`方向上的约束的创建及管理，它维护了一个`_UILayoutSpacer`并负责它的生命周期。在`FDStackView`中我们以更直接的`FDStackViewAlignmentLayoutArrangement`来对它命名。
##### `_UIOrderedLayoutArrangement`
与`_UIAlignedLayoutArrangement`相对，用来控制`distribution`方向上的约束创建及管理，它维护了一组`_UIOLAGapGuide`。在`FDStackView`中我们以更直接的`FDStackViewDistributionLayoutArrangement`来对它命名。

先提前解释几个后面会提到的名词：

- `canvas` ：`canvas`是什么？翻译过来是画布的意思，其实就是容器也就是`StackView`本身
- `Ambiguity Suppression` ：经常`Debug``AutoLayout`的同学可能对这个词并木陌生，一般约束产生冲突或者模棱两可的时候，控制台就会输出一组信息，其中就会包含这个词。这里就是抵制模棱两可的约束的意思。`StackView`中会创建一些低优先级的约束来完成这件事儿，以防止控制台打出`AutoLayout`异常的`log`。
- `minAttribute` ：是`NSLayoutAttribute`一个便捷获取方式，针对不同的`axis`会对应不同的`NSLayoutAttribute`，可能是`NSLayoutAttributeTop`也可能是`NSLayoutAttributeLeading`。
- `centerAttribute` :同样针对不同的`axis`可能是`NSLayoutAttributeCenterY`或者`NSLayoutAttributeCenterX`。
- `maxAttribute` :同样针对不同的`axis`可能是`NSLayoutAttributeBottom`或者`NSLayoutAttributeTrailing`。
- `dimensionAttribute` :同样针对不同的`axis`可能是`NSLayoutAttributeHeight`或者`NSLayoutAttributeWidth`。

{% codeblock FDStackViewAlignmentLayoutArrangement lang:objc %}
- (NSLayoutAttribute)minAttributeForCanvasConnections {
    return self.axis == UILayoutConstraintAxisHorizontal ? NSLayoutAttributeTop : NSLayoutAttributeLeading;
}

- (NSLayoutAttribute)centerAttributeForCanvasConnections {
    return self.axis == UILayoutConstraintAxisHorizontal ? NSLayoutAttributeCenterY : NSLayoutAttributeCenterX;
}

- (NSLayoutAttribute)maxAttributeForCanvasConnections {
    return self.axis == UILayoutConstraintAxisHorizontal ? NSLayoutAttributeBottom : NSLayoutAttributeTrailing;
}

- (NSLayoutAttribute)dimensionAttributeForCurrentAxis {
    return self.axis == UILayoutConstraintAxisHorizontal ? NSLayoutAttributeHeight : NSLayoutAttributeWidth;
}
{% endcodeblock %}

{% codeblock FDStackViewAlignmentLayoutArrangement lang:objc %}
- (NSLayoutAttribute)minAttributeForCanvasConnections {
    return self.axis == UILayoutConstraintAxisHorizontal ? NSLayoutAttributeLeading : NSLayoutAttributeTop;
}

- (NSLayoutAttribute)centerAttributeForCanvasConnections {
		return self.axis == UILayoutConstraintAxisHorizontal ? NSLayoutAttributeCenterY : NSLayoutAttributeCenterX;
}

- (NSLayoutAttribute)dimensionAttributeForCurrentAxis {
		return self.axis == UILayoutConstraintAxisHorizontal ? NSLayoutAttributeWidth : NSLayoutAttributeHeight;
}

- (NSLayoutAttribute)minAttributeForGapConstraint {
    return self.axis == UILayoutConstraintAxisHorizontal ? NSLayoutAttributeLeading : NSLayoutAttributeTop;
}
{% endcodeblock %}

此外`UIStackView`的约束的管理方式也十分的奇妙。除了一个例外的`Ambiguity Suppression`的约束，其余不管约束何种关系的约束都是add在`canvas`上的。既然约束都加在了`canvas`上，那这么多的约束如何区分何管理呢？

这里有个小技巧，那就是用`weakToWeak`的`NSMapTable`来管理，`key`是约束的`firstItem`,`value`是约束，而且因为`NSMapTable`是`weakToWeak`的，所以`key`和`value`所对应的`object`并不会增加引用计数，不会带来内存上的管理困难。若要找一个`view`所关联约束，直接取`view`作为`key`的`value`就可以了。`_UILayoutArrangement`维护了多个这样的`NSMapTable`，分别来管理不同作用的约束。不得不说这样的设计真的是太巧妙了。

================

### `alignment`和`distribution`的约束如何添加和管理
先给一张图看一下什么是`alignment`和`distribution`以及`Spacing`:

![image](https://developer.apple.com/library/prerelease/ios/documentation/UIKit/Reference/UIStackView_Class_Reference/Art/uistack_hero_2x.png)


在介绍实现之前，我先介绍一下`StackView`的各种`alignment`模式都是什么效果的：

- **UIStackViewAlignmentFill**：这种就是填充满整个`StackView`了，用得比较多。

![image](https://developer.apple.com/library/prerelease/ios/documentation/UIKit/Reference/UIStackView_Class_Reference/Art/align_fill_2x.png)


- **UIStackViewAlignmentLeading**：这种是左对齐。

![image](https://developer.apple.com/library/prerelease/ios/documentation/UIKit/Reference/UIStackView_Class_Reference/Art/align_leading_2x.png)


- **UIStackViewAlignmentTop**：这种是上部对齐。

![image](https://developer.apple.com/library/prerelease/ios/documentation/UIKit/Reference/UIStackView_Class_Reference/Art/align_top_2x.png)


- **UIStackViewAlignmentFirstBaseline**：这种是让`arrangedSubviews`按照`firstBaseline`对齐。只能出现在水平的`StackView`中。

![image](https://developer.apple.com/library/prerelease/ios/documentation/UIKit/Reference/UIStackView_Class_Reference/Art/align_firstbaseline_2x.png)


- **UIStackViewAlignmentCenter**：这种是居中对齐。

![image](https://developer.apple.com/library/prerelease/ios/documentation/UIKit/Reference/UIStackView_Class_Reference/Art/align_center_2x.png)


- **UIStackViewAlignmentTrailing**：这种是右部对齐。

![image](https://developer.apple.com/library/prerelease/ios/documentation/UIKit/Reference/UIStackView_Class_Reference/Art/align_leading%202_2x.png)


- **UIStackViewAlignmentBottom**：这种是底部对齐。

![image](https://developer.apple.com/library/prerelease/ios/documentation/UIKit/Reference/UIStackView_Class_Reference/Art/align_bottom_2x.png)


- **UIStackViewAlignmentLastBaseline**：这种是让`arrangedSubviews`按照`lastBaseline`对齐。同样只能出现在水平的`StackView`中。

![image](https://developer.apple.com/library/prerelease/ios/documentation/UIKit/Reference/UIStackView_Class_Reference/Art/align_lastbaseline_2x.png)


下面介绍实现，首先是`alignment`方向，`alignment`方向的约束主要包括4种
{% codeblock lang:objc %}
@interface FDStackViewAlignmentLayoutArrangement : FDStackViewLayoutArrangement
@property (nonatomic, strong) NSMutableArray<NSLayoutConstraint *> *canvasConnectionConstraints;
@property (nonatomic, strong) NSMapTable<UIView *, NSLayoutConstraint *> *hiddingDimensionConstraints;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMapTable *> *alignmentConstraints;
@end

@interface FDLayoutSpacer : UIView
@property (nonatomic, strong, readonly) NSMutableArray<NSLayoutConstraint *> *systemConstraints;
@end

{% endcodeblock %}

- **canvasConnectionConstraints**：它管理的是`arrangedSubviews`与`canvas`之间的约束；
- **hiddingDimensionConstraints**：它管理的是当`arrangedSubviews`有`hidden`的时候，该`arrangedSubview`的有关`dimensionAttribute`的约束；
- **systemConstraints**：它是由`_UILayoutSpacer`来管理的，它管理了spacer与`arrangedSubviews`之间的约束，因为这些约束的`firstItem`都是spacer自身，所以就不需要使用`NSMapTable`而直接是`NSArray`。另外spacer只有在`alignment`不是`UIStackViewAlignmentFill`的时候才会被创建，所以当`alignment`是`UIStackViewAlignmentFill`时，是没有`systemConstraints的`；
- **alignmentConstraints**：它管理的是`arrangedSubviews`之间的约束，它包括两组`NSMapTable`，根据`alignment`的不同具体的约束也不同，具体的`NSMapTable`的`key`与`alignment`及`axis`的关系如下表：

![image](http://i8.tietuku.com/0aca68eeda40a027.jpg)

可以看到除了`UIStackViewAlignmentFill`模式以外，都会有一个`Ambiguity Suppression`的key，这个key对应的`NSMapTable`的就管理了前面提到的那些低优先级防止布局时出现模棱两可状态的约束。此外`Baseline`相关的约束是只有在`axis`为`Horizontal`时才会有的，并且`UIStackViewAlignmentFirstBaseline`和`UIStackViewAlignmentTop`，`UIStackViewAlignmentLastBaseline`和`UIStackViewAlignmentBottom`的key值是相同的。

这个key的名字之所以这么取也是有讲究的，它代表着它所对应的`NSMapTable`管理的约束关系。举个例子：`axis`为`Horizontal`，`alignment`为`UIStackViewAlignmentFill`时，key为`Top`和`Bottom`，那么`Top`对应的`NSMapTable`管理的约束就是`arrangedSubviews`之间`NSLayoutAttributeTop`相等的约束。同理`Bottom`就是`NSLayoutAttributeBottom`相等的约束。

这样结合`alignment`的效果来看就很容易理解，`UIStackViewAlignmentFill`模式需要`arrangedSubviews`都充满容器，那么自然他们的`NSLayoutAttributeTop`和`NSLayoutAttributeBottom`需要都相等，而`UIStackViewAlignmentTop`模式需要`top`对齐那么只需要`NSLayoutAttributeTop`相等就OK了。

这里还有一个点就是`arrangedSubviews`之间的约束不是迭代添加的，而是都与第一个`arrangedSubview`创建关系。假设有3个`view`，那就是`view2`与`view1`建立约束，`view3`同样与`view1`建立约束而不是与`view2`迭代建立约束。

这4种约束的创建顺序是：

1. `FDLayoutSpacer的systemConstraints`
2. `canvasConnectionConstraints`
3. `alignmentConstraints`
4. `hiddingDimensionConstraints`

`FDLayoutSpacer的systemConstraints`在`FDStackViewAlignmentLayoutArrangement`中被称为`spanningLayoutGuideConstraints`，创建方法是
{% codeblock lang:objc %}
- (void)updateSpanningLayoutGuideConstraintsIfNecessary {
    if (self.mutableItems.count == 0) {
        return;
    }
    
    if (self.spanningLayoutGuide && self.spanningGuideConstraintsNeedUpdate) {
        [self.canvas removeConstraints:self.spanningLayoutGuide.systemConstraints];
        [self.spanningLayoutGuide.systemConstraints removeAllObjects];
        
        //FDSV-spanning-fit
        NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self.spanningLayoutGuide attribute:self.spanningLayoutGuide.isHorizontal ? NSLayoutAttributeWidth : NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:0];
        constraint.priority = 51;
        constraint.identifier = @"FDSV-spanning-fit";
        [self.canvas addConstraint:constraint];
        [self.spanningLayoutGuide.systemConstraints addObject:constraint];
        
        //FDSV-spanning-boundary
        [self.mutableItems enumerateObjectsUsingBlock:^(UIView *item, NSUInteger idx, BOOL *stop) {
            NSLayoutConstraint *minConstraint = [NSLayoutConstraint constraintWithItem:self.spanningLayoutGuide attribute:self.minAttributeForCanvasConnections relatedBy:[self layoutRelationForItemConnectionForAttribute:self.minAttributeForCanvasConnections] toItem:item attribute:self.minAttributeForCanvasConnections multiplier:1 constant:0];
            minConstraint.identifier = @"FDSV-spanning-boundary";
            minConstraint.priority = 999.5;
            [self.canvas addConstraint:minConstraint];
            [self.spanningLayoutGuide.systemConstraints addObject:minConstraint];
            
            NSLayoutConstraint *maxConstraint = [NSLayoutConstraint constraintWithItem:self.spanningLayoutGuide attribute:self.maxAttributeForCanvasConnections relatedBy:[self layoutRelationForItemConnectionForAttribute:self.maxAttributeForCanvasConnections] toItem:item attribute:self.maxAttributeForCanvasConnections multiplier:1 constant:0];
            maxConstraint.identifier = @"FDSV-spanning-boundary";
            maxConstraint.priority = 999.5;
            [self.canvas addConstraint:maxConstraint];
            [self.spanningLayoutGuide.systemConstraints addObject:maxConstraint];
        }];
    }
}
{% endcodeblock %}

首先判断一些不需要创建或者不需要更新这组约束的情况，比如之前提到的`alignment`为`UIStackViewAlignmentFill`或者没有`arrangedSubview`的时候。接下来创建一个宽或高为`0`的约束给spacer，因为对于后面添加的约束而言，spacer是缺少这样的一个约束以保证它能够正确布局。最后就是把每一个`arrangedSubview`与spacer分别建立`minAttribute`和`maxAttribute`的约束，这些约束的`constant`都是`0`，但是关系却不一定都是等于，需要根据`alignment`的属性不同来动态调整，有可能是大于等于，也有可能是小于等于。这需要查表来得到。

下一步创建`canvasConnectionConstraints`
{% codeblock lang:objc %}
- (void)updateCanvasConnectionConstraintsIfNecessary {
    if (self.mutableItems.count == 0) {
        return;
    }
    
    [self.canvas removeConstraints:self.canvasConnectionConstraints];
    [self.canvasConnectionConstraints removeAllObjects];
    
    NSArray<NSNumber *> *canvasAttributes = @[@(self.minAttributeForCanvasConnections), @(self.maxAttributeForCanvasConnections)];
    if (self.alignment == UIStackViewAlignmentCenter) {
        canvasAttributes = [canvasAttributes arrayByAddingObject:@(self.centerAttributeForCanvasConnections)];
    } else if (self.isBaselineAlignment) {
        NSLayoutConstraint *canvasFitConstraint = [NSLayoutConstraint constraintWithItem:self.canvas attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:0];
        canvasFitConstraint.identifier = @"FDSV-canvas-fit";
        canvasFitConstraint.priority = 49;
        [self.canvas addConstraint:canvasFitConstraint];
        [self.canvasConnectionConstraints addObject:canvasFitConstraint];
    }
    
    [canvasAttributes enumerateObjectsUsingBlock:^(NSNumber *canvasAttribute, NSUInteger idx, BOOL *stop) {
        NSLayoutAttribute attribute = canvasAttribute.integerValue;
        NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:[self viewOrGuideForLocationAttribute:attribute] attribute:attribute relatedBy:[self layoutRelationForCanvasConnectionForAttribute:attribute] toItem:self.canvas attribute:attribute multiplier:1 constant:0];
        constraint.identifier = @"FDSV-canvas-connection";
        [self.canvas addConstraint:constraint];
        [self.canvasConnectionConstraints addObject:constraint];
    }];
}
{% endcodeblock %}

因为这是`alignment`的`canvasConnectionConstraints`，所以只需关注它自己的`minAttribute`和`maxAttribute`两个方向与`canvas`的约束即可，其余两个方向会在`distributionLayoutArrangement`中创建。

特别的是如果`alignment`是`UIStackViewAlignmentCenter`的话需要加上一个`centerAttribute`的约束。如果是`alignment`是`baseline`相关的话还要给`canvas`添加一个高为`0`的低优先级约束，用来满足某些特殊情况下`canvas`约束不满足的情况。

具体与`canvas`建立约束关系的`firstItem`及`relation`关系是根据`alignment`类型以及`NSLayoutAttribute`的不同而不同的，情况比较多我就不一一列举了，同样是根据查表得到，具体可以看代码去查。

最后是`alignmentConstraints`和`hiddingDimensionConstraints`，虽然前面说它们两个的顺序是一前一后创建，但其实并不是，它们可以说是一起创建的，首先取出第一个`arrangedSubview`作为`guardView`，然后循环遍历其余`arrangedSubview`，先添加`alignmentConstraint`，如果这个`arrangedSubview`是`hidden`的那么就会再添加一个`hiddingDimensionConstraint`。
{% codeblock lang:objc %}
- (void)updateAlignmentItemsConstraintsIfNecessary {
    if (self.mutableItems.count == 0) {
        return;
    }
    
    [self.alignmentConstraints setObject:[NSMapTable weakToWeakObjectsMapTable] forKey:self.alignmentConstraintsFirstKey];
    [self.alignmentConstraints setObject:[NSMapTable weakToWeakObjectsMapTable] forKey:self.alignmentConstraintsSecondKey];
    [self.canvas removeConstraints:self.hiddingDimensionConstraints.fd_allObjects];
    [self.hiddingDimensionConstraints removeAllObjects];
    
    UIView *guardView = self.mutableItems.firstObject;
    [self.mutableItems enumerateObjectsUsingBlock:^(UIView *item, NSUInteger idx, BOOL *stop) {
        if (self.alignment != UIStackViewAlignmentFill) {
            NSLayoutConstraint *ambiguitySuppressionConstraint = [NSLayoutConstraint constraintWithItem:item attribute:self.alignmentConstraintsFirstAttribute relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:0];
            ambiguitySuppressionConstraint.identifier = @"FDSV-ambiguity-suppression";
            ambiguitySuppressionConstraint.priority = 25;
            [item addConstraint:ambiguitySuppressionConstraint];
            [self.alignmentConstraints[self.alignmentConstraintsFirstKey] setObject:ambiguitySuppressionConstraint forKey:item];
        } else {
            if (item != guardView) {
                NSLayoutConstraint *firstConstraint = [NSLayoutConstraint constraintWithItem:guardView attribute:self.alignmentConstraintsFirstAttribute relatedBy:NSLayoutRelationEqual toItem:item attribute:self.alignmentConstraintsFirstAttribute multiplier:1 constant:0];
                firstConstraint.identifier = @"FDSV-alignment";
                [self.canvas addConstraint:firstConstraint];
                [self.alignmentConstraints[self.alignmentConstraintsFirstKey] setObject:firstConstraint forKey:item];
            }
        }
        if (item != guardView) {
            NSLayoutConstraint *secondConstraint = [NSLayoutConstraint constraintWithItem:guardView attribute:self.alignmentConstraintsSecondAttribute relatedBy:NSLayoutRelationEqual toItem:item attribute:self.alignmentConstraintsSecondAttribute multiplier:1 constant:0];
            secondConstraint.identifier = @"FDSV-alignment";
            [self.canvas addConstraint:secondConstraint];
            [self.alignmentConstraints[self.alignmentConstraintsSecondKey] setObject:secondConstraint forKey:item];
        }
        if (item.hidden) {
            NSLayoutConstraint *hiddenConstraint = [NSLayoutConstraint constraintWithItem:item attribute:self.axis == UILayoutConstraintAxisHorizontal ? NSLayoutAttributeHeight : NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:0];
            hiddenConstraint.priority = [item contentCompressionResistancePriorityForAxis:self.axis == UILayoutConstraintAxisHorizontal ? UILayoutConstraintAxisVertical : UILayoutConstraintAxisHorizontal];
            hiddenConstraint.identifier = @"FDSV-hiding";
            [self.canvas addConstraint:hiddenConstraint];
            [self.hiddingDimensionConstraints setObject:hiddenConstraint forKey:item];
        }
    }];
}
{% endcodeblock %}

这里的`alignmentConstraint`的创建都是`guardView`与其余的`arrangedSubview`创建`relation`关系为**相等**的约束，而`NSLayoutAttribute`的选择仍然是查表法，根据`axis`和`alignment`的不同而选择不同的`NSLayoutAttribute`。

如果`alignment`不是`UIStackViewAlignmentFill`模式的话，就会给`arrangedSubview`创建一个`dimensionAttribute`为`0`的低优先级约束，称为`ambiguitySuppressionConstraint`放在上图中`key`为`Ambiguity Suppression`的`NSMapTable`中。

- - - - - - - - - 

现在解释一下[本文章`Part 1`](http://blog.wtlucky.com/blog/2015/10/09/fdstackview-downward-compatible-uistackview-part-1/)中最后提到的`UIStackView`当`alignment`为`UIStackViewAlignmentFill`时，最高视图隐藏掉，而其余视图没有变成第二个的视图的高度的`bug`。原因就是在`UIStackView`的中实现中`AlignmentLayoutArrangement`是没有管理`hiddingDimensionConstraints`的，所以当视图被隐藏了后，那个视图被添加了一个宽为`0`的约束，视觉上看不到了，但是高方向的约束仍然存在，所以仍然会撑开`StackView`，所以在`FDStackView`中我们在`alignment`方向上同时增加了`hiddingDimensionConstraints`，视图被`hidden`后，会在高度方向上也给他加上一个高`0`为的约束，而且这个优先级也很有讲究需要跟它的`contentCompressionResistancePriority`设为一样，这样才不会在`AutoLayout`布局系统中当用户人为添加一个高度约束后产生冲突。

写了这么多，才写完第一个技术点的第一部分，内容确实比较多，我写的也比较乱，时间比较紧所以写作时间是间断的，所以思维也是间断跳跃的，还麻烦各位看官多多包涵。本来打算一篇写完的，但是这么长，还是有必要在分一下的，`Part 2`就到这吧，其余的内容就在`Part 3`吧。