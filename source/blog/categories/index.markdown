---
layout: page
title: Categories & Tags
footer: true
---

##Categories##


<section>
  <span id="tag-cloud" style="font-size:12px">{% category_cloud [counter:true] %}</span>
</section>


##Tags##

<section>
 {% tag_cloud font-size: 200-325%, limit: 0, sort: rand, style: para %}
</section>