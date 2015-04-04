## Description

places-api is an implementation of the [OpenStreetMap API](http://wiki.openstreetmap.org/wiki/API_v0.6) written in [node.js](http://nodejs.org/) as middleware for the [express.js](http://expressjs.com/) web application framework.

##API Installation

The places-api acts as middleware for [express.js](https://github.com/strongloop/express), and cannot run on its own.
The [places-website](https://github.com/nationalparkservice/places-website) is designed to be a container for the places-api.

The following steps are designed to be copied and pasted directly into your CLI.

####\#1. Clone the [places-website](https://github.com/nationalparkservice/places-website)
  `git clone https://github.com/nationalparkservice/places-website.git`
####\#2. Change directory to places-website
  `cd places-website`
####\#3. Install the components
  `npm install`
####\#4. Copy the example.config.json to config.json
  `cp example.config.json config.json`
####\#5. Open the config.json with your favorite text editor and change the values to match your settings
  ```which subl || which vim` config.json``
####\#6. You're ready to run the website!
  `npm start`

##\#Database Setup
\#This guide will detail the steps to installing the PostGIS database on an ubuntu machine.
\#There is a [guide for windows](https://github.com/nationalparkservice/places-api/blob/places-api/scripts/tools/windowsInstall.txt) as well.

####\#1. Change to the API directory
  `cd ./node_modules/places-api/`

####\#2. Run the postgresql 9.4 and PostGIS 2.1 install script here:
  `bash ./scripts/install_postgres_9.4.sh`

####\#3. Either clone an existing set of places_api databases or run the database setup script:
  `bash ./scripts/create_osm_db.sh`

## Usage

The iD editor that is include will not work be default, since it needs to be built.
You will need to remove the places-editor from the /node_modules directory and clone it in instead
This is to ensure that you have all the dev dependencies.

After, it's cloned, edit the js/id/id.js file's npmap variable to reflect the path to your server/port.

Once you do that, run an `npm install` on it and the `make` command.

You can then navigate to http://SERVER:PORT/dist and start editing the map!
