---
layout: post
title: "Create blog use Octopress and GitHub"
date: 2013-02-24 23:02
comments: true
categories: Octopress
---

###介绍###

现下大概每一个搞技术的人都会有一个技术博客，而[GitHub](http://github.com)又是广大搞程序的人都知道的一个著名代码托管网站，它的优点众多，其中之一就是GitHub Pages，他是用来给当前的project作介绍说明只用的，鉴于此我们可以将自己blog放置上去，代码交交由GitHub托管，每次我们只需要发博文上去就好，对我们来说这是一件多么爽快人心的事啊。[Octopress](http://octopress.org)就是这样一款framework，它能部署在Github上，而且很方便使用，当把它配置好之后，几条命令就可以将博文发布上去，正如官网介绍的一样`A blogging framework for hackers.`，像骇客一样的写博客，这很不错我很喜欢，具体的介绍可以去官网看。

这两者一结合就有了我现在的这个blog了，用它来记录和分享我的学习之路上点点滴滴。网络上有很多介绍安装与配置方法的文章，官网的[Documentation](http://octopress.org/docs)写的也很好，推荐E文好的直接去官网。我在安装与配置中也遇到了各种问题，不过在[Google][]的帮助下都一一解决了，你需要懂一些`ruby(jekyll)`，并且会使用`git`命令，还要使用`markdown`来书写博文，这会让你觉得是在写代码而不是在写博文。不多说了现在记录下我自己安装与配置过程，供新手与日后自己需要时参考。<!-- More -->

我主要参考的文章：
>[Octopress Documentation][1]

>[http://ishalou.com/blog/2012/10/15/how-to-use-octopress/][2]

>[http://mrzhang.me/blog/blog-equals-github-plus-octopress.html][3]

>[git 简易指南][4]

 [Google]: http://google.cn
 [1]: http://octopress.org/docs
 [2]: http://ishalou.com/blog/2012/10/15/how-to-use-octopress/
 [3]: http://mrzhang.me/blog/blog-equals-github-plus-octopress.html
 [4]: http://rogerdudler.github.com/git-guide/index.zh.html
 
 
###安装前准备工作###

1. 你需要一个[GitHub](http://github.com)的账号，注册不说了，已有的跳过。
2. 你需要在你的机器上安装并配置`git`，[官方文档](https://help.github.com/articles/set-up-git)说的很清楚，这要用到`terminal`，也就是命令行，懒的人可以安装可视化工具GitHub，我建议还是使用命令行，以为之后众多操作都是必须使用命令行来完成的，而且这对于hacker们来说也不是什么难事。
3. 为GitHub创建`SSH` Keys，[官方文档](https://help.github.com/articles/generating-ssh-keys)，这一步很重要，不然之后使用`rake deploy`命令时会出现如下错误：
{% codeblock rake deploy error lang:bash %}
## Pushing generated _deploy website
Permission denied (publickey).
{% endcodeblock %}
由于我使用GitHub比较早，这个`SSH` Key早就生成添加到了GitHub上，但是没有使用默认的名字，始终都是Permission denied。直到在GitHub上的文档中爬了很久才找到解决办法，o(╯□╰)o原来是生成的publickey没有添加到`SSH`中。
4. 你的机器要有ruby环境，`Octopress`要求的是ruby-1.9.2，现在`ruby`最新的版本是ruby-1.9.3。可以使用`ruby --version`命令来查看。如果没有该命令或者是版本低于1.9.2的话，那么就需要安装与升级`ruby`。可以使用两种方法[rbenv](http://octopress.org/docs/setup/rbenv)和[RVM](http://octopress.org/docs/setup/rvm)。具体使用方法请自行查看之，我是用的`RVM`，在安装中遇到的问题就是我是用的是MAC OX MountainLion（10.8.2）系统，xcode的版本是4.6，没有`gcc`编译器，用得是`LLVM`，而ruby-1.9.3-p385在`LLVM`下编译不通过。最终在Google和[stackoverflow](http://stackoverflow.com)帮助下解决之。

###安装Octopress###

在`terminal`下进入Octopress所要安装目录的上一级目录，敲入一下命令：
{% codeblock install Octopress lang:bash %}
git clone git://github.com/imathis/octopress.git geekerprobe      # 从GitHub上clone Octopress到本地 geekerprobe可以随便填，Octopress会被clone到当前目录的geekerprobe目录下
cd geekerprobe    # 进入该目录，如果你是用的是RVM的话，会寻问你是否信任.rvmrc文件 当然是yes
gem install bundler   # 下载bundler，有可能提示gem命令未找到，请自行google解决方法
bundler install    #安装bundler
rake install   #安装Octopress默认主题
{% endcodeblock %}
到此Octopress在本地已经安装完毕，但是还都是默认配置，而且没有发表博文。但是你可以通过一下命令来生成并预览一下原始的界面：
{% codeblock generate and preview blog lang:bash %}
rake generate    #生成blog，就是根据配置文件，将主题、模板、发表的markdown格式的博文等众多文件生成静态的html文件存放在geekerprobe/public文件夹下
rake preview   #预览生成的blog，此时ruby会启动一个小型的server
{% endcodeblock %}
接下来打开浏览器访问[http://127.0.0.1:4000](http://127.0.0.1:4000)就可以看到页面啦！
退出预览当然是Ctrl+C了。

###Octopress简单配置###

此时在`terminal`下使用‘ls’命令查看目录结构为：
{% codeblock lang:bash %}
CHANGELOG.markdown  Rakefile        plugins
Gemfile             _config.yml     public
Gemfile.lock        config.rb       sass
README.markdown     config.ru       source
{% endcodeblock %}
`\_config.yml`、`Rakefile`、`config.ru`和`config.rb`就是四个配置文件了，我们修改配置主要是在`\_config.yml`上进行的，其他的三个一般不需要我们去直接管理。`\_config.yml`的配置分为三个部分：

1. Main Configs，配置一些博客的基本信息，标题URL什么的；
2. Jekyll & Plugins，这里是jekyll和一些官方插件的配置；
3. 3rd Party Settings，这里是第三方插件配置，我们之后自己添加的插件配置信息建议都放在这个部分中。
具体说明请看[官方Document](http://octopress.org/docs/configuring/)。 
**注意：**每次做完配置文件的修改之后都要使用`rake generate`来重新生成html来使配置生效，而简单修改页面html则不需要重新生成，在预览状态下直接刷新页面就可以了。

###发布博文###

博文有两种一种是post一种是page，具体有什么区别请google之。
发送博文只需要在当前目录下：
{% codeblock lang:bash %}
rake new_post["My First Blog"]   #发送名为My First Blog的post，会在source/_post目录下按照配置文件生成markdown文件
rake new_page["title"]   #发送page，会生成在source/下，我还没有使用过具体请看官方文档
{% endcodeblock %}
使用喜欢的编辑器打开source/\_post/yyyy-mm-dd-my-first-blog.markdown进行编辑，书写博文。
{% codeblock yyyy-mm-dd-my-first-blog lang:html %}
---
layout: post
title: "My First Blog"
date: 2013-02-23 09:01
comments: true
categories: 
---

## Hello octopress! ##
{% endcodeblock %}
开头两个下划线之间的部分是`yaml`头，用来告诉Jekyll怎么处理你的posts或者是pages，在这里你可以对你的post或者page做一些设置，比如添加作者，category，是否允许评论等。
在后面就是你自己要写的东西啦，当然是使用`markdown`来写了，当然它也支持`HTML`。`markdown`很简单，还不会的看[这里](http://wowubuntu.com/markdown/#backslash),语法说明。
写完保存generate preview就可以了。

###部署到GitHub###
现在到了最关键的时候了，就是将Octopress部署到GitHub上去。从[官方文档](http://octopress.org/docs/deploying/github/)了解到，部署到GitHub上有两种一种是使用`GitHub Pages`，这种在访问时使用的url为`http://username.github.com`，username为注册的GitHub用户名，你需要在GitHub上建立名字为`username.github.com`的`repository`。第二种是使用`GitHub Project pages (gh-pages)`，这种在访问时使用的url为`http://username.github.com/reponame`,reponame为你在GitHub上建立的`repository`的名字，这个名字可以随便写，将来生成的静态html会被push到该repo下的`gh-pages`分支中。
我个人的理解是GitHub建立了这两种方式，第一种是用来介绍你这个GitHub的，所以每个账号只能有一个，而第二个是用来介绍你的`project`的，而你可以建立多个repo，所以也就可以有多个blog了，虽然url有点复杂，不过Octopress也提供了绑定自己域名的方法，自己目前还没有域名所以使用的是默认的，这一部分自己没有试验过所以就不贴上来了，具体的查看官方文档。鉴于此我使用了第二种方式来将blog部署到GitHub上。
步骤：

+ 先到GitHub上创建名为`geekerprobe`的repo。
+ 因为使用第二种方法我们要将blog放在`username.github.com`的子集目录所以我们要在本地将目录也设置为子集目录，不让会出现*“Sorry！I can not find /”*的错误，如果使用第一种方法则跳过此步骤，因为默认就是没有子集目录的。
{% codeblock lang:bash %}
rake set_root_dir[/geekerprobe]   #将路径设置为/geekerprobe
rake set_root_dir[/]   #如果你想恢复到初始目录，则键入此命令
{% endcodeblock %}
这条命令会修改`\_config.yml`、`Rakefile`和`config.rb`中的有关路径部分的设置，并将实际文件进行剪切移动操作，以适应路径的改变。而且在本地预览时也要使用子集目录来访问预览**[http://127.0.0.1:4000/geekerprobe](http://127.0.0.1:4000/geekerprobe)**。

+ 接下来就是将blog部署上去了
{% codeblock lang:bash %}
rake setup_github_pages   #将Octopress部署到GitHub上
{% endcodeblock %}
会提示你输入一个形如`git@github.com:username/geekerprobe.git`的地址，那么就按照这种形式输入你自己的repo的地址，这个地址可以在GitHub上你的repo的SSH文本框中得到，粘贴过来就好。
{% img /images/2013-2-24/repo-ssh.jpg %}
回车确定，等待片刻提示成功就可以了。
这时查看目录会发现多了一个\_deploy的文件夹，这个文件夹是一个git库，指向了GitHub上你的repo的`gh-pages`分支。同时你的repo的`gh-pages`分支在GitHub上也已被创建按。

+ 接下来生成并push博文到GitHub上
{% codeblock lang:bash %}
rake generate   #生成
rake deploy   #push到GitHub上，此时会将/public目录下的文件完全拷贝，粘贴到/_deploy目录下，然后在push
{% endcodeblock %}
如果你的GitHub的`SSH Key`没有设置或者设置错误的话，此时会出现权限不允许的错误。看到成功时就说名部署工作已经完成了，恭喜你赶紧到浏览器访问一下你的[url](http://wtlucky.github.com/geekerprobe)试试看吧。

到此基本的工作已经做完了，你的blog已经成功部署到GitHub上了并且可以正常使用了。

###使用发布博文###

{% codeblock lang:bash %}
rake new_post[]   #创建post，在editer中编辑post
rake generate     #生成静态html
rake preview      #本地预览，修改错误，查看效果
rake deploy       #无误后，push到GitHub上
{% endcodeblock %}

到此，你可以离开此页了，如果还要看其他设置的话，请看下去，我觉得这还是挺有用的，他将你的posts也同样备份到GitHub上，下次在你换了一个环境或者电脑后，就可以直接`clone`下来或者`pull`合并，免去博文与各种配置丢失。

###备份Octopress到GitHub###

此处使用的都是`git`命令，对`git`命令不熟悉的请看[这](http://rogerdudler.github.com/git-guide/index.zh.html)。

首先/geekerprobe这个目录我们是从Octopress的GitHub上`clone`下来的，所以他本是就是一个`git`库，可以通过`cat .gitignore`查看该目录被被排除在`git`库外的文件以及目录。
这些我们在`clone`之前就已经由作者做好了。我们需要做的是：
{% codeblock lang:bash %}
git remote add origin git@github.com:username/geekerprobe.git   #在远端添加源，origin可以随便写，建议用origin这是默认，后面的路径还是那个
git branch -m site    #创建一个分支site，这个site也可以随便写。官方文档使用的是master主分支
git push origin site   #将这个源push到site分支中
{% endcodeblock %}
这样你去你的GitHub上就可以看到你的repo又多了一个site分支，并且有了文件也有版本记录。

这里说一下我理解到的`git`的简单原理，我也是刚刚接触到`git`之前都是使用`subvision`的，通过配置这个blog有了一点体会，但是比较浅显，有不对之处欢迎指出。

在一个`git`库中会有文件记录你所有对库(working dir)中文件的增删改，类似于`svn`,可以使用
{% codeblock lang:bash %}
git status
{% endcodeblock %}
来查看当前的所有文件改动。
之后将显示出来的有改动的文件`add`到缓冲区(index)，通常我都是
{% codeblock lang:bash %}
git add .
{% endcodeblock %}
将所有改动都`add`到缓冲区，但这只是临时的并没有提交到remote端，也没有被提交到上次提交后的状态下。
然后就是将缓冲区的内容提交到上次提交的状态(HEAD)下
{% codeblock lang:bash %}
git commit -m "something to say"
{% endcodeblock %}
这是引号中的文字就是类似于`svn`中的版本改动说明了，现在对文件的改动依然没有提交到remote端。接下来
{% codeblock lang:bash %}
git push origin site   #将HEAD push到remote段
{% endcodeblock %}
到此本地的版本已经提交到GitHub。

###Octopress拓展增强###

要想使Octopress拥有更强大的拓展请参考一下文章：
>[安装主题][5]<br />
>[自定义样式][6]<br />
>[添加多说评论][7]<br />
>[添加标签云与category list][8]<br />

 [5]:   https://github.com/imathis/octopress/wiki/3rd-Party-Octopress-Themes
 [6]:   http://yanping.me/cn/blog/2012/01/07/theming-and-customization/
 [7]:   http://ihavanna.org/Internet/2013-02/add-duoshuo-commemt-system-into-octopress.html
 [8]:   http://blog.log4d.com/2012/05/tag-cloud/







