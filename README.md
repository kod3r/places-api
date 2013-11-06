#poi-api

##Description

poi-api is an implementation of the [OpenStreetMap API](http://wiki.openstreetmap.org/wiki/API_v0.6) written in [node.js](http://nodejs.org/) as middleware for the [express.js](http://expressjs.com/) web application framework.

##Installation

There is an installation file in the scripts directory to install this as a website
On ubunutu, you just need to run this install script and it will take care of the rest, it can be all done with this single command
`wget https://raw.github.com/nationalparkservice/poi-api/master/scripts/install-website.sh -v -O install-website.sh && sudo bash ./install-website.sh && rm ./install-website.sh`

##Usage

The idea is that you can connect any OpenStreetMap editor to this API instead of the default OpenStreetMap API. This API will offer more functionality, such as the ability to contribute to a public domain dataset and OpenStreetMap at the same time.
