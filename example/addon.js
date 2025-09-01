const addon = require('./addon.node');

addon(function(msg){
  console.log(msg); // 'hello world'
});
