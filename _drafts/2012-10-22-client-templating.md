---
layout: post
title: "客户端模板技术的进一步探讨"
keywords: client templating, JavaScript template, JavaScript, EJS, Web, HTML
description: Use client side templating technology.
---

> 之前[博客](/2011/08/28/javascript-template)中提到了JavaScript客户端模板的用法，这是一种典型的RESTful架构风格。目前就服务器端而言，基于Java的Jersey、Spring都提供了服务器端API的框架，Rails、Django等其它语言的框架也提供了简单的方式支持编写API。本文将从客户端角度介绍客户端模板技术的优劣势。

### 减少带宽
对Web应用来说，页面结构存在很多的重复性，比如电商网站上的商品、博客首页的摘要、调查问卷中的问题等多个地方。这种结构的重复体现在HTML上，就是文件尺寸较大，从服务器端传递到客户端时需要较多的带宽。而且这些HTML文本是动态的，因此不能像静态资源那样很容易缓存起来。

客户端模板技术，把服务器端和客户端传输的数据格式，从HTML文本变成HTML模板和数据，HTML文本的生成也发生在客户端：

<p class="image-container small">
<a href="#"><img alt="How client templating works" src="/assets/images/server-client-html.png"></a>
</p>

### 能节省多少空间？
那么，这种转换到底能节省多少呢？我以自己开发的应用“[程序员最容易读错的单词](http://how2read.me)”的首页为例，做一个简单的对比。该应用的首页包含多个单词，以列表的方式呈现出来。除去静态资源文件，如CSS、JavaScript、Images、音频文件，从服务器端返回的主页HTML大小为21.48K。使用客户端模板技术，把模板HTML与数据分开来，我们对比发现，文件尺寸降低到了8.5k左右：

<p class="image-container middle">
<a href="#"><img alt="Using Client Templating" src="/assets/images/using-client-templating.png"></a>
</p>
这意味着，我们从服务器端传递数据时，每个请求都可以减少60%的数据传输。仅此一点，就值得我们跃跃欲试吧。

### 榨干浪费空间
至此，我们已经使首页的动态内容减少了60%。进一步发现，8.5k中包括6.4k的数据和2.1k的HTML模板。与时刻可能变化的数据相比，模板样式相对是稳定的，很少需要修改，所以我们可以认为HTML模板是静态的，可以与静态资源一样处理，包括设置缓存等等。

<p class="image-container middle">
<a href="#"><img alt="Static template and dynamic data" src="/assets/images/static-template-dynamic-data.png"></a>
</p>

可以看出，这样能够使动态内容再度减少25%左右。不过要想更好地缓存模板，最好把它们写入独立的模板文件。所幸除了TrimPath，可以多种客户端模板引擎可供选择，比如EJS, Moustache均支持独立的模板文件。

### 如何实现？
客户端模板技术给我们带来了更多性能优化的可能，而它的实现也比较简单。只需要把模板文件和动态数据绑定进行渲染即可，下面是一段示例代码：

{% highlight javascript%}
var result = new EJS({url: '/templates/room/seat.ejs'}).render({seat: this.model});
this.$el.html(result);
{%endhighlight%}

### 哪些场景适用？

+ 页面显示的内容在后台是一个集合；  
+ 页面使用了ul或li，而li的内容不是简单的文本

这些典型的应用场景中都存在这种重复性，可以通过客户端模板来解决。

### 有哪些缺点？
客户端模板引擎的使用不是没有代价。首先就是需要使用AJAX获取数据，并通过JavaScirpt客户端生成HTML文件，因此JavaScript禁用时无能为力。其次，动态获取数据，在某些情况下会对页面的SEO产生影响。

不过总结说来，榨干浪费空间，客户端模板引擎仍然是值得尝试的技术。