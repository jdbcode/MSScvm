#' Landsat MSS cloud and cloud shadow masking
#' 
#' Creates a cloud and cloud shadow mask for Landsat MSS imagery.
#' @param imgDir directory name (character). Full path to a MSS image directory produced by the \code{\link{MSSunpack}} function.
#' @param demFile filename (character). Full path to image-corresponding DEM file.
#' @param classify logical. If TRUE clouds, cloud shadows, and clear pixels have unique values (0 = clear, 1 = cloud shadow, 2 = cloud). 
#' If FALSE obscured pixles = 0 and clear = 1.
#' @details It is important that the input DEM file, specified by the 'demFile' parameter, be the same projection and pixel resolution as the
#' input image. It must also be >= in spatial extent, relative to the image. The program will check for these attributes and throw an error message if 
#' there is a violation. There are two helper functions to prepare a suitable DEM. Use the \code{\link{reprojectDEM}} function to ensure proper projection
#' and pixel resolution of an exisiting DEM, and the \code{\link{mosaicDEMs}} function to create a mosaic from several DEMs to ensure proper extent, projection, 
#' and pixel resolution. 
#' @return A GeoTIFF raster image file with the same dimensions as the MSS image. The file will be placed in the
#' 'imgDir' directory with the name equal to the image ID followed by '_msscvm'.
#' @examples 
#' \dontrun{
#' 
#' MSScvm(imgDir = "C:/mss/LM10360321973191AAA04", 
#'        demFile = "C:/mss/dem/wrs1_p036r032_dem.tif")
#' }
#' @export


MSScvm = function(imgDir, demFile, classify=F){
  
  
  
  #get the image file and check
  files = list.files(imgDir, full.names=T)
  refl_match = grep("toa_reflectance.tif$", files)
  if(length(refl_match) != 1){
    dn_match = grep("dn.tif$", files)
    if(length(dn_match) != 1){
      print(paste("Can't find a '*toa_reflectance.tif' or '*dn.tif' file in the directory:", imgDir))
      print("Please check that the 'imgDir' parameter path is correct and that it contains either a '*toa_reflectance.tif' or '*dn.tif' file")
      stop("Stopping MSScvm")
    } else {
      match = dn_match
      imgtype = "dn"
    }
  } else {
    match = refl_match
    imgtype = "refl"
  }
  
  imgfile = files[match]
  print(paste("Making cloud & shadow mask for",basename(imgfile)))
  
  #get some info about the image
  ref = raster::raster(imgfile) #read in the MSS file for information on image extent and as a template for holding values later
  dem = raster::raster(demFile) #read in the DEM file - raster package function
  demproj = raster::projection(dem)
  imgproj = raster::projection(ref)
  demres = raster::xres(dem)
  imgres = raster::xres(ref)
  
  #check to make the DEM and image resolutions are the same
  if(demres != imgres){
    print(paste("The DEM file:",demFile,"does not have the same pixel resolution as the image file."))
    print("Please make sure the DEM file has the same pixel resolution as the image file. Use the function 'reprojectDEM' to assist in getting it in the same resolution")
    stop("Stopping MSScvm")
  }
  
  #check to make the DEM and image projections are the same
  if(demproj != imgproj){
    print(paste("The DEM file:",demFile,"does not have the same projection as the image file."))
    print("Please make sure the DEM file is the same projection as the image file. Use the function 'reprojectDEM' to assist in getting it in the same projection")
    stop("Stopping MSScvm")
  }

  #check to make sure the extent of teh DEM is at least as big as the image
  demext = raster::extent(dem)
  imgext = raster::extent(ref)

  demokay = demext@ymax >= imgext@ymax & 
            demext@ymin <= imgext@ymin & 
            demext@xmin <= imgext@xmin & 
            demext@xmax >= imgext@xmax 
   
  if(demokay == F){
    print(paste("The DEM file:",demFile,"does not fully intersect the image file."))
    print("Please make sure the DEM file is larger in extent than the image file. Use the function 'mosaicDEMs' to assist in making a larger DEM")
    stop("Stopping MSScvm")
  }

  #get some info about the image
  info = getMetadata(imgfile) #get the image MTL metadata: sunelev, sunaz, sunzen, gain, bias, sensor, etc - used in calulating illumination and in projecting clouds
  reso = raster::xres(ref) #get the image resolution - it should be 60m - used during cloud projection 
  sunzen = info$sunzen*(pi/180) #get sun zenith angle in radians for cos

  
  if(imgtype == "dn"){
    #convert from DN to TOA reflectance
    #define the TOA reflectance function
    refl = function(file, band, gain, bias, sunzen, d, esun){
      img = raster::as.matrix(raster::raster(file, band)) #read in the file
      img = (gain*img)+bias #convert to TOA radiance #link to equations to convert DN to TOA radiance - http://landsat.usgs.gov/how_is_radiance_calculated.php
      img[img < 0] = 0 #make sure values less than 0 are set to 0 - negative radiance doesn't make sense
      img = (pi * img * (d^2))/(esun * cos(sunzen)) #convert from TOA radiance to TOA reflectance  #link to the equations to convert TOA radiance to TOA reflectance - http://landsathandbook.gsfc.nasa.gov/data_prod/prog_sect11_3.html
      img = round(img * 10000) #scale by 10000 and round so we aren't working with floating point
      return(img) #pass the TOA reflectance image back
    }
    
    #define esun values for MSS (chander et al 2009 summary of current radiometric calibration coefficients... RSE 113)
    if(info$sensor == "LANDSAT_1"){esun = c(1823,1559,1276,880.1)} #for "LANDSAT 1"
    if(info$sensor == "LANDSAT_2"){esun = c(1829,1539,1268,886.6)} #for "LANDSAT 2"
    if(info$sensor == "LANDSAT_3"){esun = c(1839,1555,1291,887.9)} #for "LANDSAT 3"
    if(info$sensor == "LANDSAT_4"){esun = c(1827,1569,1260,866.4)} #for "LANDSAT 4"
    if(info$sensor == "LANDSAT_5"){esun = c(1824,1570,1249,853.4)} #for "LANDSAT 5"
    
    #prepare some variables for converting DN to TOA reflectance
    d = eudist(info$doy) #get the earth sun distance for the image day-of-year

    #apply the TOA reflectance function to the DN MSS image bands 1, 2, and 4
    b1 = refl(imgfile, 1 ,info$b1gain, info$b1bias, sunzen, d, esun[1]) #get TOA reflectance for MSS band 1
    b2 = refl(imgfile, 2 ,info$b2gain, info$b2bias, sunzen, d, esun[2]) #get TOA reflectance for MSS band 2
    b4 = refl(imgfile, 4 ,info$b4gain, info$b4bias, sunzen, d, esun[4]) #get TOA reflectance for MSS band 4
  } 
  

  if(imgtype == "refl") {
    #load in the image bands
    b1 = raster::as.matrix(raster::raster(imgfile, 1)) #band 1
    b2 = raster::as.matrix(raster::raster(imgfile, 2)) #band 2
    b4 = raster::as.matrix(raster::raster(imgfile, 4)) #band 4
  }
  
  
  #crop the hillshade layer
  dem_ex  = raster::alignExtent(dem, ref, snap="near") #aligned the extent of the DEM to the image - raster package function
  raster::extent(dem) = dem_ex #set the DEM extend to aligned extent - raster package function
  dem = raster::crop(dem,ref) #crop the DEM to size of the image
  
  
  #make slope, aspect, and illumination images - used for topographic correction
  slope = raster::terrain(dem, opt="slope") #create slope from preped DEM
  aspect = raster::terrain(dem, opt="aspect") #create slope from preped DEM
  ill = raster::as.matrix(raster::hillShade(slope, aspect, angle=info$sunelev, direction=info$sunaz, normalize=F)) #create illumination from slope and aspect, convert to matrix for faster processing
  
  
  #apply topographic correction to band 4 for identifying cloud shadows
  k=0.55 #set the k constant
  c = (cos(sunzen)/ill)^k #apply the minnaert topographic correction
  b4topoc = round(b4*c) #round the values - probably not important, possibly faster processing and saves memory
  
  
  #identify the cloud pixels
  ndgr = (b1-b2)/(b1+b2) #normalized difference between MSS band 1 and 2
  clouds = which(ndgr > 0.0 & b1 > 1750 | b1 > 3900) #apply cloud thresholds to "ndgr" and on band 1 
  
  
  #find cloud shadows
  #model the topo-corrected band 4 cloud shadow theshold  
  b4topoc[clouds] = NA #set the cloud pixels in topo-corrected band 4 to NA
  b4nocldmean = mean(b4topoc, na.rm=T) #get the mean of the non-cloud pixel in topo-corrected band 4
  shadowthresh1 = round(0.40 * b4nocldmean + 247.97) #apply line equation to calculate the provisional topo-corrected band 4 cloud shadow theshold 
  nocldorshdw = which(b4topoc > shadowthresh1) #find the topo-corrected band 4 pixels that are considered provisional cloud shadow 
  b4nocldorshdw = b4topoc[nocldorshdw] #pull out the topo-corrected band 4 pixels that are not cloud shadow
  b4nocldorshdwmean = mean(b4nocldorshdw, na.rm=T) #get the mean of the non-cloud, non-provisional cloud shadow pixels in topo-corrected band 4
  shadowthresh2 = round(0.47 * b4nocldorshdwmean + 73.23) #apply line equation to calculate the final topo-corrected band 4 cloud shadow theshold 
  
  #identify the cloud shadow pixels
  shadows = which(b4topoc <= shadowthresh2) #apply cloud shadow threshold to topo-corrected band 4
  
  
  #find water
  slope = raster::as.matrix(slope) #convert slope to matric for faster processing 
  ndvi = (b4-b2)/(b4+b2) #calculate NDVI from MSS band 2 and 4
  waterpixels = which(ndvi < 0.0850 & slope < (0.5*(pi/180))) #apply thresholds to ndvi and slope - looking for nearly flat pixels that look like water in NDVI 
  
  
  #make some blank matrices to holder the water, shadow, and cloud layers
  b1[] = 0 #set all the pixels in MSS band 1 matrix to 0 as a image template holder
  water=shadow=cloud=b1 #copy the template holder as a water, shadow, and cloud layer
  
  
  #reduce used data
  b1=b2=b4=ill=slope=ndgr=b4nocldorshdw=b4topoc=nocldorshdw=0 #reduce memory
  
  
  #spatial sieve on water clumps that are too small (produces better looking and more accurate final mask) 
  water[waterpixels] = 1 #in the empty water layer, set the water pixels to value 1 (all other values are 0)
  #clumps = .Call("ccl", water, PACKAGE = "SDMTools") #find clumps of water pixels  
  clumps = SDMTools::ConnCompLabel(water)
  clumps = raster::setValues(ref, clumps) #convert the clumps image (which is a matrix) into a raster
  fre = raster::freq(clumps) #use the raster function "freq" to count the number of pixels in each clump
  these = which(fre[,2] < 7) #find the clumps that are smaller than 7 pixels (we don't consider these as water - just noise)
  values = fre[these,1] #pull out the too-small clump id values from the frequency table
  m = match(raster::as.matrix(clumps), values) #first convert the clumps raster to a matrix for faster processing, then identify too-small clumps
  these = which(is.na(m) == F) #find which pixels are associated with too-small clumps
  water[these] = 0 #set the too-small clump pixels as 0 (not water) in the water layer
  
  
  #apply a 2-pixel buffer to the sieved water layer - helps capture mixed shore/water pixels
  water = raster::setValues(ref,water) #convert the water layer from matrix to raster so the raster "focal" function can be used
  water = raster::focal(water, w=matrix(1,5,5), fun=max, na.rm=T) #use the raster focal function to apply a buffer around water clumps
  waterpixels = which(raster::as.matrix(water) == 1) #convert water back to matrix for faster processing and identify the water pixels
  
  
  #set the cloud shadow layer 
  shadow[shadows] = 1 #in the empty cloud shadow layer, set the cloud shadow pixels to value 1 (all other values are 0) 
  shadow[waterpixels] = 0 #set the water pixels to 0 (not cloud shadow)
  
  
  #set the cloud layer
  cloud[clouds] = 1 #in the empty cloud layer, set the cloud pixels to value 1 (all other values are 0)
  
  
  #spatial sieve on cloud clumps that are too small (produces better looking and more accurate final mask) -same process as above for water layer 
  #clumps = .Call("ccl", cloud, PACKAGE = "SDMTools")  
  clumps = SDMTools::ConnCompLabel(cloud)
  clumps = raster::setValues(ref, clumps)
  fre = raster::freq(clumps)
  these = which(fre[,2] < 10) #note that this sieve size is < 10 (water is < 7)
  values = fre[these,1]
  m = match(raster::as.matrix(clumps), values) 
  these = which(is.na(m) == F)
  cloud[these] = 0
  
  
  #apply a 2-pixel buffer to the sieved cloud layer - helps capture cloud edges - same process as for the above water layer
  cloud = raster::setValues(ref,cloud)
  cloud = raster::focal(cloud, w=matrix(1,5,5), fun=max, na.rm=F, pad=T, padValue=0)
  
  
  #getting ready to project the cloud layer out as potential area of cloud shadow
  #create a kernal to slide over the cloud layer
  r = raster::raster(ncol=31,nrow=31) #create a 1860m square raster
  ext = raster::extent(0, 31, 0, 31) #define its extent
  raster::extent(r) = ext #set its extent
  raster::projection(r) = imgproj #set its projection
  r[] = NA #fill the raster with NA
  r[16,16] = 1 #set the center pixel of the raster to 1 
  dist = raster::gridDistance(r, 1) #find the distance of all pixels in the raster to the center pixel
  kernal = dist <= 16 #set all pixel in raster that have a distance to the center pixel <= 16 as 1 - creates a circular pattern of value 1 around the center of the raster with a radius of 15 pixels (900m) 
  
  
  #put a 15 pixel buffer around the clouds in the cloud layer
  cloudproj = raster::focal(cloud, w=raster::as.matrix(kernal), fun=max, na.rm=F, pad=T, padValue=0) #w needs to be a matrix, but kernal is a raster 
  
  #set up the start and end points of the cloud projection based on the image's sun elevation and a low cloud height of 1000m and high cloud height of 7000m
  shiftstart = 1000/tan((pi/180)*info$sunelev) #calculate the starting distance
  shiftend = 7000/tan((pi/180)*info$sunelev) #calculate the ending distance
  shiftlen = seq(shiftstart,shiftend,900) #create a sequence of equal interval distances (900m) between the start and end distances
  
  
  #create a function to shift the cloud image a distance away from its original position
  shiftit = function(cloudproj,shiftlen,info,reso){
    if(info$sunaz > 90 & info$sunaz <= 180){ #sun projects to the NW
      #do some trigonometry to figure out how many meters in x and y the shift needs to be made, based on the sun azimuth and projection length 
      angle = info$sunaz - 90  #need to get the azimuth in the right context
      yshift = round((sin((pi/180)*angle) * shiftlen *  1)/reso)*reso #calculate the y shift
      xshift = round((cos((pi/180)*angle) * shiftlen * -1)/reso)*reso #calculate the x shift
      
      #shift the cloud projection layer
      cloudproj = raster::shift(cloudproj, x=xshift, y=yshift)
    }
    if(info$sunaz > 0 & info$sunaz <= 90){ #sun projects to the SW
      angle = 90 - info$sunaz
      yshift = round((sin((pi/180)*angle) * shiftlen * -1)/reso)*reso
      xshift = round((cos((pi/180)*angle) * shiftlen * -1)/reso)*reso
      cloudproj = raster::shift(cloudproj, x=xshift, y=yshift)
    }
    if(info$sunaz <= 0 & info$sunaz >= -90){ #sun projects to the SE
      angle = info$sunaz - -90
      yshift = round((sin((pi/180)*angle) * shiftlen * -1)/reso)*reso
      xshift = round((cos((pi/180)*angle) * shiftlen *  1)/reso)*reso
      cloudproj = raster::shift(cloudproj, x=xshift, y=yshift)
    }
    if(info$sunaz <= -90 & info$sunaz >= -180){ #sun projects to the NE
      angle = -90 - info$sunaz
      yshift = round((sin((pi/180)*angle) * shiftlen *  1)/reso)*reso
      xshift = round((cos((pi/180)*angle) * shiftlen *  1)/reso)*reso
      cloudproj = raster::shift(cloudproj, x=xshift, y=yshift)
    }
    return(cloudproj)
  }
  
  
  #iterate through all the shift distances using the "shiftit" function just defined - it will create rasters on-the-fly and write a line of code to combine each shift into a mosaic 
  for(m in 1:length(shiftlen)){
    if(m == 1){mergeit = "r1"} else {mergeit = paste(mergeit,",r",m, sep="")}
    dothis = paste("r",m,"=shiftit(cloudproj,shiftlen[m],info,reso)", sep="")
    eval(parse(text=dothis))
    if(m == length(shiftlen)){mergeit = paste("cloudproj = raster::mosaic(",mergeit,",fun=max)", sep="")}
  }
  
  
  #run the mosiac line of code created above
  eval(parse(text=mergeit))
  
  
  #prepare the the cloudproj layer for intersecting the cloud shadow layer
  cloudproj[!is.finite(raster::values(cloudproj))] = 0 #make sure that all values are finite in the cloud projection layer, the mosaicing function with max can cause some problems where there are no pixels
  cloudproj = raster::extend(cloudproj, cloud, value=0) #extend the cloud projection layer so it has a full union with the cloud layer
  cloudproj = raster::crop(cloudproj, cloud) #crop the cloud projection layer by the cloud layer
  
  
  #convert the cloud shadow layer to a raster to match the class of the cloud projection layer
  shadow = raster::setValues(ref,shadow)
  
  
  #get the intersection of the cloud shadow layer and cloud projection layer
  shadow = shadow*cloudproj
  
  
  #convert the final cloud shadow layer to a matrix for spatial sieve
  shadow = raster::as.matrix(shadow)
  
  
  #spatial sieve on cloud shadow clumps that are too small (produces better looking and more accurate final mask) - same process as above for water and cloud layer 
  #clumps = .Call("ccl", shadow, PACKAGE = "SDMTools")  
  clumps = SDMTools::ConnCompLabel(shadow)
  clumps = raster::setValues(ref, clumps)
  fre = raster::freq(clumps)
  these = which(fre[,2] < 10) #note that this sieve size is < 10 (water is < 7)
  values = fre[these,1]
  m = match(raster::as.matrix(clumps), values) 
  these = which(is.na(m) == F)
  shadow[these] = 0
  shadow = raster::setValues(ref, shadow)
  
  
  #apply a 2-pixel buffer to the sieved cloud shadow layer - helps capture shadow edges - same process as for the above water and cloud layer
  shadow = raster::focal(shadow, w=matrix(1,5,5), fun=max, na.rm=F, pad=T, padValue=0)
  
  
  #deal with either classifying cloud, cloud shadow, and clear-view separately or treat as binary obsured/clear-view
  if(classify == T){  #if classify == T, then cloud, cloud shadow, and clear view will each be assigned a unique value clear-view=0, cloud shadow=1, cloud=2
    cloud = cloud*2 #if classify == T make the cloud pixels in the cloud layer have a value of 2, clear-view is already 0 and cloud shadow is already 1
    cloudshadow = raster::mosaic(cloud,shadow,fun=max, na.rm=T) #create a mosaic of the cloud, and cloud shadow layers - cloud takes precedence where they overlap
  } else { #if classify == F, then 
    cloudshadow = sum(cloud, shadow, na.rm=T) #combine the cloud and cloud shadow layers
    cloudshadow = raster::setValues(ref,as.numeric(raster::values(cloudshadow) == 0)) #set obscured pixels to value 0 and clear-view to 1. This makes for easy masking of images, just multiply the mask by the image
  } 
  
  
  cloudshadow[is.na(ref)] = NA
  cloudshadow = as(cloudshadow, "SpatialGridDataFrame")
  #write out the mask
  outfile = file.path(dirname(imgfile),paste(substr(basename(imgfile),1,21),"_msscvm.tif",sep="")) #define a file name for the mask - uses same directory as the image and then use the image ID and appends "_cloudmask.tif" for the name
  rgdal::writeGDAL(cloudshadow, outfile, drivername = "GTiff", type = "Byte", mvFlag=255) #write out the mask - no compression
  
}