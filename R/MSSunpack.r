#' Decompress and stack Landsat LPGS MSS images
#'
#' Decompresses and stacks Landsat LPGS MSS images provided by USGS as *.tar.gz files. Optionally 
#' outputs top-of-atmosphere (TOA) radiance and reflectance files.
#' @param imgFile filename (character). Full path to compressed LPGS Landsat MSS image file provided by USGS.  
#' @param toaRad logical. If TRUE, a TOA radiance image will be created.
#' @param toaRefl logical. If TRUE, a TOA reflectance image will be created. 
#' @param useL1G logical. If TRUE, L1G images will be processed.
#' @details It is important that the 'imgFile' be an unaltered tar.gz-compressed LPGS image file that you receive 
#' from USGS through \href{http://rstudio.com}{EarthExplorer}. Note that DN values <= 1 are set to NA across all bands. 
#' This mitigates a problem caused by bad columns on the east and west edge of images when mosaicing adjacent images together.  
#' @return A 4-band Landsat MSS GeoTIFF raster image file in DN units. If optional 'toaRad' and/or 'toaRefl' 
#' parameters are set to TRUE, then similar TOA radiance and reflectance image files will created. The files will be placed in
#' the same location as the 'imgFile' with the name equal to the image ID plus an appended descriptor. Descriptors
#' include 'dn' (digital number), 'toa_radiance' (TOA radiance), and 'toa_reflectance' (TOA reflectance).
#' @seealso \code{\link{MSSdn2rad}}, \code{\link{MSSdn2refl}}
#' @examples 
#' \dontrun{
#' 
#' MSSunpack(imgFile = "C:/mss/LM10360321973191AAA04.tar.gz")
#' MSSunpack(imgFile = "C:/mss/LM10360321973191AAA04.tar.gz", 
#'           toaRad = FALSE, toaRefl = TRUE, useL1G = TRUE)
#' }
#' @export


MSSunpack = function(imgFile, toaRad=FALSE, toaRefl=FALSE, useL1G=FALSE){
  
  #figure out if this is an L1G image and stop the function according to the 'useL1G' parameter
  print(paste("Unpacking and preparing",basename(imgFile)))
  tempdir = file.path(dirname(imgFile),"temp")
  untar(imgFile, exdir=tempdir)
  mtlfile = list.files(tempdir, pattern = "MTL.txt", full.names = T, recursive = T) #find the mtl metadata file
  info = getMetadata(mtlfile)
  if(useL1G == F & info$datatype == "L1G"){
      unlink(tempdir, recursive=T, force=T) #delete the temp folder and its contents
      print(paste("MSS file:",imgFile,"is L1G, if you want to use it, set the 'useL1G' parameter to TRUE"))
      stop("Stopping MSSunpack")
  }
  
  #get file and directory info
  allfiles = list.files(tempdir, full.names=T) #find all the decompressed files 
  tiffiles = allfiles[grep("TIF",allfiles)] #subset the tif image files
  ancfiles = allfiles[grep("TIF",allfiles, invert=T)] #subset the other files
  filebase = basename(tiffiles[1]) #get the basename
  filedir = dirname(imgFile) #get the directory
  
  #create stack output name
  name = paste(info$imgid, "_dn.tif", sep = "") #define the new file basename 
  outdir = file.path(filedir, info$imgid) #define the output directory
  finalstack = file.path(outdir, name) #define the new full filename of the output image 
  
  #deal with the ancillary file names
  baseancfiles = basename(ancfiles) #get the basenames of the ancillary files
  newancfiles =  file.path(outdir, baseancfiles) #define the new filenames for ancillary files
  
  #start working with the image files - stack and set bad pixels to 0
  s = raster::stack(tiffiles[1],tiffiles[2],tiffiles[3],tiffiles[4]) #stack the band files
  img = raster::as.array(s) #convert to array for fastering processing
  b1bads = img[,,1]>1 #finds bad image edge pixels that cause problems when mosaicing 
  b2bads = img[,,2]>1 #finds bad image edge pixels that cause problems when mosaicing
  b3bads = img[,,3]>1 #finds bad image edge pixels that cause problems when mosaicing
  b4bads = img[,,4]>1 #finds bad image edge pixels that cause problems when mosaicing
  bads = b1bads*b2bads*b3bads*b4bads #combines all of the bad pixels
  
  img[,,1] = img[,,1]*bads #sets all the bad pixels to value 0
  img[,,2] = img[,,2]*bads #sets all the bad pixels to value 0
  img[,,3] = img[,,3]*bads #sets all the bad pixels to value 0
  img[,,4] = img[,,4]*bads #sets all the bad pixels to value 0
  
  dir.create(outdir, recursive=T, showWarnings=F) #make a new output directory
  
  file.rename(ancfiles,newancfiles) #move the associated files
  
  #write out the dn file
  outimg = raster::setValues(s,img) #convert from matrix to raster   
  outimg = as(outimg, "SpatialGridDataFrame") #convert from rater to SGDF for faster writing
  rgdal::writeGDAL(outimg, finalstack, drivername = "GTiff", options="INTERLEAVE=BAND", type = "Byte", mvFlag = 0) #write out the image.
  
  if(toaRad == T){MSSdn2rad(finalstack)} #calculate and write the toa radiance file if flagged
  
  if(toaRefl == T){MSSdn2refl(finalstack)} #calculate and write the toa reflectance file if flagged
  
  unlink(tempdir, recursive=T, force=T) #delete the temp folder and its contents
}