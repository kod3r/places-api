#poi-api

##Description

poi-api is an implementation of the [OpenStreetMap API](http://wiki.openstreetmap.org/wiki/API_v0.6) written in [node.js](http://nodejs.org/) as middleware for the [express.js](http://expressjs.com/) web application framework.

##Installation

Installation has yet to be streamlined, so it's a little tricky, but it can be done quickly.

1. Create a directory for the website to reside
   `mkdir poi-website`
2. Within that directory, create the node_modules directory
   `mkdir poi-website/node_modules`
3. Clone this project into the node_modules directory
   `cd poi-website/node_modules; git clone https://github.com/nationalparkservice/poi-api.git`
4. Copy the example contents to the root of your poi-website directory
   `cp ./poi-api/examples/* ./../`
5. Rename that example.package.json to package.json
   `cd ./../; mv example.package.json package.json`
6. Run npm install in this directory, and it should put everything lese you need in place
   `npm install`
7. Go back into the poi-api directory and create the config file from the example one
  `cd ./node_modules/poi-api/; cp example.config.json config.json`
8. Use your favorite text editor to set up the name of your database and password within that config file
9. At this point, you might be thinking... well I don't have a database in [OpenStreetMap 0.6 Schema](http://wiki.openstreetmap.org/wiki/Databases_and_data_access_APIs#API). Lucky for you, there are scripts for that!
10. Navigate into the scripts directory
    `cd ./scripts`
11. There you will find the postgres.sh and osmosis.sh scripts, postgres.sh installs postgres 9.3 and osmosis. osmosis.sh will run download the state of Delaware to your computer and import it to your new database.
    `sudo bash postgres.sh`
    `sudo bash osmosis.sh`
12. This will take a while, but after it's done, you're probably ready to run the server!
    `cd ../../`
    `node app.json`

##Usage

The idea is that you can connect any OpenStreetMap editor to this API instead of the default OpenStreetMap API. This API will offer more functionality, such as the ability to contribute to a public domain dataset and OpenStreetMap at the same time.
