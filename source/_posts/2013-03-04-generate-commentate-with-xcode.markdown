---
layout: post
title: "为Xcode添加生成注释服务"
date: 2013-03-04 13:05
comments: true
categories: [iOS development]
tags: Xcode 
---

`Xcode`不得不说，很好用的一款`IDE`，他集成了很多功能，但惟独没有发现为一个方法添加注释的功能。尤其是在当有大量的方法需要添加注释，而且注释的格式还要统一的时候，真的让人头疼。
在`Xcode 3.2`版本的时候，还可以找到`appledoc`插件，很方便的生成注释。但是到了`Xcode 4.0`以上的版本就找不到这个功能，虽然`appledoc`仍然可以用，但是需要使用命令行，而且生成的是`html`文件。就没有再仔细研究，继续寻找更简便的方法。
最终找到一位大神写的一段`ruby`脚本，使用它为系统添加了一项服务，使用此可以很方便为指定的方法生成指定格式的注释。
不过，测试发现这段`ruby`脚本还是有一点点问题的，在生成注释后会把当前生成注释的方法的声明删掉。我只好凭着多年的编程经验对这段脚本进行了一点修改（第一次接触到`ruby`代码。o(╯□╰)o），现在已经很好使用了，基本上没有啥问题了。分享给大家。

先展示个效果：
{% codeblock lang:objc %}
/**
 *	<#Description#>
 *
 *	@param 	application 	<#application description#>
 *	@param 	launchOptions 	<#launchOptions description#>
 *
 *	@return	<#return value description#>
 */
- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    return YES;
}
{% endcodeblock %}

<!--More -->

###如何安装使用###

所需文件：[下载](http://wtlucky.github.com/geekerprobe/downloads/XcodeAddCommentate.zip)
1. ruby脚本 `Doxygen.rb`原始的 `DoxygenNew.rb`我修改的
2. 添加服务的应用程序 `ThisService.app`

首先打开`ThisService.app`，加载`DoxygenNew.rb`
{% img http://ww4.sinaimg.cn/large/8ded26aejw1e2dppl3txtj.jpg %}

可以通过`Add option`增加一些自定义设置，这里只添加了应用程序filter，添加的该服务只有`Xcode`能使用

点`Test Service`测试服务，可以粘过一些代码过来测试。
{% img http://ww3.sinaimg.cn/bmiddle/8ded26aejw1e2dpwj5pk9j.jpg %}

测试无误后，添加服务就好了。

然后就可以在`Xcode`的服务里找到添加的这个服务了。
{% img http://ww2.sinaimg.cn/bmiddle/8ded26aejw1e2dpzqi9jhj.jpg %}

为了方便使用再为这个服务设置一个快捷键，往后在使用时，只需要选中要生成注释的方法名，按下快捷键，注释就会自动给生成了。

最后贴上我改过的`ruby`代码，希望大家根据自己的需要再进行编辑，拿出来与大家分享。
{% include_code ruby/DoxygenNew.rb %}