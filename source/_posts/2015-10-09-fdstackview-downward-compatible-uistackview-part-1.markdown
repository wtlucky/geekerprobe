---
layout: post
title: "FDStackView —— Downward Compatible UIStackView (Part 1)"
date: 2015-10-09 21:32:12 +0800
comments: true
categories: [iOS development]
tags: iOS AutoLayout forkingdog
---

加入百度知道团队也有一段时间了，能跟[@我就叫Sunny怎么了](http://weibo.com/u/1364395395)、[@sinojerk](http://weibo.com/u/5665046845)等小伙伴一起工作生活是一种极赞的体验。在完成日常业务开发之余，我们也会进行一些技术研究项目，并将研究结果以开源的方式公布出来，自然我也成为了`forkingdog`开源小组的一员。

近期我们的研究项目是`FDStackView`，现如今已经完成了`Alpha`版本的开发工作，并将其开源在了`Github`上，[项目地址](https://github.com/forkingdog/FDStackView)。虽然现在已经完成所有的基本功能，但是仍需要在真实的环境中测试试用，欢迎大家将试用之后的问题反馈给我们，提`issue`给我们，使我们更好的修复和完善`FDStackView`，以便于更好的方便开发者们使用。
<!-- More -->

## Introduce

`FDStackView`究竟是什么呢？在介绍`FDStackView`之前，首先你需要知道`UIStackView`是什么？`UIStackView`是苹果在WWDC上发布`iOS9`的时候新推出的一个`UIKit`的视图，现在网上可以搜索到很多关于它的资料，关于介绍，如何使用等。简单来说就是可以使用它来做一些流式布局，开发者只需要将需要的视图丢到`UIStackView`中，然后设置它的一些属性来展现所需要的布局，因此无需自己再去添加各种约束，所有约束不在由开发者自己去管理，这对于一些还不会使用`AutoLayout`的开发者来说是一个福音。复杂来说，因为`UIStackView`是可以嵌套使用的，那么再结合上一些简单的约束，那么就可以完成任何复杂的界面了。想想之前需要各种管理约束，而现在有了它只需要将视图丢给它，改几个属性然后界面就做好了，是不是爽到爆，开发效率又提升一个档次啊。下面提供几个介绍`UIStackView`的文章，使还不太了解的同学可以了解一下，传送门在此：

>[iOS 9: Getting Started with UIStackView](http://code.tutsplus.com/tutorials/ios-9-getting-started-with-uistackview--cms-24193)

>[中文翻译版](http://www.cocoachina.com/ios/20150623/12233.html)

>[An Introduction to Stack Views in iOS 9 and Xcode 7](http://www.appcoda.com/stack-views-intro/)

>[中文翻译版](http://www.cocoachina.com/ios/20150820/13118.html)

介绍完`UIStackView`的优势想必大家都已经跃跃欲试了，我自身对于这个控件都是十分的期待，因为在开发中你可以不用去写大段的创建`constraints`的代码了，如果你使用`xib`或者`storyboard`的话，那么在`IB`中你也不需要去连接各种约束了，这是多么棒的一种体验，而且在`Xcode7`的`IB`中右下角往常用来增加约束，修正视图的位置又新增加了一个`stack`按钮，可以快速的将所选视图加入到`UIStackView`中，可见苹果也是推荐开发者使用`UIStackView`的。但是`UIStackView`是在`iOS9`才推出的，最低支持的系统也是`iOS9`，这就蛋疼了，现在能有几个`APP`是从`iOS9`开始支持的，如此一来这个控件就成了鸡肋般的存在，再低版本下根本无法使用。自己在业务开发中经常会想这个需求用`UIStackView`简直就是妙解，而我却还在这里痛苦的连约束……鉴于这个强烈的需求，`FDStackView`出现了，它就是为了解决`UIStackView`在低于`iOS9`的系统下无法使用的问题。在`FDStackView`之前也已经有了一些类似的开源项目，比如`OAStackView`和`TZStackView`，然而他们都不能满足我们的需求，局限性还是比较大的，比如不支持`IB`，某些功能还没有实现，类名需要使用非`UIStackView`，在我们看来这些对开发者来说都是不友好的，开发者需要的是一款功能完善，支持`IB`，使用时完全无感，在`Xcode7`上直接使用`UIStackView`即可，接下来的事情交给`FDStackView`就好，它负责将`UIStackView`在低于`iOS9`的系统上运行。需要注意的是如果使用`IB`的话，那么`IB`的`Builds for`属性需要设置为`iOS 9.0 and later`。如图所示：

{% img https://raw.githubusercontent.com/forkingdog/FDStackView/master/Snapshots/snapshot0.png %}

## Research

这个技术项目有一大部分的时间，我们都是在做调研工作，首先我们需要把`UIStackView`玩的很熟练，它的各种属性，各种状态以及他们的组合关系分别是什么样的，其次我们需要解决的问题有：

1. 使用低系统版本的`API`和控件创建一个和`UIStackView`一模一样的控件`FDStackView`;
2. 在低系统版本运行`UIStackView`的时候使用我们的`FDStackView`;
3. 使`FDStackView`获得`Interface Builder`的支持。

解决了以上三个问题后，那么这个项目基本上也就算是完成了，第一个是工作量最大的工程，它又可以拆分为以下几个技术点：

- `alignment`和`distribution`的约束如何添加和管理；
- `spacing`和`distribution`的关系及约束的创建；
- 子视图的隐藏显示如何处理；
- 子视图的`intrinsicContentSize`发生变化时如何处理。

首先我们假设在第一个难点已经解决的前提下去攻克其他的难点，毕竟有其他开源方案的存在，说明这个不是不可行的。

至于第二个难点，`UIStackView`在低系统版本编译时会报找不到符号的`error`，那么解决的思路就是在低系统版本将`UIStackView`的符号写进去，然后在`runtime`将符号与我们的`FDStackView`做关联，从而使低系统版本也能够运行`UIStackView`，而实际上在起作用的是我们的`FDStackView`。这里使用到的`黑魔法`就是汇编语言，网上已经有大神给出了类似的[解决方案](https://gist.github.com/OliverLetterer/4643294)，对其进行优化和修改之后应该就能满足我们的需求。

最后一个难点就是使`FDStackView`获得`Interface Builder`的支持，因为我们是`IB`的重度使用者，一个不能在`IB`上使用的控件一定不是一个好控件。所以一定要让`FDStackView`能够在`IB`上使用，有一个方案就是直接使用`UIView`然后把他的`Class`指定为`FDStackView`，将`Axis`、`Alignmen`和`Distribution`等属性通过`IBInspectable`使其可以在`IB`中编辑和设置，但是这样一个是`IBInspectable`在`IB`中的显示效果很烂，说实话就是不好用，再一个就是用了`UIView`没有办法像`UIStackView`那样在`IB`中可以直接预览布局效果，这就是很差的一种体验了。最好的方案就是在`IB`中仍然使用`UIStackView`，使其在`IB`中有最佳的体验，然后借助上一难点的解决方案，在低系统版本中使用`FDStackView`代替`UIStackView`。这样就会带来两个其他问题：

1. `IB`的构建版本是根据`Project`的部署版本来的，如果项目不是支持`iOS9`的话那么会报这样一个`error`:`”UIStackView before iOS 9.0”`；
2. 如何使`IB`构建出来的`FDStackView`获得在`IB`中给`UIStackView`所设置的各种属性。
这两个问题，第一个只需要将`IB`的构建版本设置为`iOS9`及以后即可，目前来看是没有问题的，但是还不知道其他的控件被`IB`搞成`iOS9`的版本，在低系统版本上会不会有问题，这个还需要后续的验证。第二个问题，由于使用`IB`创建的`UIKit`控件都会由`initWithCoder:`进行初始化，因此弄清楚`NSCoder`的`decode`过程就能将`IB`设置的属性赋值给所创建的对象了。

解决完以上两个难点，就可以回过头来研究第一个了，就是创建一个和`UIStackView`一模一样的`FDStackView`。这里我们对`UIStackView`进行了详细的研究，包括`dump`出所有`UIStackView`的相关私有类，各个类的方法，实例变量等。还需要添加符号断点来跟踪各个方法的调用顺序及各个实例变量的值得变化情况。同时还需要分析各个状态下`UIStackView`的约束`constraints`的情况，包括约束的个数，连接的方式，及约束所添加到的视图等。经过以上的各种分析之后，我们又通过在`IB`中借助`UIView`手动连接约束的方式，连出每一个`UIStackView`所对应的状态。经过这一番调查与研究我们已经大概摸清的`UIStackView`的工作原理与实现方式。

与此同时我们还发现了两个`UIStackView`的`bug`，本以为在`Xcode7`正式发布之后会得到修复，可是遗憾的是从我们开始研究的时候的`beta5`到后来的`beta6`、`GM`和正式版这两个`bug`依然存在，后面我会介绍一下这两个`bug`。

## Implementation

下面介绍一下具体的实现细节，同样还是从第二个点说起，最终起关键作用的代码是这些：
{% codeblock lang:objc %}
// ----------------------------------------------------
// Runtime injection start.
// Assemble codes below are based on:
// https://github.com/0xced/NSUUID/blob/master/NSUUID.m
// ----------------------------------------------------

#pragma mark - Runtime Injection

__asm(
      ".section        __DATA,__objc_classrefs,regular,no_dead_strip\n"
#if	TARGET_RT_64_BIT
      ".align          3\n"
      "L_OBJC_CLASS_UIStackView:\n"
      ".quad           _OBJC_CLASS_$_UIStackView\n"
#else
      ".align          2\n"
      "_OBJC_CLASS_UIStackView:\n"
      ".long           _OBJC_CLASS_$_UIStackView\n"
#endif
      ".weak_reference _OBJC_CLASS_$_UIStackView\n"
      );

// Constructors are called after all classes have been loaded.
__attribute__((constructor)) static void FDStackViewPatchEntry(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        @autoreleasepool {

            // >= iOS9.
            if (objc_getClass("UIStackView")) {
                return;
            }

            Class *stackViewClassLocation = NULL;

#if TARGET_CPU_ARM
            __asm("movw %0, :lower16:(_OBJC_CLASS_UIStackView-(LPC0+4))\n"
                  "movt %0, :upper16:(_OBJC_CLASS_UIStackView-(LPC0+4))\n"
                  "LPC0: add %0, pc" : "=r"(stackViewClassLocation));
#elif TARGET_CPU_ARM64
            __asm("adrp %0, L_OBJC_CLASS_UIStackView@PAGE\n"
                  "add  %0, %0, L_OBJC_CLASS_UIStackView@PAGEOFF" : "=r"(stackViewClassLocation));
#elif TARGET_CPU_X86_64
            __asm("leaq L_OBJC_CLASS_UIStackView(%%rip), %0" : "=r"(stackViewClassLocation));
#elif TARGET_CPU_X86
            void *pc = NULL;
            __asm("calll L0\n"
                  "L0: popl %0\n"
                  "leal _OBJC_CLASS_UIStackView-L0(%0), %1" : "=r"(pc), "=r"(stackViewClassLocation));
#else
#error Unsupported CPU
#endif

            if (stackViewClassLocation && !*stackViewClassLocation) {
                Class class = objc_allocateClassPair(FDStackView.class, "UIStackView", 0);
                if (class) {
                    objc_registerClassPair(class);
                    *stackViewClassLocation = class;
                }
            }
        }
    });
}
{% endcodeblock %}

首先说一下`__asm`:
{% codeblock %}
Use the asm, _asm, or __asm keyword to place assembly language statements in the middle of your C or C++ source code. Any C++ symbols are replaced by the appropriate assembly language equivalents.
You can group assembly language statements by beginning the block of statements with the asm keyword, then surrounding the statements with braces ({}).
Note: The __asm form is the only one supported by Clang-based C++ compilers.
{% endcodeblock %}
意思就是说在你的`C`或`C++`源代码中放入汇编代码用来替换任何`C++`的符号。

{% codeblock lang:objc %}
__asm(
			/**
       this is a data section for objc2 class references with the following attributes:
       * regular: "A regular section may contain any kind of data and gets no special processing from the link editor. This is the default section type. Examples of regular sections include program instructions or initialized data."
       * no_dead_strip: "The no_dead_strip section attribute specifies that a particular section must not be dead-stripped."

       Documentation can be found here: https://developer.apple.com/library/mac/#documentation/developertools/Reference/Assembler/040-Assembler_Directives/asm_directives.html
       */
      ".section        __DATA,__objc_classrefs,regular,no_dead_strip\n"
#if	TARGET_RT_64_BIT
      ".align          3\n" // align the next label to 2^3 bytes = 64 bit for 64 bit platforms
      "L_OBJC_CLASS_UIStackView:\n"  // the L_OBJC_CLASS_UIStackView label will store the _OBJC_CLASS_$_UIStackView label, which is weak referenced (see below)
      ".quad           _OBJC_CLASS_$_UIStackView\n"
#else
      ".align          2\n"
      "_OBJC_CLASS_UIStackView:\n"
      ".long           _OBJC_CLASS_$_UIStackView\n"
#endif
			/**
       .weak_reference: "The .weak_reference directive causes symbol_name to be a weak undefined symbol present in the output file’s symbol table. This is used by the compiler when referencing a symbol with the weak_import attribute."
       */
      ".weak_reference _OBJC_CLASS_$_UIStackView\n"
      );
{% endcodeblock %}

先来说这一个部分，大神的[解决方案](https://gist.github.com/OliverLetterer/4643294)给出了英文注释，尝试着直译了一下：
{% codeblock %}
这是一个由regular和no_dead_strip属性所标明的objc2类的数据区间。
regular:一个regular区间一般包含各种类型的数据而且他们不会被连接器做特殊处理。这是默认的区间类型，包括程序指令和初始化数据是regular区间。
no_dead_strip:一个no_dead_strip区间标识出那些一定不能dead_strip的特殊区间。
{% endcodeblock %}
发现还不如不译，就直接说一下大概的意思吧。
第一行是取得符号所在的区间，之后区分`64`和`32`位系统，将`_OBJC_CLASS_$_UIStackView`这个符号与自定的符号做一个`weak`类型的关联。

接下来就是`__attribute__((constructor))`这个黑魔法，这个标识的方法会在所有的类`load`之后，`main`函数调用之前调用。所以此时`FDStackView`已经被`load`了。再之后就是判断`runtime`是否存在`UIStackView`，不存在的话就根据不同的系统平台将指向`_OBJC_CLASS_$_UIStackView`这个符号的指针存储在`stackViewClassLocation`中，接下来通过`runtime`创建`UIStackView`这个类并作为`FDStackView`的子类，并注册进`runtime`，最后将`UIStackView`作为`stackViewClassLocation`这个指针的值。如此一来在低系统版本中`UIStackView`就能作为`FDStackView`的子类使用了。它没有重载任何方法，因此就跟使用直接`FDStackView`一模一样。

接下来的问题是`IB`加载出来的`UIStackView`如何将属性值设置到我们的`FDStackView`上，这个在前面研究是已经有结论，首先需要将`IB`的`build for`做下修改，然后`IB`创建的`UIKit`控件都会由`initWithCoder:`进行初始化，所以所有的信息都在`NSCoder`这个对象中，`NSCoder`提供了一系列的`decode`方法，由于`key`是字符串，所以可以在汇编代码处直接看到，所以通过加符号断点的方式找到这几个`key`。

{% img https://oac67o3cg.qnssl.com/1475116128.png %}
{% img https://oac67o3cg.qnssl.com/1475116163.png %}

如此一来就可以直接在`FDStackView`的`initWithCoder:`方法中取到值，再将这几个值赋值即可
{% codeblock lang:objc %}
- (id)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if (self) {
        // Attributes of UIStackView in interface builder that archived.
        [self commonInitializationWithArrangedSubviews:[decoder decodeObjectForKey:@"UIStackViewArrangedSubviews"]];
        self.axis = [decoder decodeIntegerForKey:@"UIStackViewAxis"];
        self.distribution = [decoder decodeIntegerForKey:@"UIStackViewDistribution"];
        self.alignment = [decoder decodeIntegerForKey:@"UIStackViewAlignment"];
        self.spacing = [decoder decodeDoubleForKey:@"UIStackViewSpacing"];
        self.baselineRelativeArrangement = [decoder decodeBoolForKey:@"UIStackViewBaselineRelative"];
        self.layoutMarginsRelativeArrangement = [decoder decodeBoolForKey:@"UIStackViewLayoutMarginsRelative"];
    }
    return self;
}
{% endcodeblock %}

最后就是通过系统的`API`创建`constraints`来实现`FDStackView`了，这里涉及的内容比较多，包括几个辅助的私有类，及`Alignment`和`Distribution`方向上的约束创建，子视图隐藏，`intrinsicContentSize`改变如何处理等。这里我们都尽可能的与猜测到的`UIStackView`的实现保持一致。这些内容将会在后续的另一篇文章中介绍。

## UIStackView Bugs

现在来说一下我们在调研`UIStackView`时发现的两个`bug`，[测试的`Demo`](https://github.com/wtlucky/UIStackViewBugDemo)已经放在`Github`上。

这个测试`Demo`会借助我们的`FDStackView`来演示对比出`UIStackView`的`bug`，上面是系统原生的`UIStackView`，下面是我们的`FDStackView`，两者的参数设置是完全相同的。

先来看第一个，当`Distribution`设置为`UIStackViewDistributionFillProportionally`时，并且存在`spacing`时就会出现问题，如图所示：

{% img http://i3.piimg.com/22c9f3dc8b429bdd.jpg %}

`UIStackViewDistributionFillProportionally`这个属性的意思是子视图的宽度会根据他们内容的宽度比例而在`UIStackView`中占据对应的宽度，即他们的实际的宽度比应该是他们的内容固有宽度（`intrinsicContentSize`）的比例，`Demo`中三个`Label`的固有宽度即汉字的宽度是`4:1:2`，那么在`UIStackView`中他们所占据的宽度也应该是`4:1:2`，这在`spacing`为`0`的情况下是ok的。

如果存在`spacing`的话，那么`UIStackView`应该先减去子视图之间的`spacing`，然后再去按比例分布子视图的宽度。这里可以看到`UIStackView`的布局是烂的了，而`FDStackView`的布局是ok的。

这里我们通过分析`UIStackView`身上的`constraints`大概得出`UIStackView`出现这个`bug`的原因是，他们的算法出了问题，他们这一部分的约束是这样添加的，每一个子视图的宽度等于`UIStackView`的宽度乘上一个比例系数，即`AutoLayout`计算公式`y  = m * x + c`中的`m`系数，`c`的值一直为`0`。他们在计算`m`的时候出了问题，忽略了`spacing`的存在，也就是在计算中没有计算上`spacing`的值。

具体拿`Demo`来看的话，`UIStackView`的最左边的`Label`的宽度应该是这样计算的`label.width = 4 * UIStackView.width / (4 + 1 + 2)`，这是`spacing`为`0`时，`m`的值就是`4 / (4 + 1 + 2)`，这没有问题 ，但是如果有`spacing`的话，他们把`spacing`也作为了分母的一部分，认为`spacing`也是可以按比例显示宽度的，所以`m`的值就成为了`4 / (4 + 1 + 2 + spacing)`（这里的`spacing`不是`UIStackView`设置`spacing`的值，而应该是实际`UIStackView`中出现的所有`spacing`的和）。因为`spacing`被当作分母计算了进去，那么在布局的时候`spacing`也应该按照计算出的系数乘上`UIStackView`的宽度来显示，但实际上他们没有这么做，而是把`spacing`按固定值来显示了，这样就会因为分母加入了`spacing`导致所有子视图计算出的`m`偏小，进而显示出来也就会偏小，到了最后一个视图时，由于约束优先级的缘故导致这个宽度的约束不再起作用，从而导致被拉长，出现了上图的效果。

所以这里`UIStackView`是算法出了问题而显示时又按正确的样式来显示，所以布局就烂了，其实在有`spacing`的状态下就不应该忽略`c`的值了，而且`spacing`也不应该参与到分母中去计算，正确的约束应该是这个样子的`label.width = 4 * UIStackView.width / (4 + 1 + 2) - 4 * spacing / (4 + 1 + 2)`，这时`c`就有值了，不再是`0`而是`-4 * spacing / (4 + 1 + 2)`。

整体来说`UIStackView`在处理`UIStackViewDistributionFillProportionally`这个属性的时候采取的约束添加方式不是最好的，处理起来是比较复杂的，这样处理会出现很多非整数情况，一个是计算复杂，在一个也会丢失精度。所以我们在`FDStackView`中没有使用这种连接方式，而是使用了另外一种方法，后面的文章会介绍到。

另外一个`bug`是当`Alignment`属性设置为`UIStackViewAlignmentFill`时，当一个最高的子视图隐藏掉了时，`UIStackView`的高度并没有变化，这时它应该变为第二高的子视图的高度，具体如图所示：

{% img http://imgchr.com/images/hidingBug.gif %}

这种情况只有在属性设置为`UIStackViewAlignmentFill`时才会出现，具体的出现原因我们也有分析出来的结论，但是涉及到`Alignment`方向上约束添加的问题，这个会在后一篇文章中提到，所以这里就先不做解释，之后在说。我们的`FDStackView`修复了这个问题，但是在一种情况下也会失去作用就是给这个要隐藏的视图收到添加了一个高优先级的高度约束的情况下，不过一般情况下我们使用`UIStackView`基本都不会再给子视图添加约束了。

第一篇文章就介绍这么多，后面我会找时间把第二篇文章（Part 2）整理出来。

————————————

![](https://oac67o3cg.qnssl.com/1475114982.png )
