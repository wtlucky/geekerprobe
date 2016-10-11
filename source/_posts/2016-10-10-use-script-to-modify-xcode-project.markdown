---
layout: post
title: "懒人福利：用脚本来修改Xcode工程"
date: 2016-10-10 17:59:55 +0800
comments: true
categories: [iOS development]
tags: iOS Ruby Xcode
---

懒，基本上是每个程序员同学公有的特性。也就是因为懒才造就了现在众多先进的发明，才让我们的生活省时省力起来。写这篇文章，也是因为自己犯懒，不想总是重复性的干一些固定的工作，所以通过脚本来完成。文章主要介绍了[Xcodeproj](http://rubygems.org/gems/xcodeproj)这个`Ruby`的工具包，为了使用这个工具包我还现学现卖了`Ruby`这门语言，算是个入门级选手了吧，其实真的没有想象中的那么复杂。
如果已经是能够熟练使用`Xcodeproj`的选手，就可以不用继续往下看了。^_^

<!-- More -->

先介绍下背景，我们的项目`Model`层使用了自己的ORM框架，同时也使用了`Protocol Buffer`，这也就导致了每个版本之间有新增接口，或者接口文档有变化的时候，都需要重新生成对应的`Model`文件。而这些文件每次都要手动替换`Xcode`中的现有文件，这其实是一件很枯燥很麻烦的时间，而且非常容易出错，漏掉一个文件或者少替换一个文件都是很棘手的问题。虽然我现在编写了一部分`Shell`脚本，可以直接将新生成的文件替换到`Xcode`工程所对应的物理目录中。但是即使如此，还需要对`Xcode`的工程文件作出处理，增加新文件的引用，如果不增加引用，只是把文件丢到物理目录上的话，`Xcode`工程并不会索引这个文件。同时像PB那些文件还需要添加`-fno-objc-arc`这个编译指示符，而这些文件往往有几十个之多，简直要爆炸！(不过还好有搜索批量添加的功能，暂时忍了。。)

后来就想，物理文件通过`Shell`脚本搞定了，那剩下的这个能不能也通过工具给搞定？有两个思路。

## 1. Xcode Extension
最近比较流行的就是`Xcode Extension`了，它真的是无所不能，各种各样的插件都已经存在了，我就觉得这个一定行。所以开始着手干，后来发现这个需求其实是太复杂了点儿。

首先`Xcode`插件的开发需要监测所有Xcode发出的`Notifications`，然后摘取出自己需要的，并弄清楚各个参数的类型及关系，同时还需要一定的逆向功底，找到对应Xcode控件的实现方法及如何使用，我自己尝试了下，虽然找到了几个关键的notification，但是Xcode文件管理那里各个元素分别对应何种类，着实让我头大了一把。后来随着Xcode8的发布，苹果禁掉了第三方的插件，所以这一条路自然也就走不下去了。

## 2. pbxproj文件
做过多人协作开发的同学都会遇到代码冲突的情况，而所有与工程相关的冲突都会体现在pbxproj这个文件上，这个文件就处在.xcodeproj这个目录中，这个文件其实就是整个Xcode工程的配置文件，所有的文件引用，group关系，build设置都在这里面能够找到。仔细去看他就是一个plist文件也就是一个特殊的xml文件。它的编写有着一定的规律。

所以通过对这个文件的编写也能够达到同样的目的，所以尝试着手搓一下。然而当我真正分析这个文件的时候就发现，随随便便一个工程这个文件就有着动辄上千行文字，而且内部不同数据之间的格式也都不近相同，然后每个数据之前都有一个24位的16进制数字。这个数字的生成还是一个迷之存在，感觉应该是个UUID。

截取部分文件的内容如图所示：
![](https://oac67o3cg.qnssl.com/1476154768.png )

最终经过尝试，这个文件处理啊起来也不是十分的容易，不过我在写这篇文章的时候看到一篇研究
pbxproj文件的文章，讲的十分深入透彻。[Let's Talk About project.pbxproj](http://yulingtianxia.com/blog/2016/09/28/Let-s-Talk-About-project-pbxproj/)，对这个文件感兴趣的同学推荐去阅读。

### 先人的轮子
正在上面两种策略发愁的时候，出现了柳暗花明又一村的事情，最近在阅读一篇博客的时候发现了这么一篇文章[使用代码为 Xcode 工程添加文件](http://draveness.me/bei-xcodeproj-keng-de-zhe-ji-tian/)，介绍的就是这个一个需求，才知道了又`Xcodeproj`这样一个前人已经造好的轮子了。后来一想也确实是，CocoaPods能够通过脚本完成项目工程的修改，他们一定已经做好这件事情了。

在发现这个新大陆之后，立马就开始着手准备编写适合自己需求的脚本文件。我在比之前那个作者写起来方便多了，因为现在这个工具有了完善的[文档支持](http://www.rubydoc.info/gems/xcodeproj)。这为开发提供了很大的便捷性。

我自己的需求整体上看其实就需要干两件事，因为所有文件事先已经全部移动到物理目录了，所以首先要把Xcode工程中，对应group下的所有文件删掉，然后在创建相应的group，并将文件添加到对应的group中。最后再根据需要添加编译指示的文件，添加编译指示，就完了。

那么首先就是打开工程，找到Target，一般的项目，target的第一个就是我们所需要的主target了。

{% codeblock lang:ruby %}
require 'xcodeproj'
require_relative 'functions'

project_path = File.join(File.dirname(__FILE__), "../iphone/Zhidao.xcodeproj")
project = Xcodeproj::Project.open(project_path)
target = project.targets.first
{% endcodeblock %}

拿到target之后，就要找到们所存放相应目录的group，group在`Xcodeproj`中对应这个类`PBXGroup`，通过查看文档可以找到他提供了一个`find_subpath`的方法，会从它自身这个节点根据提供的path依次向下寻找，最后一个参数为如果没有找到，是否创建这个group。拿到这个group之后，根据我自身项目的需要，因为我的group和文件的物理目录是一一对应的，还需要设置一下它的`source_tree`和`path`，对应的就是`Xcode`中的这个内容。

![](https://oac67o3cg.qnssl.com/1476179089.png )

{% codeblock lang:ruby %}
mapiGroup = project.main_group.find_subpath(File.join('Frameworks', 'Libraries', 'ZDNetManager', 'MAPI'), true)
mapiGroup.set_source_tree('<group>')
mapiGroup.set_path('MAPI')
{% endcodeblock %}

获取到了根group之后，就可以拿到他的children，然后就可以递归找到每一个文件，调用`remove_form_project`了，但是我在实际编写的过程中，发现一旦对一个文件调用了`remove_form_project`之后，那这个循环就break了，也就只执行了一次，尝试了各种方法也没找到解决方案，在Github上还找到了有人提过这个[issue](https://github.com/CocoaPods/Xcodeproj/issues/132)，但是好像也没有解决。最后通过再次翻查文档，发现还有`clear`这样一个方法，它会直接清空整个group下的所有元素，非常适合我的需求，不需要我自己去遍历了。

{% codeblock lang:ruby %}
if !mapiGroup.empty? then
    mapiGroup.clear()
end
{% endcodeblock %}

但是使用过之后，还存在问题这仅仅是在`Xcode`中左侧的`Project Navigator`中把文件引用删除了，但是对于`.m`或者资源文件这种需要加入到target中的文件，并不会直接删掉，如此一来在`Xcode`的`Build Phase`中就会看到这样的情况。文件丢失。

![](https://oac67o3cg.qnssl.com/1476179895.png )

所以针对这种情况，就需要在clear之前，对这些文件特殊处理，在target中将文件引用删掉。

{% codeblock lang:ruby %}
def removeBuildPhaseFilesRecursively(aTarget, aGroup)
	aGroup.files.each do |file|
		if file.real_path.to_s.end_with?(".m", ".mm") then 
			aTarget.source_build_phase.remove_file_reference(file)
		elsif file.real_path.to_s.end_with?(".plist") then
			aTarget.resources_build_phase.remove_file_reference(file)
		end
	end
	
	aGroup.groups.each do |group|
		removeBuildPhaseFilesRecursively(aTarget, group)
	end
end
{% endcodeblock %}

接下来是添加新的文件，首先通过`find_subpath`将所有的group创建出来，然后在将每个group下对应的文件给引用进去就可以了。这里对`.m`和资源文件还是需要单独处理，因为不光工程要引用他们，target也需要引用他们。所以先向工程添加之后拿到返回的`PBXFileReference`，在向target对应的`build_phase`添加即可。虽然target提供了增加一组文件的方法`add_file_references`，但是这样的添加方式并不能设定编译指示，一个Target的`Build rule`对应着`PBXBuildRule`，从文档中没有找到丝毫设置的方法。后来倒是发现再向target的`build_phase`中添加单个文件的时候可以设置`compiler flags`。

{% codeblock lang:ruby %}
def addFilesToGroup(aTarget, aGroup)
	Dir.foreach(aGroup.real_path) do |entry|
		filePath = File.join(aGroup.real_path, entry)
		# 过滤目录和.DS_Store文件
		if !File.directory?(filePath) && entry != ".DS_Store" then
			# 向group中增加文件引用
			fileReference = aGroup.new_reference(filePath)
			# 如果不是头文件则继续增加到Build Phase中，PB文件需要加编译标志
			if filePath.to_s.end_with?("pbobjc.m", "pbobjc.mm") then
				aTarget.add_file_references([fileReference], '-fno-objc-arc')
			elsif filePath.to_s.end_with?(".m", ".mm") then
				aTarget.source_build_phase.add_file_reference(fileReference, true)
			elsif filePath.to_s.end_with?(".plist") then
				aTarget.resources_build_phase.add_file_reference(fileReference, true)
			end
		end
	end
end
{% endcodeblock %}

最后将一切执行完之后，执行一下保存就完事儿了。

{% codeblock lang:ruby %}
project.save
{% endcodeblock %}


这篇文章没有多高深，主要就是介绍一下`Xcodeproj`这个轮子，有遇到相同类似需求的同学可以参考下，因为介绍这个轮子的资料确实太少了。。


