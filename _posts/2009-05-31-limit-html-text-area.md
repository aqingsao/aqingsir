---
layout: post
title: "HTML textarea输入框限制长度"
keywords: Web, HTML, textarea, 限制长度
description: "解决了在HTML中如何限制Text Area输入指定长度的问题"
tags: [Html]
---

textarea是多行的HTML文本输入控件，文本区中可容纳无限数量的文本。一般用于需要输入较多文本的场景，比如描述、评论、反馈、文章内容等。我们可以通过cols和rows属性，或者使用CSS的height和width属性规定其尺寸，但如何限制输入文本的长度呢？

我们希望textarea也能添加maxlength属性：

{% highlight javascript linenos %}
<textarea rows='5' cols='50' maxlength='250' name=''></textarea>  
{% endhighlight %}

可惜textarea本身不支持该属性，可以结合JavaScript实现，其基本思路是：监听用户输入事件，超出指定长度时截断文本，从而显示文本的长度。不同浏览器需监听的事件不同，一般来说，firefox、safari下的input事件，和IE浏览器的propertychange这两个事件就够了。我们使用jQuery为例：

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
 
页面加载时，为带maxlength属性的textarea输入框绑定该事件即可：

{% highlight javascript linenos %}
$(limit_textarea_input);
{% endhighlight %}
