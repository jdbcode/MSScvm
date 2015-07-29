#' Convert MSS DN values to TOA reflectance
#'
#' Convert MSS DN values to TOA reflectance.
#' @param imgFile filename (character). Full path to *dn.tif image file produced by the \code{\link{MSSunpack}} function.  
#' @details DN values are first converted to top-of-atmosphere (TOA) radiance using the equation found \href{http://landsat.usgs.gov/how_is_radiance_calculated.php}{here}.
#' Then TOA radiance is converted to TOA reflectance using the equation found \href{http://landsathandbook.gsfc.nasa.gov/data_prod/prog_sect11_3.html}{here}.
#' The ESUN values used are from the publication 'Chander et al. 2009. Summary of current radiometric calibration coefficients... Remote Sensing of Environment. 113'. 
#' @return A 4-band Landsat MSS GeoTIFF raster image file in units of top-of-atmosphere (TOA) reflectance. The file will be placed in the
#' same directory as the 'imgFile' with the name equal to the image ID followed by 'toa_reflectance'. Note that the values are scaled by 10,000
#' and rounded to the nearest integer to reduce the file size.
#' @seealso \code{\link{MSSdn2rad}}
#' @examples \dontrun{
#' 
#' MSSdn2refl("C:/mss/LM10360321973191AAA04/LM10360321973191AAA04_dn.tif")
#' }
#' @export

MSSdn2refl = function(imgFile){
  
  print(paste("Converting",basename(imgFile),"to TOA reflectance"))
  #link to the equations to convert DN to TOA and TOA to SR
  #http://landsathandbook.gsfc.nasa.gov/data_prod/prog_sect11_3.html
  
  #define the TOA reflectance function
  refl = function(imgFile, band, gain, bias, sunzen, d, esun){
    orig = raster::raster(imgFile, band) #read in the file
    img = raster::as.matrix(orig) #convert from raster to matrix
    img = ((gain*img)+bias) #convert from DN to TOA radiance
    img[img < 0] = 0 #set all values less than 0 to 0 - negative radiance does not make sense
    img = (pi * img * (d^2))/(esun * cos(sunzen)) #convert from TOA radiance to TOA reflectance
    img = round(img * 10000) #scale by 10,000 and round to save on file size
    img = raster::setValues(orig,img) #convert from matrix to raster
    return(img) #return the TOA radiance raster
  }
  
  info = getMetadata(imgFile) #read in the image metadata
  
  #define esun values for mss (chander et al 2009 summary of current radiometric calibration coefficients... RSE 113)
  if(info$sensor == "LANDSAT_1"){esun = c(1823,1559,1276,880.1)}
  if(info$sensor == "LANDSAT_2"){esun = c(1829,1539,1268,886.6)}
  if(info$sensor == "LANDSAT_3"){esun = c(1839,1555,1291,887.9)}
  if(info$sensor == "LANDSAT_4"){esun = c(1827,1569,1260,866.4)}
  if(info$sensor == "LANDSAT_5"){esun = c(1824,1570,1249,853.4)}
  
  d = eudist(info$doy) #define the earth sun distance
  sunzen = info$sunzen*(pi/180) #get sun zenith angle in radians for cos 
  
  #apply the conversion to reflectance using the 'refl' function
  b1 = refl(imgFile,1,info$b1gain, info$b1bias, sunzen, d, esun[1]) 
  b2 = refl(imgFile,2,info$b2gain, info$b2bias, sunzen, d, esun[2])
  b3 = refl(imgFile,3,info$b3gain, info$b3bias, sunzen, d, esun[3])
  b4 = refl(imgFile,4,info$b4gain, info$b4bias, sunzen, d, esun[4])
  
  img = raster::stack(b1,b2,b3,b4) #stack the bands
  
  img = as(img, "SpatialGridDataFrame")   #convert the raster to SGHF so it can be written using GDAL (faster than writing it with the raster package)
  outfile = sub("dn", "toa_reflectance", imgFile) #define the outputs file
  rgdal::writeGDAL(img, outfile, drivername = "GTiff", type = "Int16", mvFlag = -32768, options="INTERLEAVE=BAND") #write out the TOA reflectance file
}