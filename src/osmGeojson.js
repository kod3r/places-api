/* converts OSM XML to OSM JSON using a fast streaming parser */
var _ = require('../node_modules/osmtogeojson/lodash.custom.js'),
  htmlparser = require('../node_modules/osmtogeojson/node_modules/htmlparser2'),
  osmtogeojson = require('osmtogeojson');

var XmlParser = function() {
  var json = {
    'version': 0.6,
    'elements': []
  };
  var buffer = {};
  var p = new htmlparser.Parser({
    onopentag: function(name, attr) {
      switch (name) {
        case 'node':
        case 'way':
        case 'relation':
          buffer = {
            type: name,
            tags: {}
          };
          _.merge(buffer, attr);
          if (name === 'way') {
            buffer.nodes = [];
            buffer.geometry = [];
          }
          if (name === 'relation') {
            buffer.members = [];
            buffer.nodes = [];
            buffer.geometry = [];
          }
          break;
        case 'tag':
          buffer.tags[attr.k] = attr.v;
          break;
        case 'nd':
          buffer.nodes.push(attr.ref);
          if (attr.lat) {
            buffer.geometry.push({
              lat: attr.lat,
              lon: attr.lon
            });
          } else {
            buffer.geometry.push(null);
          }
          break;
        case 'member':
          buffer.members.push(attr);
          break;
        case 'center':
          buffer.center = {
            lat: attr.lat,
            lon: attr.lon
          };
          break;
        case 'bounds':
          buffer.bounds = {
            minlat: attr.minlat,
            minlon: attr.minlon,
            maxlat: attr.maxlat,
            maxlon: attr.maxlon
          };
      }
    },
    ontext: function() {},
    onclosetag: function(name) {
      if (name === 'node' || name === 'way' || name === 'relation' || name === 'area') {
        // remove empty geometry or nodes arrays
        if (buffer.geometry && buffer.geometry.every(function(g) {
          return g === null;
        }))
          delete buffer.geometry;
        if (name === 'relation')
          delete buffer.nodes;
        json.elements.push(buffer);
      }
      if (name === 'member') {
        if (buffer.geometry) {
          buffer.members[buffer.members.length - 1].geometry = buffer.geometry;
          buffer.geometry = [];
        }
      }
    }
  }, {
    decodeEntities: true,
    xmlMode: true
  });

  p.parseFromString = function(xmlStr) {
    p.write(xmlStr);
    p.end();
    return json;
  };
  p.getJSON = function() {
    return json;
  };
  return p;
};

module.exports = function(data) {
  var parseXml = new XmlParser();
  var returnValue = osmtogeojson(parseXml.parseFromString(data));
  returnValue.features.map(function(element) {
    console.log(element);
    for (var tag in element.properties.tags) {
      element.properties[tag] = element.properties.tags[tag];
    }
    element.properties.updated_at = element.properties.meta.timestamp;
    element.properties.updated_by = element.properties.meta.user;
    element.properties.version = element.properties.meta.version;
    delete element.properties.tags;
    delete element.properties.meta;
    delete element.properties.relations;
    return element;
  });
  return returnValue;
};
