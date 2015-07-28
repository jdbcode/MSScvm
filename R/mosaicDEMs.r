#' Create a DEM mosaic from a direcory of DEM's
#'
#' A helper function to create the large-extent DEM file required by the 'MSScvm' function.
#' @param dir directory name (character). Full path to a directory containing digital elevation model (DEM) files to be mosaiced.
#' @param projRef filename (character). Full path to an image file produced by the \code{\link{MSSunpack}} function.
#' @param srcNodata numeric. What is the background value of the DEM files in the directory. If there is no background value, use NA (default) 
#' @param dstNodata numeric. Specify the value to represent background pixels in the mosaic DEM. -32768 is the default
#' @details The provided directory path should only contain decompressed digital elevation files from the same source (SRTM, NED, GTOPO, etc).
#' The function will search the directory and include all files found in the mosaic. It is important that each file have the same background value
#' and that it is correctly assigned to the 'srcNodata' parameter, if not, intersection between DEMs could have unexpected results. 
#' Each individual DEM file will be adjusted to match the projection and pixel resolution of the 'proRef' image. 
#' Then they will be merged using the mean value of intersecting pixels.  
#' @return A GeoTIFF raster file representing the union of all individual DEM files found in the provided directory path. The mosaic file will be written to the 
#' provided directory as "dem_mosaic.tif". 
#' @seealso \code{\link{reprojectDEM}}
#' @examples \dontrun{
#' 
#' mosaicDEMs(dir = "C:/mss/dems", 
#'            projRef = "C:/mss/LM10360321973191AAA04/LM10360321973191AAA04_dn.tif",
#'            srcNodata = -9999, dstNodata= -32768)
#' }
#' @export


mosaicDEMs = function(dir, projRef, srcNodata=NA, dstNodata=-32768){
  
  align = function(img, refimg){
    img = raster::raster(img)
    imgex = raster::alignExtent(img, refimg, snap="near")
    raster::extent(img) = imgex
    return(img)
  }
  
  template = raster::raster(projRef)
  reso = raster::xres(template)
  proj = raster::projection(template)
  demfiles = normalizePath(list.files(dir, full.names=T))
  
  #check files to see if they are compressed
  zip = grep("zip", demfiles)
  tar = grep("tar", demfiles)
  gz =  grep("gz", demfiles)
  if(sum(length(zip),length(tar),length(gz)) != 0){
    print(paste("There are compressed files in this directory:",dir))
    print("make sure the directory only contains decompressed files")
    stop("Stopping mosaicDEMs")
  }
  
  for(i in 1:length(demfiles)){
    demfile = demfiles[i]
    print(paste("Reprojecting",basename(demfile)))
    bname = basename(demfile)
    extension = substr(bname,(nchar(bname)-3),nchar(bname))
    dstfile = sub(extension, "_reprojected.tif", demfile) 
  
    gdalUtils::gdalwarp(srcfile=demfile, dstfile=dstfile, 
      t_srs=proj, of="GTiff", overwrite=TRUE,
      r="near", srcnodata=srcNodata, dstnodata=dstNodata, multi=T,
      tr=c(reso,reso), co="INTERLEAVE=BAND")
  }
  
  demfiles = list.files(dir, pattern="reprojected.tif$", full.names=T)
  len = length(demfiles)
  if(len <= 1){
    print(paste("There are less than 2 DEM files in this directory:",dir))
    print("Not enough to mosaic")
    stop("Stopping mosaicDEMs")
  }
  
  refimg = raster::raster(demfiles[1])
  
  outfile = file.path(dir,"dem_mosaic.tif")
  big = NA #create a dummy variable to be overwritten on-the-fly with eval
  for(i in 1:len){
    if(i == 1){mergeit = "r1"} else {mergeit = paste(mergeit,",r",i, sep="")}
    dothis = paste("r",i,"=align(demfiles[",i,"], refimg)", sep="")
    eval(parse(text=dothis))
    if(i == len){mergeit = paste("big = raster::mosaic(",mergeit,",fun=mean,na.rm=T,tolerance=0.5, filename=outfile, format='GTiff', datatype = 'INT2S',overwrite=T,options=c('COMPRESS=NONE'))", sep="")}
  }
  
  print("Creating DEM mosaic")
  eval(parse(text=mergeit))
  unlink(demfiles)
  
}

