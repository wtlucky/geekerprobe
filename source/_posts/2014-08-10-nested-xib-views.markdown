---
layout: post
title: "Nested Xib Views - 使用XIB实现嵌套自定义视图"
date: 2014-08-10 15:18
comments: true
categories: [iOS development]
tags: iOS
---

在进行`iOS`开发的过程中，对于一些复杂的界面，我们可以通过`Interface Builder`这个`Xcode`集成的可视化界面编辑工具在完成，这回节省大部分时间以及代码量。它的使用方法这里不做介绍了，这次我要介绍是使用它来实现一个嵌套的自定义视图。解释一下就是，我们使用`IB`自定义了一个`View`，然后又在其他的`xib`文件中使用了这个`View`，那么这就是所谓的嵌套自定义视图。之所以要介绍它，是因为我自己在使用它的时候遇到了一些问题，一方面写下来做个记录供自己查看，另一方面我相信大家在使用的时候应该也会遇到这样的问题，方便大家。<!-- More -->

下面使用的示例代码我已经放到`Github`上了，[项目地址](https://github.com/wtlucky/nestedXibLoad)，有需要的朋友可以去查看，`Demo`非常简单，主要是介绍这个知识点。

##Question##

首先我们创建一个`SingleView`的工程，项目使用`StoryBoard`，（使用`Xib`也无所谓，因为有些老的项目可能还没有使用到`StoryBoard`），然后创建一个`CustomView`作为我们的自定义视图。

{% img http://imgchr.com/images/QQ20140810-1.jpg %}

有时对于复杂的界面我们可能会拆分出来对它进行单独处理，又有可能它的界面布局很复杂，这时我们就会用`Interface Builder`对它的布局进行处理。这里的`CustomView`就是这样一个视图，所以我们为它创建一个`xib`文件，我们通常的作法就是把`xib`中的`View`的`custom class`更改为我们的`CustomView`。

{% img http://imgchr.com/images/QQ20140810-2.jpg %}

接下来对我们的界面进行布局，并连接输出口，编写响应逻辑，这里我放了一个`ImageView`和一个`Label`在这里，并把`View`的背景色设置为浅灰色。

{% img http://imgchr.com/images/QQ20140810-3.jpg %}

自定义的`View`制作完成，回到我们`ViewController`的`xib`文件，拖入两个`View`并把他们的`custom class`更改为`CustomView`。

{% img http://imgchr.com/images/QQ20140810-11.jpg %} 

这时，我们算是工作做完了，运行程序，结果悲剧了，怎么不是我们想要的结果，为什么只生成了两个空白的视图，我们视图上的图片和文字哪里去了？

{% img http://imgchr.com/images/QQ20140810-5.jpg %}

在`CustomView`中的`awakeFromeNib`方法中增加断点调试发现，在`CustomView`初始化完成后，`ImageView`和`Label`并没有被初始化，他们仍然是`nil`。这就是在嵌套使用`xib`自定义视图时非常容易出现的问题，我们觉得被嵌套的视图能够正常显示出来，但是实际上它并没有被按照我们在`xib`上指定的方式被初始化。

{% img http://imgchr.com/images/QQ20140810-6.jpg %}

##Solution##

那么如何解决这种问题，以及这种问题又是如何出现的呢？其实这主要是由于我们对`xib`文件的加载原理不熟悉所导致的，我们以为定义一个`View`，创建一个`xib`文件并布局好它的子视图，让后将它使用在另外一个`xib`文件中，把`custom class`改成它，然后`xib`的加载系统会自动为我们做好其余的一切。其实并不是这样的。

这样做`xib`加载系统只会为我们创建一个`CustomView`的对象，但这并不包括`CustomView`所对应的`xib`文件中的部分，所以只创建了一个空白的`View`。

解决他们有两种方式，不过最终的思路都是通过代码强制使`CustomView`的`xib`部分被加载。第一种是通过代码创建`CustomView`的对象，然后`addSubview`到`viewController`的`view`上。第二种是在`CustomView`的实现文件里，通过重载一些方法，来完成加载`xib`文件。

这两种方法各有利弊，第一种使用起来方便也好理解，但是当嵌套的层级比较多的时候或者一个`View`中有多个这样的`CustomView`时，这种方式就会显得过于麻烦。而第二种虽然理解起来有些难度，但是当你处理好之后，直接在需要的`xib`文件中拖入`view`，改个`custom class`，就能直接生成需要的对象了，并且也能够在`xib`中对他们进行直接布局，不再需要用代码去布局了。

###NO 1.###

先来介绍第一种方法，很简单，就是找到`xib`文件，生成对象，设置属性，`addsubview`到视图上。

{% img http://imgchr.com/images/QQ20140810-7.jpg %}

###NO 2.###

第二种方法是通过重载`initWithCoder`方法来实现，因为通过`xib`来创建一个对象会调用到这个方法，所以我们需要在这个方法里做一些处理，把这个`CustomView`的`xib`中的内容加载进来，这时同样是需要通过代码来来加载，首先附上代码

{% codeblock lang:objc %}
- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        UIView *containerView = [[[UINib nibWithNibName:@"CustomView" bundle:nil] instantiateWithOwner:self options:nil] objectAtIndex:0];
        CGRect newFrame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        containerView.frame = newFrame;
        [self addSubview:containerView];
    }
    return self;
}
{% endcodeblock %}

此外，还要这里的输出口以及设置`custom class`的位置跟第一种方式有所不同，这里需要取消掉`xib`中`view`的`custom class`，再将跟它连接的图片与文字的输出口取消掉，在这里这个`view`只是被当做一个容器来处理，它跟`Customview`没有直接关系，它将来会被`addSubview`到`CustomView`上，除此之外还要把`xib`的`File's ower`的`custom class`改成`CustomView`，表示这个`xib`文件的持有者是`CustomView`。再把它与图片和文字通过输出口连接起来。

{% img http://imgchr.com/images/QQ20140810-8.jpg %}

这个时候在运行程序就看到了我们想要的结果了。^_^

{% img http://imgchr.com/images/QQ20140810-10.jpg %}


其实想要实现第二种解决方案所要的效果，还有一种方式，它是通过重载`awakeAfterUsingCoder:`方法来实现的，这个方法的返回值会替换掉真正的加载对象，所以在具体的加载`CustomView`的方式又与第一种相同，所以`xib`的输出口连接与`custom class`的设置也与第一种解决方案相同。不过这种方式是更复杂也更难于理解的，不推荐使用，因为上一个方法就能很好的解决这个问题了，这里只是贴出这个方法的代码，有想仔细研究的请参看文章底部的参考文章。

{% codeblock lang:objc %}
- (id) awakeAfterUsingCoder:(NSCoder*)aDecoder {
    BOOL isJustAPlaceholder = ([[self subviews] count] == 0);
    if (isJustAPlaceholder) {
        CustomView* theRealThing = [[self class] getClassObjectFromNib];

        theRealThing.frame = self.frame; 

        // make compatible with Auto Layout
        self.translatesAutoresizingMaskIntoConstraints = NO;
        theRealThing.translatesAutoresizingMaskIntoConstraints = NO;

        // convince ARC that we're legit, unnecessary since at least Xcode 4.5
        CFRelease((__bridge const void*)self);
        CFRetain((__bridge const void*)theRealThing);

        return theRealThing;
    }
    return self;
}
{% endcodeblock %}

##参考资料##

>[Embedding custom-view Nibs in another Nib: Towards the holy grail][1]

>[An Update on Nested Nib Loading][2]

[1]: https://blog.compeople.eu/apps/?p=142
[2]: http://blog.yangmeyer.de/blog/2012/07/09/an-update-on-nested-nib-loading
