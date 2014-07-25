---
layout: post
title: "Swift Hexadecimal conversion"
date: 2014-07-25 15:11
comments: true
categories: [iOS development]
tags: iOS Swift
---

自己的`Blog`好久没有更新了，一个是因为这半年里要忙着毕业好多事情，再一个就是工作上也很忙，基本就没有时间来为我的`Blog`增添新的血液了。`APPLE`在`WWDC 2014`上公布了一门新的编程语言[Swift](https://developer.apple.com/swift/)，最近可以说是相当火热，而且在语言热度排名上也是突飞猛进，这是一个集合了N多语言优秀特性于一身的全新语言，它将成为开发`iOS`和`MAC`的新的选择。并且据说他将会取代`Objective-C`，但是我觉得并不是这样，不过这也仅仅是一家之谈，至于会不会这样，我们走着瞧。<!-- More -->

既然苹果放出了这样一个利器，身为`iOS开发者`的我也不能落下，`APPLE`为我们提供了两个文档[The Swift Programming Language](https://developer.apple.com/library/prerelease/ios/documentation/swift/conceptual/swift_programming_language/index.html)和[Using Swift with Cocoa and Objective-C](https://developer.apple.com/library/prerelease/ios/documentation/Swift/Conceptual/BuildingCocoaApps/index.html)。他们一个是纯语言角度的介绍`Swift`，包括各种细节语法，另一个则是介绍怎么它怎么与`Cocoa`交互，如何使用它开发`iOS`和`MAC`应用，以及如何与现有的程序兼容。学习这样一门全新的技术我还是建议读第一手资料的，虽然现在网络上有好多中文版的资料了吧，但是苹果的文档写的很是通俗易懂，读起来也没有什么困难。而起自己之前有过脚本语言的经验，所以看起来也是很快。

读完两个文档，就做一些实战的内容，先从小程序开始，之前自己写过一个`进制转换器`，没啥功能，就是提供一个十进制和十六进制互相转换的功能，主要还是为了方便自己在写一些颜色值的时候使用。之前的版本是用`Objective-C`写的，那么这次就用`Swift`重写一遍。

这个程序最主要的部分也就是两个进制相互转换的算法了，用`Objective-C`实现起来很简单，通过一下字符`char`的运算就能搞定。代码如下：
{% codeblock Hexdecimal To Decimal lang:objc %}
- (NSString *)decimalConvertedFromHexdecimal:(NSString *)hexdecimal
{
  int sum = 0;
  for (int i = 0; i < hexdecimal.length; i ++) {
    char c = [hexdecimal characterAtIndex:i];

    int num = 0;
    if (c >= 'A' && c <= 'F') {
      num = c - 'A' + 10;
    } else if (c >= 'a' && c <= 'f') {
      num = c - 'a' + 10;
    } else if (c >= '0' && c <= '9') {
      num = c - '0';
    } else {
      UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"错误"
      message:@"你提供了非法字符" delegate:nil
      cancelButtonTitle:@"知道了"
      otherButtonTitles:nil];
      [alert show];
      self.beforeConvertTextField.text = @"";
      [self.beforeConvertTextField becomeFirstResponder];
      return nil;
    }

    sum += num * pow(16, hexdecimal.length - i - 1);
  }

  return [NSString stringWithFormat:@"%d", sum];
}
{% endcodeblock %}

{% codeblock Decimal To Hexdecimal lang:objc %}
- (NSString *)hexdecimalConvertedFromDecimal:(NSString *)decimal
{
  int num = [decimal intValue];
  NSMutableString *result = [[NSMutableString alloc] initWithCapacity:0];

  while (num > 0) {
    int tmp = num % 16;
    char c = '0';
    if (tmp > 9) {
      c = 'a' + (tmp - 10);
    } else {
      c = '0' + tmp;
    }
    NSString *character = [NSString stringWithFormat:@"%c", c];
    [result insertString:character atIndex:0];
    num /= 16;
  }

  return result;
}
{% endcodeblock %}

但是当我使用`Swift`重写的时候，我进入到了一个很深的坑里，发现这项任务是如此的难做，我定义了这样两个方法，注意方法的参数和返回值：
{% codeblock Swift Code lang:objc %}
func decimalConvertedFromHexdecimal(hexdecimal: String) -> String? {
}
func hexdecimalConvertedFromDecimal(decimal: String) -> String? {
}
{% endcodeblock %}
我使用的是Swift提供的`String`类型，它是由一系列的`Character`类型的字符组成的，但是这种`Character`并不是`char`，他们在处理进制转换这个问题上让我无从下手，也有可能是我还不够熟悉，不知道正确的用法，如果有人知道欢迎告诉我。下面来说一说我遇到的问题，首先在`Swift`中是没有`‘A’`这种字符表示方法的，更不用说用它去进行运算了，其次`Character`不能进行大小比较，只能进行想等或者不等的比较，这样一来在判断一个字符所在的区间上就遇到了很大的问题。

`Swift`的`String`提供了`uft8`和`uft16`方法，返回值为`UTF8View`或者`UFT16View`，这是一个`Array`，使用`for-in`遍历他们可以输出他们的数字值，但是这个值也仅仅是能进行输出使用，他们不是`Int`也不能进行加减运算。不能进行运算在转换上就无能为力。单单从这里看来，`Swift`确实蛋疼，连这么一个小小的问题都不能搞定。

不过还好，`Swift`对`Cocoa`做了兼容使得`String`与`NSString`可以无缝转化，在使用了`NSString`后，问题的处理就变得简单多了，在`Swift`中`NSString`使用一系列的`unichar`组成的，查看声明可以看到他其实就是`UInt`，那么他就可以进行运算，所以把`String`改成`NSString`完成这两个方法。即使这样，`Swift`不支持`‘A’`这种字符的特性，也使得我们必须自己把字符转化为数值来运算，使得程序的可读性很差，还就是`Swift`的内置类型不支持隐式转换，所以在类型不一致的地方都需要强制转换一下。

这两个方法的实现在文末的代码中有，这个代码虽然完成了功能，但是还有很多需要改进和优化的地方，其次在代码风格上也需要改一下，[Raywenderlich](https://github.com/raywenderlich/swift-style-guide)的`Swift`的代码风格就很不错，非常值得套用。

最后说一下，在`iOS8`中`UIAlertView`和`UIActionSheet`被废除了，而引入的是`UIAlertController`，通过`preferredStyle`来确定类型，通过`UIAlertAction`来增加事件，然后通过`presentViewController`来显示出来，在使用上做到了统一，还是蛮方便的。

下面附上完全的代码，
{% include_code swift/HexConverterViewController.m %}
