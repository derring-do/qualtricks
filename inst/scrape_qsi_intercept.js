//Uses legacy UI
var intercepts = [];
for(var titles = document.querySelectorAll("li[class='Element Intercept']"), i = 0; i < titles.length; i++) {
var obj = new Object();
obj.status = titles[i].children[0].title;
obj.title = titles[i].children[1].title;
intercepts.push(obj);
}
return intercepts