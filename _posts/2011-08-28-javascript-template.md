---
layout: post
title: 'JavaScript模板的使用'
keywords: JavaScript, template, trimpath, Web
description: Use JavaScript template to simplify development of JavaScript.
---

随着RESTFul架构风格的兴起，越来越多的团队使用客户端MVC代替原来的服务器端MVC框架：服务器端通过URI暴露可用的资源和状态表示，客户端（如浏览器、App）则聚合不同的资源，并且显示出来。从技术实现的角度来看，浏览器客户端通常使用AJAX调用资源，带来的问题就是前端JavaScript越来越重量级，不容易维护。下面通过一个例子来说明前端JavaScript膨胀的后果，以及如何通过JavaScript模板来进行简化。

某电子商务网站中，需要查看促销商品列表及其概要信息，假设对应的页面是这样的：

{%highlight html%}
<div class="resource-holder" data-resource-uri="items/recommended">
  <table id="recommendedItems" style="display:none">
    <thead>
      <tr>
        <th>名称</th>
        <th>价格</th>
        <th>折扣</th>
        <th>描述</th>
      </tr>
    </thead>
  </table>
  <div id="noRecommendedItems" style="display: none">
    <h2>对不起, 当前没有促销商品</h2>
  </div>
</div>
{%endhighlight%}

浏览器通过AJAX获取促销商品列表，并对数据进行处理：如果没有任何促销商品，显示一条简单信息；有至少一个，则显示对应的table。默认使用jQuery类库，一般来说代码会是这样的：

{%highlight javascript linenos%}
$(function() {
  $.getJSON($(".resource-holder").attr('data-resource-uri'), function(data) {
    if(data.length > 0){
      var recommendedItemsView = RecommendedItems.renderView(data);
      $("#promotionalItems").append();
      $("#promotionalItems").show();
    }
    else{
      $("#noPromotionalItems").show();
    }
  });
});
{%endhighlight%}

其中生成表格中tbody部分的函数实现如下：

{%highlight javascript linenos%}
var RecommendedItems = (function() {
  var renderView = function(items) {
    var body = $('<tbody></tbody>');
    var i = 0;
    for (i; i < items.length; i++) {
      var item = items[i];
      var tds = '<td>' + item.name + "</td><td>" + formatter.asRMB(item.price) + "</td><td>" + formatter.asPercentage(item.discount) + "</td><td>" + item.description + "</td>";
      body.append('<tr>' + tds + "</tr>");
    }
    return body;
  };
  return {
    renderView:renderView
  };
})();
{%endhighlight%}

在上面这段JavaScript中，renderView方法根据服务器返回的JSON数据，生成需要显示的tbody内容。由于资源中，价格是数字，折扣是小数，而前端页面显示时会进行一定的格式化，请看for循环里面的两个格式化方法：formatter.asRMB会把指定的金额转换成人民币的形式显示，如10000显示成¥10,000; formatter.asPercentage会把小数显示成分成，如0.40显示成40％。最终返回的tbody会被加入到table中。

由于在JavaScript中混入了HTML的标签，导致代码可读性很差，并且很容易出错。有没有简化的方法呢？

与服务器端的模板引擎类似，JavaScript也有客户端的模板引擎类库支持，比如JST（http://code.google.com/p/trimpath/wiki/JavaScriptTemplates）就是一个轻量级的模板引擎。在页面导入相应类库（如trimpath/template.js）后，我们的页面可以优化：

{%highlight html%}
<div class="recommended-items" data-template-id='recommendedItemsTemplate' data-resource-uri="items/recommended">
</div>

<script id="recommendedItemsTemplate" style="display:none">
  {if model.items.length > 0}
    <table id="recommendedItems">
      <thead>
        <tr>
          <th>名称</th>
          <th>价格</th>
          <th>折扣</th>
          <th>描述</th>
        </tr>
      </thead>
      <tbody>
        {for item in model.items}
          <tr>
          <td>item.name</td>
          <td>item.price</td>
          <td>item.discount</td>
          <td>item.description</td>
        </tr>
        {/for}
      </tbody>
    </table>
  {else}
    <div id="noRecommendedItems">
      <h2>对不起, 当前没有促销商品</h2>
    </div>
  {/if}
</script>
{%endhighlight%}

JavaScript中的处理，简单而直接：通过Ajax请求及data-resource-uri属性调用促销商品列表，经由模板引擎渲染后，显示到页面上：
{%highlight javascript linenos%}
$(function() {
  $recommendedItems = $('.recommended-items');
  $recommendedItemsTemplate = $('#' + $recommendedItems.data('template-id'))
  $.getJSON($recommendedItems.data('resource-uri'), function(data) {
    var formattedData = RecommendedItems.formatData(data);
    var view = TrimPath.parseTemplate($recommendedItemsTemplate.html(), $recommendedItemsTemplate.process({model:formattedData})
    $recommendedItems.append(view);
  });
});
var RecommendedItems = (function() {
  var formatData = function(items) {
    var rows = [];
    var i = 0;
    for (i; i < items.length; i++) {
      rows.push({"name":items[i].planNumber,
      "price":formatter.asRMB(items[i].price),
      "discount":formatter.asPercentage(items[i].discount),
      "description":items[i].description});
    }
    return rows;
  };
  return {
    formatData:formatData
  };
})();
{%endhighlight%}

如此修改，页面呈现逻辑（AJAX调用）和格式化逻辑完全分开：页面呈现逻辑就是document.ready时执行的内容，起到了controller的作用，无需单元测试。而formatData函数只负责数据的格式化，比如金额显示成人民币的格式；折扣显示成百分比，因此职责清晰，易于编写单元测试；