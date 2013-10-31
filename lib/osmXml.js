var config = require('../config'),
jsontoxml = require('jsontoxml'),
xmlSchema = require('./osmXmlSchema'),
tag = config.xml.tags,
xmlize = function(inD, schema) {
  var outD = [],
  child = {},
  newInD = {},
  newSchema,
  fieldInD = {};

  // We need to loop through all the objects in the object
  for (var key in inD) {
    ////console.log('key:', key);
    child[tag.name] = key;
    if (typeof inD[key] === 'object') {
      ////console.log('','schema found');
      for (var subKey in inD[key]) {
        ////console.log(' ', 'looking at:', key, subKey);
        if (schema && schema[key] && schema[key].attributes && schema[key].attributes.indexOf(subKey)>=0) {
          ////console.log('  ', 'it\'s an attribute', key);
          child[tag.attribute] = child[tag.attribute] ? child[tag.attribute] : {};
          child[tag.attribute][subKey] = inD[key][subKey];
        } else {
          ////console.log('  ', 'it\'s a tag', key, subKey);
          child[tag.children] = child[tag.children] ? child[tag.children] : [];
          newInD = {};
          newInD[subKey] = inD[key][subKey];
          newSchema = (schema && schema[key]) ? schema[key] : null;
          if( Object.prototype.toString.call( inD[key][subKey] ) === '[object Array]' ) {
            //console.log('   ', 'it\'s an array', key, subKey);
            for (var fieldIndex in inD[key][subKey]) {
              fieldInD = newInD;
              fieldInD[subKey] = inD[key][subKey][fieldIndex];
              child[tag.children].push(xmlize(fieldInD, newSchema));
            }
          } else if (typeof inD[key][subKey] === 'object') {
            //console.log('   ', 'it\'s a normal tag', key, subKey);
            child[tag.children].push(xmlize(newInD, newSchema));
          } else {
            //console.log('   ', 'it\'s text', key, subKey);
            child[tag.children].push({name: subKey, text: inD[key][subKey].toString()});
          }
        }
      }
    } else {
      console.log('not an object', key);
    }
    outD.push(child);
  }
  return outD;
};

exports.convert = function(inData, options) {
  var xmlHeader = config.xml.header;

  // Run the xmlize code on our json to make it into XML
  var xmlizedData = (xmlize(inData, xmlSchema));
  return [xmlHeader, jsontoxml(xmlizedData, options)].join('');
  // return xmlizedData;
};
