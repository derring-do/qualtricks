//Uses Experience Management UI
var creatives = [];
for(var titles = document.querySelectorAll('span[title]'), i = 0; i < titles.length; i++) {
var obj = new Object();
obj.id = titles[i].parentNode.parentNode.id;
obj.title = titles[i].title;
obj.type = titles[i].parentNode.nextSibling.nextSibling.title;
creatives.push(obj);
}
return creatives