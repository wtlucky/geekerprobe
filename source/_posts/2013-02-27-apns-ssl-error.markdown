---
layout: post
title: "APNS服务器搭建ssl错误问题解决方案"
date: 2013-02-27 21:37
comments: true
categories: [iOS development]
tags: iOS PHP Apache APNS
---

最近再做一个推送项目，需要搭建`APNS`服务器，再将PHP代码部署到`Server`上时遇到了如下错误：
{% codeblock APNS ssl error %}
Warning: stream_socket_client() [function.stream-socket-client]: Unable to set local cert chain file `ck.pem'; Check that your cafile/capath settings include details of your certificate and its issuer in D:\AppServ\www\push1\push.php on line 24

Warning: stream_socket_client() [function.stream-socket-client]: failed to create an SSL handle in D:\AppServ\www\push1\push.php on line 24

Warning: stream_socket_client() [function.stream-socket-client]: Failed to enable crypto in D:\AppServ\www\push1\push.php on line 24

Warning: stream_socket_client() [function.stream-socket-client]: unable to connect to ssl://gateway.sandbox.push.apple.com:2195 (Unknown error) in D:\AppServ\www\push1\push.php on line 24
Failed to connect: 0
{% endcodeblock %}

上网Google之，发现很多人遇到此问题，给出的解决方案照做后错误依然存在。
最终还是自己解决，从问题本身出发吧，自己当初调试时`Server`是部署在`Mac os`上的，而现在却要部署在`Windows Server 2008`上。所以很可能是两边的配置出了问题，而代码的第24行为：
{% codeblock lang:php %}
<?php
$fp = stream_socket_client(
        'ssl://gateway.sandbox.push.apple.com:2195', $err,
        $errstr, 60, STREAM_CLIENT_CONNECT|STREAM_CLIENT_PERSISTENT, $ctx);
?>
{% endcodeblock %}
`PHP`给出的错误大概是说，没有找到证书，无法建立ssl连接。

<!--More -->

首先`.pem`证书已经制作，并且可用。还有就是证书的路径需要放正确
{% codeblock lang:php %}
<?php
stream_context_set_option($ctx, 'ssl', 'local_cert',$this->localcert);
?>
{% endcodeblock %}
确保该函数的最后一个参数所指的路径能正确找到证书。
经过测试在`Mac OS`下这样就可以了，但是在`Windows`下要改成这样：
{% codeblock lang:php %}
<?php
stream_context_set_option($ctx, 'ssl', 'local_cert',dirname(__FILE__) . '\\' .$this->localcert);
?>
{% endcodeblock %}

但是做了这些，问题仍然不能解决，剩下的问题就是`Apache`需要开启`ssl`模块，通过查看`Apache`的[官方文档](http://httpd.apache.org/docs/2.2/howto/ssi.html)得知，使用`ssl`需要`Apache`开启三个支持模块分别是：

1. mod_include
2. mod_cgi
3. mod_expires

接下来打开`Apache`的配置文件`httpd.conf`大概50-100行之间模块加载部分，放开这三个模块加载前的注释：
{% codeblock lang:apache %}
LoadModule reqtimeout_module libexec/apache2/mod_reqtimeout.so
LoadModule ext_filter_module libexec/apache2/mod_ext_filter.so
LoadModule include_module libexec/apache2/mod_include.so          #注释放开
LoadModule filter_module libexec/apache2/mod_filter.so
LoadModule substitute_module libexec/apache2/mod_substitute.so
LoadModule deflate_module libexec/apache2/mod_deflate.so
LoadModule log_config_module libexec/apache2/mod_log_config.so
LoadModule log_forensic_module libexec/apache2/mod_log_forensic.so
LoadModule logio_module libexec/apache2/mod_logio.so
LoadModule env_module libexec/apache2/mod_env.so
LoadModule mime_magic_module libexec/apache2/mod_mime_magic.so
LoadModule cern_meta_module libexec/apache2/mod_cern_meta.so
LoadModule expires_module libexec/apache2/mod_expires.so         #注释放开
LoadModule headers_module libexec/apache2/mod_headers.so
LoadModule ident_module libexec/apache2/mod_ident.so
{% endcodeblock %}

保存，重启`Apache`，再试，问题已解决。


最后附上推送部分的`PHP`代码：
{% include_code php/push.php %}
