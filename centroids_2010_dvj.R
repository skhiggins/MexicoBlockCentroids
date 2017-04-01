# CALCULATES CENTROIDS OF MANZANAS
#! created Feb 3 2015

# NOTES
#  This version of centroids*.R uses the shapefiles scraped by 
#   Diego Valle available at the link below, 
#   rather than the versions of shape files I scraped
# https://blog.diegovalle.net/2013/06/shapefiles-of-mexico-agebs-manzanas-etc.html

# CHANGES

# TO DO 

############
# PACKAGES #
############
require(foreign) #read/write.dta, read/write.csv, etc.
require(sp) #spatial objects; used by rgdal
require(rgdal) #spatial; readOGR etc.
require(rgeos) #spatial; gCentroid etc.
require(maptools) #spatial; readShapePoly etc. (requires rgeos)
require(dplyr) #package recommended by Ed Rubin

#################
# PRELIMINARIES #
#################
rm(list=ls()) # clear user-defined objects

###############
# DIRECTORIES #
###############
main   = "C:/Dropbox/FinancialInclusion/"
source(paste0(main,"_do/directories.R")) # read in directories
setwd(paste0(shps,"_2010_dvj/"))

##########
# LOCALS #
##########
# CONTROL CENTER
manzana  = 1 # census block 
ageb     = 1 # AGEB (larger than census block) centroids
loc_urb  = 1 # urban locality centroids
loc_rur  = 1 # rural locality centroids
plotbool = 1 # whether to plot ploygons and centroids (maybe slower)

# states = c( # only those in ENCEL
	# "camp",
	# "col",
	# "chis",
	# "gto",
	# "gro",
	# "hgo",
	# "mex",
	# "mich",
	# "mor",
	# "pue",
	# "slp",
	# "son",
	# "tab",
	# "tamps",
	# "tlax",
	# "ver"
# )

# ALL STATES
states = c( # listed out manually; could instead sys.glob for folders
	"ags",
	"bc",
	"bcs",
	"camp",
	"chih",
	"chis",
	"coah",
	"col",
	"df",
	"dgo",
	"gro",
	"gto",
	"hgo",
	"mex",
	"mich",
	"mor",
	"nay",
	"nl",
	"oax",
	"pue",
	"qro",
	"qroo",
	"sin",
	"slp",
	"son",
	"tab",
	"tamps",
	"tlax",
	"ver",
	"yuc",
	"zac"
)

########################
# PRELIMINARY PROGRAMS #
########################
centroidify = function(state,suffix="_manzanas",write=FALSE,as.df=FALSE,plot=TRUE) {
	# NOTE THE 2010 SHAPE FILES FROM https://blog.diegovalle.net/2013/06/shapefiles-of-mexico-agebs-manzanas-etc.html
	#  are already in lat long (see code here: https://gist.github.com/diegovalle/5843688)

	# READ IN SHAPE FILE 
	myshp = readShapePoly(paste0(state,"/",state,suffix), 
		proj4string = CRS("+proj=longlat +datum=WGS84"))
	
	# GENERATE CENTROIDS
	centroids = gCentroid(myshp,byid=T)
	class(centroids)
	
	# PLOT TO TEST THAT IT WORKED:
	if (plot==TRUE) { # runs slower but makes plots so you can see how the function is progressing
					  # through localities
		plot(myshp)
		plot(centroids,add=T,col="red")
	}
	
	# MAKE A SPATIAL POINTS DATA FRAME WITH THE BLOCK CODES AND CENTROIDS
	centroids.spdf = SpatialPointsDataFrame(centroids,data=myshp@data)
		
	# GET RID OF UNNECESSARY VARIABLES IN DATA SLOT
	centroids.spdf = centroids.spdf[,1:5]
	
	# WRITE COORDINATES AND OTHER DATA TO A .csv
	if (write==TRUE) { 
		write.csv(
			cbind(as.data.frame(coordinates(centroids.spdf)),slot(centroids.spdf,"data")),
			file=paste0(state,suffix,".csv")
		)
	}
	
	# RETURN OUTPUT
	if (as.df==TRUE) {
		centroids.df = as.data.frame(cbind(as.data.frame(coordinates(centroids.spdf)),slot(centroids.spdf,"data")))
		return(centroids.df)
	} else { # as.df==FALSE
		return(centroids.spdf)
	}
}

#######################
# CALCULATE CENTROIDS #
#######################
# Manzana
if (manzana==1) {
	mysuffix = "_manzanas"
	centroids.manz.list = lapply(states, centroidify, suffix=mysuffix, as.df=TRUE, plot=plotbool)
	graphics.off()
	centroids.manz.full = do.call(rbind,centroids.manz.list)
	dim(centroids.manz.full)
	write.csv(centroids.manz.full,file=paste0("centroids",mysuffix,".csv"))
}

# Ageb
if (ageb==1) {
	mysuffix = "_ageb_urb"
	centroids.ageb.list = lapply(states, centroidify, suffix=mysuffix, as.df=TRUE, plot=plotbool)
	graphics.off()
	centroids.ageb.full = do.call(rbind,centroids.ageb.list)
	dim(centroids.ageb.full)
	write.csv(centroids.ageb.full,file=paste0("centroids",mysuffix,".csv"))
}

# Locality (urban and semi-urban)
if (loc_urb==1) {
	mysuffix = "_loc_urb"
	centroids.locurb.list = lapply(states, centroidify, suffix=mysuffix, as.df=TRUE, plot=plotbool)
	graphics.off()
	centroids.locurb.full = do.call(rbind,centroids.locurb.list)
	dim(centroids.locurb.full)
	write.csv(centroids.locurb.full,file=paste0("centroids",mysuffix,".csv"))
}

# Locality (rural)
if (loc_rur==1) {
	#  Raw data from INEGI already comes as spatial points data frame 
	# READ IN SHAPE FILE 
	myshp = readShapePoints("national/national_loc_rur", 
		proj4string = CRS("+proj=longlat +datum=WGS84"))
	class(myshp)
	# MAKE A SPATIAL POINTS DATA FRAME WITH THE BLOCK CODES AND CENTROIDS
	centroids.spdf = SpatialPointsDataFrame(myshp,data=myshp@data)
	# GET RID OF UNNECESSARY VARIABLES IN DATA SLOT
	centroids.spdf = centroids.spdf[,1:5]
	# WRITE COORDINATES AND OTHER DATA TO A .csv
	write.csv(
		cbind(as.data.frame(coordinates(centroids.spdf)),slot(centroids.spdf,"data")),
		file="centroids_loc_rur.csv"
	)
}

#END
