#!/usr/bin/env node
var Padnews;

Padnews = require('./lib/padnews');

new Padnews('sgyfCRGiBZC').run(5000, function(it){
  return console.log(it.time + " [" + (it.location || '公開') + "] " + it.content);
}, function(){
  return console.log("something updated");
});
