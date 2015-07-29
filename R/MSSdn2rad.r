#' Convert MSS DN values to TOA radiance
#'
#' Convert MSS DN values to TOA radiance.
#' @param imgFile filename (character). Full path to *dn.tif image file produced by the \code{\link{MSSunpack}} function.
#' @details The equation used to convert DN to TOA radiance can be found \href{http://landsat.usgs.gov/how_is_radiance_calculated.php}{here}.
#' @return A 4-band Landsat MSS GeoTIFF raster image file in units of top-of-atmosphere (TOA) radiance. The file will be placed in
#' same directory as the 'imgFile' with the name equal to the image ID followed by 'toa_radiance'. Note that the values are scaled by 100
#' and rounded to the nearest integer to reduce the file size.
#' @seealso \code{\link{MSSdn2refl}}
#' @examples \dontrun{
#' 
#' MSSdn2rad("C:/mss/LM10360321973191AAA04/LM10360321973191AAA04_dn.tif")
#' }
#' @export

MSSdn2rad = function(imgFile){
  
  print(paste("Converting",basename(imgFile),"to TOA radiance"))
  info = getMetadata(imgFile) #get image metadata
  b = raster::brick(imgFile) #load the DN image as a brick
  img = raster::as.array(b)  #convert the brick to an array

  img[,,1] = round(100*((info$b1gain*img[,,1])+info$b1bias)) #convert fro DN to radiance and scale by 100 and round
  img[,,2] = round(100*((info$b2gain*img[,,2])+info$b2bias)) #convert fro DN to radiance and scale by 100 and round
  img[,,3] = round(100*((info$b3gain*img[,,3])+info$b3bias)) #convert fro DN to radiance and scale by 100 and round
  img[,,4] = round(100*((info$b4gain*img[,,4])+info$b4bias)) #convert fro DN to radiance and scale by 100 and round
  
  img[img < 0] = 0 #you can't have negative radiance - set negative values to 0
  
  img = raster::setValues(b,img) #convert the array to a brick 
  img = as(img, "SpatialGridDataFrame") #convert the brick to SGHF to be written by GDAL
  outfile = sub("dn", "toa_radiance", imgFile) #define output filename
  rgdal::writeGDAL(img, outfile, drivername = "GTiff", type = "Int16", mvFlag = -32768, options="INTERLEAVE=BAND") #write the file
}
  
