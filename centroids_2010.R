# CALCULATES CENTROIDS OF MANZANAS
#! created Feb 3 2015

# NOTES
#   8-28-2015 Was getting topology error on some localities, so rather than read 
#              in the shapefiles with readOGR or gCentroid, had to read them in 
#              Stata using shp2dta, save as .dta, read into R as .dta, 
#              convert to spatial in R, then calculate centroids and distances


# CHANGES
#   2-24-2015 Add conversion to lat/long using UTM codes sent by Jose Solis

# TO DO 

############
# PACKAGES #
############
require(foreign) #read/write.dta, read/write.csv, etc.
require(sp) #spatial objects; used by rgdal
require(rgdal) #spatial; readOGR etc.
require(rgeos) #spatial; gCentroid etc.
require(maptools) #spatial; readShapePoly etc. (requires rgeos)
require(dplyr) 

###############
# DIRECTORIES #
###############
main   = "C:/Dropbox/FinancialInclusion/"
d_main = "D:/FinancialInclusion/"
source(paste0(main,"_do/directories.R")) # read in directories
setwd(paste0(shps,"_2010/"))

##########
# LOCALS #
##########
shapefiles = list.files(".",pattern="*_d.dta") # converted to *_d.dta by shp2dta (Stata)
print(shapefiles)

########################
# PRELIMINARY PROGRAMS #
########################
deunderscore = function(x) { # to get rid of underscores in varnames (R doesn't like them)
	new = gsub("_","",x)
	return(new)
}
centroidify = function(loc,suffix="_manzanas",write=FALSE,as.df=FALSE,plot=TRUE) {
	# FOR UTM TO LAT/LONG CONVERSION
	loczone = loczones$zutm[which(loczones$claveofi==as.numeric(loc))]
	
	if (ageb==TRUE)  { let = "a" } # agebs
	if (ageb==FALSE) { let = "m" } # manzanas

	# READ IN SHAPE FILE 
	myshp = readShapePoly(paste0(loc,let))

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
	
	if (write==TRUE) {
		write.csv(
			cbind(as.data.frame(coordinates(centroids.spdf)),slot(centroids.spdf,"data")),
			file=paste0(state,suffix,".csv")
		)
	}
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
mysuffix = "_manzanas"
centroids.manz.list = lapply(states, centroidify, suffix=mysuffix, as.df=TRUE)
graphics.off()
centroids.manz.full = do.call(rbind,centroids.manz.list)
dim(centroids.manz.full)
write.csv(centroids.manz.full,file=paste0("centroids",mysuffix,".csv"))

# Ageb
mysuffix = "_ageb_urb"
centroids.ageb.list = lapply(states, centroidify, suffix=mysuffix, as.df=TRUE)
graphics.off()
centroids.ageb.full = do.call(rbind,centroids.ageb.list)
dim(centroids.ageb.full)
write.csv(centroids.ageb.full,file=paste0("centroids",mysuffix,".csv"))

#END
