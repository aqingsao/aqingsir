---
layout: post
title: "HTML textarea输入框限制长度"
keywords: Web, HTML, textarea, 限制长度
description: "解决了在HTML中如何限制Text Area输入指定长度的问题"
tags: [Html]
---

textarea在Web开发中经常用到，但是它本身不支持maxlength，可以通过下面的js实现：
 
{% highlight javascript linenos %}
function limit_textarea_input() {  
    $("textarea\[maxlength\]").bind('input propertychange', function() {  
        var maxLength = $(this).attr('maxlength');  
        if ($(this).val().length > maxLength) {  
            $(this).val($(this).val().substring(0, maxLength));  
        }  
    })  
}  
{% endhighlight %}
 
通过侦听input事件(firefox, safari...)和propertychange事件(IE)，限制textarea输入框的长度。
这样给需要限制长度的输入框加上maxlength属性就可以了：

{% highlight javascript linenos %}
<textarea rows='5' cols='50' maxlength='250' name=''></textarea>  
{% endhighlight %}

然后页面加载上绑定事件即可：

{% highlight javascript linenos %}
$(limit_textarea_input)  
{% endhighlight %}
