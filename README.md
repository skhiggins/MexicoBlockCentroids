# MexicoBlockCentroids
Scrape Mexico's Census block shape files, calculate centroids

Consists of three scripts:
scrape_inegi_2010.py 
  // scrapes 2010 Census block (similar to U.S. Census tract) 
  // from website of Mexico's National Statistical Institute (INEGI) 
centroids.do 
  // converts shape files in Stata (some shape files had issues
  //  that I couldn't solve using R)
centroids_2010.R 
  // read in converted shape files and calculate their centroids in R
