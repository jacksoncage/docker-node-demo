var hapi = require('hapi');
var server = new hapi.Server('0.0.0.0', 8080);

server.route({
  method: 'GET'
, path: '/'
, handler: function(req, reply) {
    reply('Hello salty containers!');
  }
});

server.start(function () {
    console.log('Server running at:', server.info.uri);
});
