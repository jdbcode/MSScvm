#' Reproject a DEM file
#'
#' Reproject a DEM file to match the projection and pixel resolution of an image file. A helper function to make a DEM
#' conform to the properties of an image file prior to using it as an input to the \code{\link{MSScvm}} masking function.
#' @param demFile filename (character). Full path to DEM file.
#' @param projRef filename (character). Full path to an image file produced by the \code{\link{MSSunpack}} function.
#' @param srcNodata numeric. Specify the background value in the input DEM. If there is no background value, use NA (default).
#' @param dstNodata numeric. Specify the value to represent background pixels in the reprojected DEM. -32768 is the default.
#' @details The DEM file will be adjusted to match the projection and pixel resolution of the 'proRef' image.
#' @return A GeoTIFF raster file with '_reprojected.tif' replacing the last 4 characters of the input DEM filename.
#' @seealso \code{\link{mosaicDEMs}}
#' @examples \dontrun{
#' 
#' reprojectDEM(demFile = "C:/mss/dem/wrs1_p036r032_dem.tif",
#'              projRef = "C:/mss/LM10360321973191AAA04/LM10360321973191AAA04_dn.tif",
#'              srcNodata= -9999, dstNodata= -32768)
#' }
#' @export

reprojectDEM = function(demFile, projRef, srcNodata=NA, dstNodata=-32768){
  
  template = raster::raster(projRef) #read in the projection reference image
  reso = raster::xres(template) #get the pixel resolution
  proj = raster::projection(template) #get the projection
  
  print(paste("Reprojecting",demFile))
  bname = basename(demFile) #get the basename of the dem file
  extension = substr(bname,(nchar(bname)-3),nchar(bname)) #extract the extension of the dem file
  dstfile = sub(extension, "_reprojected.tif", demFile) #define the filename
  
  gdalUtils::gdalwarp(srcfile=demFile, dstfile=dstfile, 
           t_srs=proj, of="GTiff",
           r="near", multi=T, srcnodata=srcNodata, dstnodata=dstNodata, overwrite=TRUE,
           tr=c(reso,reso), co="INTERLEAVE=BAND") #reproject the image using gdalwarp through gdalUtils
  
}






