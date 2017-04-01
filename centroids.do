* SHP2DTA MANZANA SHAPE FILES TO LOAD INTO R AND CALCULATE CENTROIDS
* (Test one locality at a time)
*  created January 2015

* CHANGES

* TO DO

* NOTES
*	01-23-2015 gencentroids option of shp2dta doesn't work! centroids way outside
*				polygons. (Confirmed on Statalist that this is a bug.)
*               Instead, use R to generate centroids (centroids.R)

***************
* DIRECTORIES *
***************
global main C:/Dropbox/FinancialInclusion // !change! if using different computer
include $main/_do/directories.doh // !include!

**********
* LOCALS *
**********
local proj for_conversions
local continue = 0 // to convert all locality shape files,
	// set continue = 0; to start part way through the list 
	// (e.g. if conversion fails for one locality), set 
	// continue = 1 and mark the starting point with the 
	// failedat local:
local failedat "320570001" // if conversions fail, put number of failed locality here

*******************
* LOG AND ARCHIVE *
*******************
time 
!move /y $log/`proj'_*.log $archive/log/ // for Mac/Unix it's !mv -f instead of !move /y; /y or -f are to automatically overwrite if file exists
cap copy $do/`proj'.do $archive/do/`proj'_`time'.do
cap log close
if "`c(trace)'"=="off" cap log using $log/`proj'.log, text replace // incl if condition to avoid gigantic log files
pwd

************************
* PRELIMINARY PROGRAMS *
************************
// program to count occurances of string in a variable
cap program drop stringcount
program define stringcount
	syntax varname, searchfor(string) gen(string)
	local v `varlist'
	confirm string var `v'
	confirm new var `gen'
	tempvar cut comma
	qui gen `gen' = 0
	qui gen `cut' = `v'
	cap assert strpos(`cut',"`searchfor'")==0
	while _rc {
		qui replace `gen' = `gen'+1 if strpos(`cut',"`searchfor'")>0
		qui replace `cut' = subinstr(`cut',"`searchfor'","",1) // replace first comma
		cap assert strpos(`cut',"`searchfor'")==0
	}
end

// claveify: convert manzana codes from INEGI shapefile format (e.g., 234-8,4)
//  into 7-digit format consistent with ENCELURB data (e.g., 2348004)
//  (note: blanks will be 000000; have to check whether those exist in ENCELURB data)
cap program drop claveify
program define claveify
	syntax varname
	local v `varlist'
	gen orig_`v' = `v' // to see what it was before removing spaces etc
	tempvar forclave comma comma_m1 comma_p1 tag countcommas counthyphens
	replace `v' = subinstr(`v',"/",",",.) // some had SIN NOMBRE/SIN CLAVE
	replace `v' = subinstr(`v',"RURAL","",.)
	replace `v' = subinstr(`v'," ","",.) // some had a space before - or ,
	
	* to solve problem of one locality having 155,7,28
	stringcount `v', searchfor(",") gen(`countcommas')
	replace `v' = subinstr(`v',",","-",1) if `countcommas'==2  // replace first , with -	
	* some had eg "160-8, 161-2, SIN CLAVE" which above turned to 160-8-161-2 so:
	stringcount `v', searchfor("-") gen(`counthyphens')
	replace `v' = subinstr(`v',"-","y",2) if `counthyphens'==3 
	// now it will be solved by the code to deal with "y" below
	
	gen `comma' = strpos(`v',",")
	gen `comma_m1' = `comma'-1
	gen `comma_p1' = `comma'+1
	gen ageb = substr(`v',1,`comma_m1')
	
	* to solve problem of one locality being "53,SIN CLAVE" (will treat as SIN NOMBRE)
	replace ageb = "SINNOMBRE" if ageb=="53" | ageb=="40" | ageb=="5"
	
	replace ageb = subinstr(ageb,"-","",.)
	gen manzonly = substr(`v',`comma_p1',.)
	
	* to solve problem that some manzanas have -A at end (aren't supposed to)
	replace manzonly = subinstr(manzonly,"-A","",.)

	* to solve problem of one string that is 039-0,070-4,042-2,045-6 y 041-8,SIN CLAVE
	* (in this case they must be a bunch of blocks that are next to each other to have
	*  the same polygon...I will arbitrarily choose the first in the list, which is done
	*  automatically by lines above for ageb. Now just need to get the block at the end)
	cap assert strpos(manzonly,",")==0
	while _rc { // keep looping until no commas in any obs for manzonly var
		replace `comma' = strpos(manzonly,",") if strpos(manzonly,",")!=0
		replace `comma_p1' = `comma' + 1 if strpos(manzonly,",")!=0
		replace manzonly = substr(manzonly,`comma_p1',.) if strpos(manzonly,",")!=0
		cap assert strpos(manzonly,",")==0
	}
	
	* to solve problem of one string that is 044-3 y 090-3 (spaces deleted above)
	foreach x in y Y { // lower and upper case
		replace ageb = substr(ageb,1,strpos(ageb,"`x'")-1) if strpos(ageb,"`x'")>0 
	}

	replace manzonly = "00" + manzonly if length(manzonly)==1 // three digits
	replace manzonly = "0" + manzonly if length(manzonly)==2  // three digits
	assert manzonly!="0" & manzonly!="00" & manzonly!="000"
	replace manzonly="000" if manzonly=="SINCLAVE"
	replace ageb = "0" + ageb if length(ageb)==3 // already took out the -; usually they include the 0 but sometimes not
	replace ageb = "0000" if ageb=="SINNOMBRE" | ageb=="CAMELLON" // both "SIN NOMBRE" and other words like "CAMELLON"
	
	* solve problem of one having 1338-3,018 (extra digit, no possible match in 2010 shapefiles)
	* and another having 140-20. Arbitrarily take first 4 digits
	replace ageb = substr(ageb,1,4) if length(ageb)==5
	
	gen clave_manzana = ageb + manzonly
	cap assert length(clave_manzana)==7
	if _rc {
		gen l=length(clave_manzana)
		br if l!=7
		di as error "assertion is false"
		error 9
	}
	examples clave_manzana
	duplicates tag clave_manzana, gen(`tag')
	tab manzonly if `tag'>0 // for those with manzonly!="000", must be localities with multiple polygons
						  // can probably still get the correct centroid with gCentroid in R, 
						  // then merge back into here and drop duplicates
end

// mysaveold is 
//  -saveold- depending on version of Stata
// (created because saveold syntax of saveold changed from Stata 13 to 14
//  and need to save in Stata 12 or older to be read into R
capture program drop mysaveold
program define mysaveold // program to put rows of a matrix into Latex
	syntax anything, [replace version(integer 12)]
	if _caller()<13 {
		save `anything', `replace'
	}
	else if _caller()>=13 & _caller()<14 {
		saveold `anything', `replace'
	}
	else { // v14 or newer
		saveold `anything', version(`version') `replace'
	}
end


********
* DATA *
********
cd $inegi_shps
local folders : dir . dirs "*"
foreach folder of local folders {
	if (`continue'==1 & strpos(`"`folders'"',"`folder'") >= strpos(`"`folders'"',"`failedat'")) | (`continue'==0) { // "
		cd `folder'
		shp2dta using "`folder'_grpoc", data("`folder'_grpoc_d") coor("`folder'_grpoc_c") replace
		use `folder'_grpoc_d, clear
		keep if GEOGRAFICO=="MANZANA" // there are many polygons in the original data set 
								  // (blocks, parks, etc.) and I only want to include the Census block
		lower, except(_ID) // Sean's user written ado file
		if _N>0 claveify nombre // convert manzana names (e.g., 234-8,4 to 2348004)
			// if _N>0 is because some localities have no manzanas
		sort _ID
		mysaveold `folder'_grpoc_d, replace 
		use `folder'_grpoc_c, clear
		merge m:1 _ID using `folder'_grpoc_d, keep(match) // to keep Census blocks only
		keep _ID _X _Y // get it back to a "coordinates" style data set for spmap
		sort _ID // must be sorted by ID var for spmap
		mysaveold `folder'_grpoc_c, replace
		cd ..
	}
}

