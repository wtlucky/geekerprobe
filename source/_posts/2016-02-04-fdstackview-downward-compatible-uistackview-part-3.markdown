---
layout: post
title: "FDStackView —— Downward Compatible UIStackView (Part 3)"
date: 2016-02-04 15:24:55 +0800
comments: true
categories: [iOS development]
tags: iOS AutoLayout forkingdog
---

上一篇[`Part 2`](http://blog.wtlucky.com/blog/2016/01/19/fdstackview-downward-compatible-uistackview-part-2/)只介绍了第一个技术点**`alignment`和`distribution`的约束如何添加和管理**的`alignment`这一部分的内容，这一篇继续介绍`distribution`的约束添加和管理。

同样的在介绍实现之前，我先介绍一下`StackView`的各种`distribution`模式都是什么效果的：

<!-- More -->

- **UIStackViewDistributionFill**：这种应该是目前最常用的了，它就是将`arrangedSubviews`填充满整个`StackView`，如果设置了spacing，那么这些`arrangedSubviews`之间的间距就是spacing。如果减去所有的spacing，所有的`arrangedSubview`的固有尺寸(`intrinsicContentSize`)不能填满或者超出`StackView`的尺寸，那就会按照`Hugging`或者`CompressionResistance`的优先级来拉伸或压缩一些`arrangedSubview`。如果出现优先级相同的情况，就按排列顺序来拉伸或压缩。

![image](https://docs-assets.developer.apple.com/published/82128953f6/distribute_fillroportionally_2x_4a83cd74-be8d-4ef1-adf9-c5252a1bcc65.png)


- **UIStackViewDistributionFillEqually**：这种就是`StackView`的尺寸减去所有的spacing之后均分给`arrangedSubviews`，每个`arrangedSubview`的尺寸是相同的。

![image](https://docs-assets.developer.apple.com/published/82128953f6/distribute_fillequally_2x_5ccda608-869a-48b9-9515-9b6314d091a9.png)


- **UIStackViewDistributionFillProportionally**：这种跟FillEqually差不多，只不过这个不是讲尺寸均分给`arrangedSubviews`，而是根据`arrangedSubviews`的`intrinsicContentSize`按比例分配。

![image](https://docs-assets.developer.apple.com/published/82128953f6/distribute_fillroportionally_2x_4a83cd74-be8d-4ef1-adf9-c5252a1bcc65.png)


- **UIStackViewDistributionEqualSpacing**：这种是使`arrangedSubview`之间的spacing相等，但是这个spacing是有可能大于`StackView`所设置的spacing，但是绝对不会小于。这个类型的布局可以这样理解，先按所有的`arrangedSubview`的`intrinsicContentSize`布局，然后余下的空间均分为spacing，如果大约`StackView`设置的spacing那这样就OK了，如果小于就按照`StackView`设置的spacing，然后按照`CompressionResistance`的优先级来压缩一个`arrangedSubview`。

![image](https://docs-assets.developer.apple.com/published/82128953f6/distribute_equalspacing_2x_6668568b-a445-402c-94ae-f5e85b0b10bd.png)


- **UIStackViewDistributionEqualCentering**：这种是使`arrangedSubview`的中心点之间的距离相等，这样没两个`arrangedSubview`之间的spacing就有可能不是相等的，但是这个spacing仍然是大于等于`StackView`设置的spacing的，不会是小于。这个类型布局仍然是如果`StackView`有多余的空间会均分给`arrangedSubviews`之间的spacing，如果空间不够那就按照`CompressionResistance`的优先级压缩`arrangedSubview`。

![image](https://docs-assets.developer.apple.com/published/82128953f6/distribute_equalcentering_2x_7089d0d3-f161-452b-ab3e-9885c7b6101e.png)


在介绍`distribution`的约束创建和管理的过程中也涉及到了第二个知识点**`spacing`和`distribution`的关系及约束的创建**的内容，所以这两部都在这里介绍了。

`distribution`方向同样也包括4种约束，这4种约束也都是添加到`canvas`上的，除此之外它还包括一组通过`NSMapTable`维护的`FDGapLayoutGuide`。

{% codeblock lang:objc %}
@interface FDStackViewDistributionLayoutArrangement : FDStackViewLayoutArrangement
@property (nonatomic, strong) NSMutableArray<NSLayoutConstraint *> *canvasConnectionConstraints;
@property (nonatomic, strong) NSMapTable<UIView *, NSLayoutConstraint *> *edgeToEdgeConstraints;
@property (nonatomic, strong) NSMapTable<UIView *, NSLayoutConstraint *> *relatedDimensionConstraints;
@property (nonatomic, strong) NSMapTable<UIView *, NSLayoutConstraint *> *hiddingDimensionConstraints;

@property (nonatomic, strong) NSMapTable<UIView *, FDGapLayoutGuide *> *spacingOrCenteringGuides;
@end
{% endcodeblock %}

- **canvasConnectionConstraints**：它管路的是`arrangedSubviews`与`canvas`之间的约束；
- **edgeToEdgeConstraints**：它管理的是`arrangedSubviews`之间一个接一个的约束，这里需要注意这些约束的常量是`StackView`的spacing，但是关系却不一定是相等。还有就是如果有个`arrangedSubview`被`hidden`了那么它仍然参与到`edgeToEdge`的约束创建及布局中，只不过是把它与后一个`arrangedSubview`之间的`edgeToEdgeConstraint`的常量由spacing设置为`0`。
- **relatedDimensionConstraints**：它管理的是`arrangedSubviews`之间`distribution`各种相等关系的约束，这里面的管理的约束是`StackView`的`distribution`布局的精髓所在。如果是`UIStackViewDistributionFill`模式的话，是没有`relatedDimensionConstraint`的。`UIStackViewDistributionFillEqually`与`UIStackViewDistributionFillProportionally`使用的是一种类型的约束，而`UIStackViewDistributionEqualCentering`与`UIStackViewDistributionEqualSpacing`使用的却是另一种类型的约束，后面在详细介绍。
-  **hiddingDimensionConstraints**：它管理的是当`arrangedSubviews`有`hidden`的时候，该`arrangedSubview`的有关`dimensionAttribute`的约束；
-  **spacingOrCenteringGuides**：这个管理的就不是约束了，它是一组`FDGapLayoutGuide`，只用在`UIStackViewDistributionEqualCentering`和`UIStackViewDistributionEqualSpacing`这两种模式中，`FDGapLayoutGuide`用来连接左右两个`arrangedSubView`，作为一个辅助view来约束左右两个view的位置关系。`spacingOrCenteringGuides`的key是`FDGapLayoutGuide`连接的左边的`arrangedSubview`。

最后说明的就是`FDGapLayoutGuide`与`arrangedSubView`相连接的约束没有被`NSMapTable`所管理，它们就只是被加到了`canvas`上。因为当模式改变时，所有的`FDGapLayoutGuide`会被移除或者重建，所以跟它们相关的约束也会被一并清楚。

那么以上几种约束的创建顺序是怎样的呢？

1. 首先是`canvasConnectionConstraints`；
2. 其次是每一种模式都会涉及到的`edgeToEdgeConstraints`；
3. 然后再遍历所有`arrangedSubviews`，如果有`arrangedSubview`被`hidden`了，那么就会创建`hiddingDimensionConstraints`；
4. 最后是`relatedDimensionConstraints`，这里如果是`UIStackViewDistributionEqualCentering`和`UIStackViewDistributionEqualSpacing`这两种模式的话，会先创建出`spacingOrCenteringGuides`。

下面具体来看，首先`canvasConnectionConstraints`：
{% codeblock lang:objc %}
- (void)resetCanvasConnectionsEffect {
    [self.canvas removeConstraints:self.canvasConnectionConstraints];
    if (!self.items.count) return;

    NSMutableArray *canvasConnectionConstraints = [NSMutableArray new];
    NSLayoutAttribute minAttribute = [self minAttributeForCanvasConnections];
    NSLayoutConstraint *head = [NSLayoutConstraint constraintWithItem:self.canvas attribute:minAttribute relatedBy:NSLayoutRelationEqual toItem:self.items.firstObject attribute:minAttribute multiplier:1 constant:0];
    [canvasConnectionConstraints addObject:head];
    head.identifier = @"FDSV-canvas-connection";

    NSLayoutConstraint *end = [NSLayoutConstraint constraintWithItem:self.canvas attribute:minAttribute + 1 relatedBy:NSLayoutRelationEqual toItem:self.items.lastObject attribute:minAttribute + 1 multiplier:1 constant:0];
    [canvasConnectionConstraints addObject:end];
    end.identifier = @"FDSV-canvas-connection";

    self.canvasConnectionConstraints = canvasConnectionConstraints;
    [self.canvas addConstraints:canvasConnectionConstraints];
}
{% endcodeblock %}

比较简单，先判断一下不需要创建的情况，然后就是根据`axis`选用不同的`NSLayoutAttribute`，将第一个和最后一个`arrangedSubview`分别与`StackView`创建相等的约束。这样一来再加上`FDStackViewAlignmentLayoutArrangement`中创建的两个`canvasConnectionConstraints`，整个`canvas`的上下左右四个方向的约束就都有了，满足了`canvas`布局的基本条件。

接下来是`edgeToEdgeConstraints`：
{% codeblock lang:objc %}
- (void)resetFillEffect {
    // spacing - edge to edge
    [self.canvas removeConstraints:self.edgeToEdgeConstraints.fd_allObjects];
    [self.edgeToEdgeConstraints removeAllObjects];
    [self.canvas removeConstraints:self.hiddingDimensionConstraints.fd_allObjects];
    [self.hiddingDimensionConstraints removeAllObjects];

    UIView *offset = self.items.car;
    UIView *last = self.items.lastObject;
    for (UIView *view in self.items.cdr) {
        NSLayoutAttribute attribute = [self minAttributeForGapConstraint];
        NSLayoutRelation relation = [self edgeToEdgeRelation];
        NSLayoutConstraint *spacing = [NSLayoutConstraint constraintWithItem:view attribute:attribute relatedBy:relation toItem:offset attribute:attribute + 1 multiplier:1 constant:self.spacing];
        spacing.identifier = @"FDSV-spacing";
        [self.canvas addConstraint:spacing];
        [self.edgeToEdgeConstraints setObject:spacing forKey:offset];
        if (offset.hidden || (view == last && view.hidden)) {
            spacing.constant = 0;
        }
        offset = view;
    }
    // hidding dimensions
    for (UIView *view in self.items) {
        if (view.hidden) {
            NSLayoutAttribute dimensionAttribute = [self dimensionAttributeForCurrentAxis];
            NSLayoutConstraint *dimensionConstraint = [NSLayoutConstraint constraintWithItem:view attribute:dimensionAttribute relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:0];
            dimensionConstraint.identifier = @"FDSV-hiding";
            [self.canvas addConstraint:dimensionConstraint];
            [self.hiddingDimensionConstraints setObject:dimensionConstraint forKey:view];
        }
    }
}
{% endcodeblock %}

先移去旧的相关约束，然后将`arrangedSubviews`依次迭代遍历，根据`axis`选择正确的`NSLayoutAttribute`创建首尾相接的约束，常量为`StackView`的spacing，关系则根据`distribution`的不同而或等于或大于等于。

这里如前面介绍的一样，如果这个`arrangedSubview`是`hidden`的那么它仍然参与`edgeToEdgeConstraints`的创建，只不过它与后一个`arrangedSubview`的约束常量不再是spacing而是`0`。还有一个特殊的就是如果是最后一个`arrangedSubview`被`hidden`了，那么它与前一个`arrangedSubview`的约束的常量也同样是`0`。

最后再遍历所有`arrangedSubviews`，如果有`arrangedSubview`被`hidden`了，那就根据`axis`给这个`arrangedSubview`创建一个常量为`0`的`dimensionConstraint`。

如果是`UIStackViewDistributionFill`的话，那么到这里所有`distribution`的约束就已经创建完了，已经满足需求了。但是其他几种还要有后续的步骤。

==========================

先来看`UIStackViewDistributionFillEqually`和`UIStackViewDistributionFillProportionally`这两种类型：
{% codeblock lang:objc %}
- (void)resetEquallyEffect {
    [self.canvas removeConstraints:self.relatedDimensionConstraints.fd_allObjects];
    [self.relatedDimensionConstraints removeAllObjects];

    NSArray<UIView *> *visiableViews = self.visiableItems;
    UIView *offset = visiableViews.car;
    CGFloat order = 0;
    for (UIView *view in visiableViews.cdr) {
        NSLayoutAttribute attribute = [self dimensionAttributeForCurrentAxis];
        NSLayoutRelation relation = NSLayoutRelationEqual;
        CGFloat multiplier = self.distribution == UIStackViewDistributionFillEqually ? 1 : ({
            CGSize size1 = offset.intrinsicContentSize;
            CGSize size2 = view.intrinsicContentSize;
            CGFloat multiplier = 1;
            if (attribute == NSLayoutAttributeWidth) {
                multiplier = size1.width / size2.width;
            } else {
                multiplier = size1.height / size2.height;
            }
            multiplier;
        });
        NSLayoutConstraint *equally = [NSLayoutConstraint constraintWithItem:offset attribute:attribute relatedBy:relation toItem:view attribute:attribute multiplier:multiplier constant:0];
        equally.priority = UILayoutPriorityRequired - (++order);
        equally.identifier = self.distribution == UIStackViewDistributionFillEqually ? @"FDSV-fill-equally" : @"FDSV-fill-proportionally";
        [self.canvas addConstraint:equally];
        [self.relatedDimensionConstraints setObject:equally forKey:offset];

        offset = view;
    }
}
{% endcodeblock %}

仍然是先干掉旧的约束，然后跟前面不同的是要取出所有的**非hidden**的`arrangedSubview`添加约束，而不是所有`arrangedSubview`。

这两个`distribution`类型是将当前`axis`所对应的`dimensionAttribute`的约束作用在`arrangedSubviews`上，如果是`UIStackViewDistributionFillEqually`，那么约束的比例(`multiplier`)就是`1`，如果是`UIStackViewDistributionFillProportionally`，那`multiplier`就需要通过计算得出，是通过两个`arrangedSubview`的`intrinsicContentSize`做比值，这样就能保证`arrangedSubview`最终会按照`intrinsicContentSize`的比例来分配`StackView`的空间布局。

再来看`UIStackViewDistributionEqualCentering`和`UIStackViewDistributionEqualSpacing`这两种类型：
{% codeblock lang:objc %}
- (void)resetSpacingOrCenteringGuides {
    [self.spacingOrCenteringGuides.fd_allObjects makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.spacingOrCenteringGuides removeAllObjects];
    NSArray<UIView *> *visiableItems = self.visiableItems;
    if (visiableItems.count <= 1) {
        return;
    }

    [[visiableItems subarrayWithRange:(NSRange){0, visiableItems.count - 1}] enumerateObjectsUsingBlock:^(UIView *item, NSUInteger idx, BOOL *stop) {
        FDGapLayoutGuide *guide = [FDGapLayoutGuide new];
        [self.canvas addSubview:guide];
        guide.translatesAutoresizingMaskIntoConstraints = NO;
        UIView *relatedToItem = visiableItems[idx+1];

        NSLayoutAttribute minGapAttribute = [self minAttributeForGapConstraint];
        NSLayoutAttribute minContentAttribute;
        NSLayoutAttribute maxContentAttribute;
        if (self.distribution == UIStackViewDistributionEqualCentering) {
            minContentAttribute = self.axis == UILayoutConstraintAxisHorizontal ? NSLayoutAttributeCenterX : NSLayoutAttributeCenterY;
            maxContentAttribute = minContentAttribute;
        } else {
            minContentAttribute = minGapAttribute;
            maxContentAttribute = minGapAttribute + 1;
        }

        NSLayoutConstraint *beginGap = [NSLayoutConstraint constraintWithItem:guide attribute:minGapAttribute relatedBy:NSLayoutRelationEqual toItem:item attribute:maxContentAttribute multiplier:1 constant:0];
        beginGap.identifier = @"FDSV-distributing-edge";
        NSLayoutConstraint *endGap = [NSLayoutConstraint constraintWithItem:relatedToItem attribute:minContentAttribute relatedBy:NSLayoutRelationEqual toItem:guide attribute:minGapAttribute + 1 multiplier:1 constant:0];
        endGap.identifier = @"FDSV-distributing-edge";
        [self.canvas addConstraint:beginGap];
        [self.canvas addConstraint:endGap];

        [self.spacingOrCenteringGuides setObject:guide forKey:item];
    }];
}

- (void)resetSpacingOrCenteringGuideRelatedDimensionConstraints {
    [self.canvas removeConstraints:self.relatedDimensionConstraints.fd_allObjects];
    NSArray<UIView *> *visiableItems = self.visiableItems;
    if (visiableItems.count <= 1) return;

    FDGapLayoutGuide *firstGapGuide = [self.spacingOrCenteringGuides objectForKey:visiableItems.car];
    [self.spacingOrCenteringGuides.fd_allObjects enumerateObjectsUsingBlock:^(UIView *obj, NSUInteger idx, BOOL *stop) {
        if (firstGapGuide == obj) return;
        NSLayoutAttribute dimensionAttribute = [self dimensionAttributeForCurrentAxis];
        NSLayoutConstraint *related = [NSLayoutConstraint constraintWithItem:firstGapGuide attribute:dimensionAttribute relatedBy:NSLayoutRelationEqual toItem:obj attribute:dimensionAttribute multiplier:1 constant:0];
        related.identifier = @"FDSV-fill-equally";
        [self.relatedDimensionConstraints setObject:related forKey:obj];
        [self.canvas addConstraint:related];
    }];
}
{% endcodeblock %}

先创建`spacingOrCenteringGuides`，开始是干掉旧的`spacingOrCenteringGuides`。这里使用的仍然是**visiableItems**。
`FDGapLayoutGuide`用来连接左右相连的两个可见`arrangedSubview`。

这两个`distribution`不同的地方就是`UIStackViewDistributionEqualSpacing`的`FDGapLayoutGuide`连接的是`arrangedSubview`的`minAttribute`和`maxAttribute`，而`UIStackViewDistributionEqualCentering`的`FDGapLayoutGuide`连接的却是`arrangedSubview`的`centerAttribute`。

接下来就是创建`relatedDimensionConstraints`，就是根据`axis`不同给对应的`dimensionAttribute`创建相等的约束即可，这些约束是作用在`FDGapLayoutGuide`上的，而与前面那两种`distribution`类型不同。这就是一开始说的`relatedDimensionConstraints`中的两种类型的约束。

到此整个`distribution`方向的约束也都创建完了。加上`alignment`方向创建的约束，`StackView`已经可以使用了。

==========================

介绍完这些再回过头来看[本文章`Part 1`](http://blog.wtlucky.com/blog/2015/10/09/fdstackview-downward-compatible-uistackview-part-1/)中后面提到的`UIStackView`的第一个bug，当存在spacing的时候`UIStackViewDistributionFillProportionally`这个类型的`StackView`是烂掉的。我刚才看了一下，苹果仍然没有修复这个bug。

具体的原因那篇文章中已经解释了，现在说下为什么`FDStackView`没有这个问题，相信看完前面创建约束的过程，读者朋友应该就能发现我们并没有像`UIStackView`那样将`canvas`的`dimensionAttribute`乘以一个系数作为`arrangedSubview`的`dimensionConstraint`。我们的`arrangedSubview`的`dimensionConstraint`是与`canvas`无关的，是`arrangedSubviews`之间的比例关系，而且spacing在之前的`edgeToEdgeConstraints`中就已经创建了，这两者是分开创建的，所以算法不同，自然也就不会出现这个bug。

==========================

下面看其余的知识点：
### 子视图的隐藏显示如何处理

如果一个已经布好局的`StackView`，在一个`arrangedSubview`被`hidden`或者`show`之后，那么其余的`arrangedSubviews`也要做出相应变化，来相应这种变化。

在`FDStackView`这里我们是通过`KVO`监测每一个`arrangedSubview`的`hidden`属性，当任何一个`arrangedSubview`属性发生变化后，我们就通过`rebuild`的方式重新创建整个`StackView`的约束，就是重新布局一遍。这是目前`1.0`版本的处理方式，这样势必会带来性能的损失，这也是我们后续优化性能的关键。

### 子视图的`intrinsicContentSize`发生变化时如何处理

什么叫子视图的`intrinsicContentSize`发生变化呢？举个例子，一个已经布好局的`StackView`，其中有一个`arrangedSubview`是一个`UILabel`，但是这个`UILabel`被重新`setText`了，那么它的`intrinsicContentSize`就会发生变化，自然`StackView`的布局如果不发生变化的话就是错误的。所以在这种情况下`StackView`也要做出处理。

这里我们研究了`UIStackView`的实现方式，一个`arrangedSubview`的`intrinsicContentSize`发生变化如何被捕捉到，是我们未知的，`UIKit`并没有暴露任何方法给我们，我们只能通过下符号断点的方式给dump出来的`UIStackView`的私有类。

研究发现当一个`arrangedSubview`的`intrinsicContentSize`发生变化时，`UIStackView`总会调用到`_intrinsicContentSizeInvalidatedForChildView:`这个私有方法，参数为发生变化的`arrangedSubview`。所以我们就把这一私有方法给替换了，借助`UIKit`内部的机制来帮我们通知一个`arrangedSubview`的`intrinsicContentSize`发生变化的这种情况。

{% codeblock lang:objc %}
// Use non-public API in UIView directly is dangerous, so we inject at runtime.
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL selector = NSSelectorFromString(@"_intrinsicContentSizeInvalidatedForChildView:");
        Method method = class_getInstanceMethod(self, @selector(intrinsicContentSizeInvalidatedForChildView:));
        class_addMethod(self, selector, method_getImplementation(method), method_getTypeEncoding(method));
    });
}
{% endcodeblock %}

接到这种通知之后，我们目前也是通过`rebuild`的方式来重建`StackView`的约束的。其实对于这种情况以及上面提到的`hidden`的情况，我们都能得到具体发生变化的那个`arrangedSubview`，这也将会是后续优化的突破口。

==========================

到此整个`FDStackView`的设计实现过程都介绍完了，当然还有一些零零碎碎的点没有说，都在源码里了。后续版本会增加`Layout Margins`的支持，以及性能优化。

最后在附一张`UIStackView`及`FDStackView`在不同`iOS`系统上加载运行图：

![](https://oac67o3cg.qnssl.com/1475116763.png )

全文完，转载请注明出处，谢谢阅读。

————————————

![](https://oac67o3cg.qnssl.com/1475114982.png )
