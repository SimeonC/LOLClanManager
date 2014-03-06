### API Readme
This directory and it's children (if any) contain all the business logic or data driven functions of the application.

## loldb_score_scraper.coffee

This file has the code for scraping the scores off a loldb.gameguyz.net summoner profile URL.

## balance_algorithm.coffee

This file has the algorithm for balancing 2 teams and a function for rating the confidence of 2 teams.
Players must be in the format: { score: int, name: string, preference: [ 5 element array, index 0 is most preferred role INDEX, index 4 is least preferred role INDEX ], every element of array must be unique and {0,4}.
Teams are an array: [[team 0 players],[team 1 players]]