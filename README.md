### Readme.md
This is the LOL Clan Manager - It's supposed to help with setting up games amongst a group of people fairly and evenly.
In future this is also supposed to take in account fixed teams with AWOL's, general clan attendance management etc.

## Getting Started

1. Install node.js
2. Run `npm install`
3. Run `npm start`
4. Navigate in your browser to http://localhost:3000/

## Site Structure

Every folder (excluding node_modules) has a readme.md file describing the purpose of the folder and what it contains, each README.md file must start with a title and the second (2nd) line must be a short one line summary of the purpose of that folder. This summary is used in the generate_structure.sh script to create the structure.md file.
The intent of the Structure.md file is to give a quick overview of where in the project a particular piece of code is likely to be contained. Useful for future support, other developers and the like.
There are only 6 root level files - app.coffee, generate_structure.sh, package.json, README.md, routes.coffee and structure.md; all other files must be in a sub directory.

#App startup

The ./app.coffee file should only contain global module inits and includes to files in other directories - this keeps it clean, the structure partitioned nicely and the closures help prevent accidental overwriting of variables.

#routes

The routing for express is done in 3 files: the main file is ./routes.coffee this contains all misc routes that don't fit anywhere else. The file for all Data calls (think JSON) that pertain specifically to API functions go in the ./api/routes.coffee file. All routes that serve HTML go in the ./views/routes.coffee.