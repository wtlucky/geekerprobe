---
layout: post
title: "入门bash shell脚本"
date: 2013-05-02 15:15
comments: true
categories: [Bash Shell]
tags: shell
---

在进行批量的操作，或者繁琐的操作时，可以使用`shell`编写脚本来简化操作。我使用过众多别人编写的脚本，但是自己从来没有写过。今天正好碰到一个问题，不想繁琐的去挨个操作，那么就尝试着写一个脚本来方便操作一下吧。

首先说一下自己遇到的问题，今年去参加了`CocoaChina开发者大会`，会上的`PPT`很好，今天在网上把他们下载了下来，但是问题是，他们的命名很长而且前一部分都是一样的，类似于"CocoaChina2013开发者大会-……"，前一部分都是重的，在`Finder`里看起来很是不方便，根本看不到有用的文件名信息，所以我决定要把这十多个文件重命名去掉前缀。

从来没有编写过`shell`脚本，向来都是使用`shell`命令的我，先从学习编写`shell`脚本文件开始吧！

<!-- More -->

在文本编辑器中第一行（必须是第一行）首先键入`#!/bin/sh`，符号`#!`用来告诉系统它后面的参数是用来执行该文件的程序。

####注释####
在`shell`中`#`代表注释，直到这一行结束。

####变量####
在`shell`中，变量都由字符串组成，变量名无需提前声明，写了就可以直接赋值，`变量名=值`(这里等号两边一定不能有空格)。
取变量时要使用`$`符号。有时在一长串字符串中包含变量，可以对变量名加上`{}`来区分。例如有一个变量`num=2`
`echo "this is the $numnd"`，这样会有问题，我们要写成`echo "this is the ${num}nd"`。

####流程控制####
只写一下本次用到的`for`循环，其他的流程控制以后用到时在学习。
for-loop表达式查看一个字符串列表 (字符串用空格分隔) 然后将其赋给一个变量：
for var in ....; do
　 ....
done
在下面的例子中，将分别打印ABC到屏幕上：
{% codeblock lang:bash %}
#!/bin/sh
for var in A B C ; do
　 echo "var is $var"
done
{% endcodeblock %}

这里参考的文章是[Linux shell脚本编写基础](http://blog.csdn.net/fpmystar/article/details/4183678)

在我写的`shell`脚本中则是使用循环输出当前文件夹下文件的名字：
{% codeblock lang:bash %}
#!/bin/sh
for aFile in *; do
    tmpFile=`basename $aFile`
    echo 原文件名：${tmpFile}
done
{% endcodeblock %}

接下来就是对获取到的每一个文件名的字符串进行截取，删掉不需要的部分：
{% codeblock lang:bash %}
#!/bin/sh
for aFile in *; do
    tmpFile=`basename $aFile`
    newName=${tmpFile#C*-}
    echo 原文件名：${tmpFile}
    echo 新文件名：${newName}
done
{% endcodeblock %}

这里学习了一下`shell`字符串的操作知识，`:`选取子串 `#`正向截取子串 `%`逆向截取子串 `##`正向最长匹配 `%%`逆向最长匹配。
{% codeblock lang:bash %}
str="abcdef"
expr substr "$str" 1 3  # 从第一个位置开始取3个字符， abc
expr substr "$str" 2 5  # 从第二个位置开始取5个字符， bcdef 
expr substr "$str" 4 5  # 从第四个位置开始取5个字符， def

echo ${str:2}           # 从第二个位置开始提取字符串， bcdef
echo ${str:2:3}         # 从第二个位置开始提取3个字符, bcd
echo ${str:(-2)}        # 从倒数第二个位置向左提取字符串, abcde
echo ${str:(-2):3}      # 从倒数第二个位置向左提取3个字符, cde

str="abbc,def,ghi,abcjkl"
echo ${str#a*c}         # ,def,ghi,abcjkl  一个井号(#) 表示从左边截取掉最短的匹配 (这里把abbc字串去掉）
echo ${str##a*c}        # jkl，             两个井号(##) 表示从左边截取掉最长的匹配 (这里把abbc,def,ghi,abc字串去掉)
echo ${str#"a*c"}       # 空,因为str中没有子串"a*c"
echo $[str##"a*c"}      # 空,同理
echo ${str#d*f)         # abbc,def,ghi,abcjkl, 
echo ${str#*d*f}        # ,ghi,abcjkl   

echo ${str%a*l}         # abbc,def,ghi  一个百分号(%)表示从右边截取最短的匹配 
echo ${str%%b*l}        # a             两个百分号表示(%%)表示从右边截取最长的匹配
echo ${str%a*c}         # abbc,def,ghi,abcjkl  
{% endcodeblock %}

这里参考的文章[Bash Shell字符串操作小结](http://my.oschina.net/aiguozhe/blog/41557)

最后就是将文件重命名了：
{% codeblock lang:bash %}
#!/bin/sh
for aFile in *; do
    tmpFile=`basename $aFile`
    newName=${tmpFile#C*-}
    echo 原文件名：${tmpFile}
    echo 新文件名：${newName}
    mv $tmpFile $newName
done
{% endcodeblock %}

运行时发现只有部分文件被成功重命名了，其余的都不成功，而这些不成功的文件名中都包含空格，空格是很大一个问题，在获取原文件名时文件名就被空格截断了，导致文件名不全。因而重命名也是失败的，找不到源文件。
参考这篇文章[SHELL技巧：处理文件名中的那些空格](http://www.cnblogs.com/cocowool/archive/2013/01/15/2861904.html)
找到了解决方法，对变量添加`""`使空格被正确处理，这不是最好的方法，但是在我这个小小的脚本中完全可以了。

文章中还介绍了一种终极解决方法就是设置`IFS(the Internal Field Separator)`，但是在设置之前先保存当前的`IFS`，操作完成之后在设置回去。
{% codeblock lang:bash %}
#!/bin/sh
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

#进行操作

IFS=$SAVEIFS
{% endcodeblock %}

但是我这样使用之后经过测试发现，并不能解决问题，文件名被读取成其他怪异的形式了，空格是被正常读取了但是`-`也被读取成空格了，我不知道这是为什么，有知道的欢迎告诉我。

最后附上自己写的完整的`shell`脚本，虽然很短，但这是第一次写，也算是个入门吧。
{% codeblock lang:bash %}
#!/bin/sh

#===============将文件名的前缀部分去掉=============
#====处理文件名中带空格的问题，先保存$IFS变量，经测试这么做还是会有问题部分字符会丢失
#SAVEIFS=$IFS
#IFS=$(echo -en "\n\b")
for aFile in *; do
    #对变量加上双引号会避免文件名中有空格的问题
    tmpFile=`basename "$aFile"`
    #截取文件名字符串中的前一部分
    newName=${tmpFile#C*-}
    echo 原文件名：${tmpFile}
    echo 新文件名：${newName}
    #对文件进行重命名
    mv "$tmpFile" "$newName"
done
#=====将$IFS恢复为原来的状态
#IFS=$SAVEIFS
{% endcodeblock %}


###总结一下需要注意的地方###
1. 在写`shell`脚本时不能延续写其他代码乱加空格的习惯，空格在`shell`中很重要，随便加空格会导致`shell`脚本执行失败。
2. 还是空格问题，使用`basename`命令时，获取到的文件名如果有空格的话将不会获取之后部分，可以对变量添加`""`解决问题。
3. `cp` `mv`等命令要求文件命中同样不能有空格，也可以在脚本中对变量添加`""`解决。
4. 刚开始写`shell`脚本时最好写一句测试一句，要严谨不能想当然。
 