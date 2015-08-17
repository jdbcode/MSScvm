# MSScvm

An automated cloud and cloud shadow masking system for Landsat MSS imagery. It provides a means of more easily incorporating MSS imagery in large-area and time series analysis by providing an efficient way to prevent cloud and cloud shadow pixels from contaminating mosaics, composites, and time series analysis.

http://www.msscvm.jdbcode.com/

## Overview

MSScvm will take Landsat LPGS MSS images and preform the following processes:

*   Decompress
*   Stack individual image bands to a single 4-band file
*   Write image files for spectral units of DN, TOA radiance, and TOA reflectance
*   Help prepare a required DEM file by providing convenient functions to mosaic, reproject, and resample
*   Create cloud and cloud shadow masks

The program uses the R programming environment and GDAL to execute the work. Therefore you must install both R and GDAL, and we recommended that you use RStudio as the front-end to interact with the R environment. This guide will walk you through installing the required software and R packages, as well as demonstrate the use of MSScvm. Note that on the [Download](download.html) page the MSScvm R package manual can be downloaded. It contains standard R documentation for each function described below. In the R command prompt you can also type `?` followed by a function name to display the function's help page. As in: `?MSSunpack`.

The basic order of operations for running MSScvm is:

1.  Download MSS image
2.  Unpack the image using the `MSSunpack` function
3.  Identify and download image-corresponding DEM(s)
4.  Run the `mosaicDEMs` or `reprojectDEM` functions to prepare the DEM(s)
5.  Create cloud and shadow mask using the `MSScvm` function

If working with many images from the same Landsat footprint you will go through the above steps only once and then just the following for each successive image:

1.  Unpack the image using the `MSSunpack` function
2.  Create cloud and shadow mask using the `MSScvm` function

MSScvm will automatically write outputs to the same directory location as the input image, with intuitive file names that include the original image ID and descriptions for each type (DN, TOA radiance, TOA reflectance, and mask). The images are in the GeoTIFF format in the native resolution and projection of the input image file, with background values set to NoData.

## System requirements

### Computer

MSScvm was developed and tested on computers running Windows 7 64-bit OS with >= 8 GB of RAM.

### Software

*   R
*   RStudio
*   GDAL

## Install software

MSScvm requires R, RStudio, and GDAL programs be installed on your computer. R is a free computer programming language for statistical computing and graphics. RStudio provides a convenient front-end interface to the R environment. GDAL is a program for reading, writing, and manipulating geospatial data.

If you don't already have a current version of these programs you'll need to download and install them to your computer.

### R

Follow the install directions on the [R](http://www.r-project.org/) website

### RStudio

Follow the install directions on the [RStudio](http://www.rstudio.com/) website

### MSScvm

See the [Download](download.html) page for instructions and the most current version

### GDAL

There are numerous ways you can install GDAL, the following is one example.

1.  Go to [http://www.gisinternals.com/sdk/](http://www.gisinternals.com/sdk/)
2.  Click on the _Downloads_ link for the version that best matches your system (we use MSVC 2010 - x64)
3.  Download the _Generic installer for the GDAL core components_
4.  Run the installer
5.  Include GDAL in your system's environmental variable _PATH_

1.  Open Windows _Control Panel_ and select _System_
2.  Click on _Advanced system settings_
3.  Click the _Environmental Variables..._ button
4.  Under System variables, scroll down to the _Path_ variable and click on it to highlight it
5.  Click the _edit_ button
6.  Get your cursor to the end of the line, add a semi-colon (;) and add the path to the GDAL installation location. Example: C:\GDAL (this may not actually be the location on your system)

## Get MSS images

The MSS images processed by MSScvm should be compressed (.tar.gz) USGS LPGS images requested through [EarthExplorer](http://earthexplorer.usgs.gov/). This will ensure that the automated features of the program work correctly. They are contained in the _Landsat Archive_ directory under the _Data Sets_ tab on the EarthExplorer website.

Follow the instructions on the EarthExplorer site for selecting and downloading MSS images. When you have received your images, place the unaltered <samp>*.tar.gz</samp> files in a directory that you have write permission for, since MSScvm will write files to this location (some government and institutional systems restrict user writing capabilities).

## Prepare MSS images

Run the `MSSunpack` function to decompress, stack, and optionally output top-of-atmosphere (TOA) radiance and reflectance images. The <var>imgFile</var> input is the full path to a compressed LPGS MSS image from USGS EarthExplorer. The logical parameters <var>toaRad</var> and <var>toaRefl</var> determine whether TOA radiance and reflectance images are created along with the default DN image. The following examples demonstrate loading the MSScvm package and running the `MSSunpack` function with and without the <var>toaRad</var> and <var>toaRefl</var> parameters (each set to FALSE by default).

Load the MSScvm library (this only needs to be done once when a new R session is started):

<pre>library(MSScvm)</pre>

Run the `MSSunpack` function to create a 4-band DN image stack:

<pre>MSSunpack(imgFile = "C:/mss/LM10360321973191AAA04.tar.gz")</pre>

... or optionally run the `MSSunpack` function with the <var>toaRad</var> and <var>toaRefl</var> parameters set to TRUE to create 4-band DN, TOA radiance,and TOA reflectance image stacks:

<pre>MSSunpack(imgFile = "C:/mss/LM10360321973191AAA04.tar.gz", toaRad = TRUE, toaRefl = TRUE)</pre>

GeoTIFF raster image files will be written out. The files will be placed in a directory in the same location as the input <var>imgFile</var> with the name equal to the image ID. The files will contain the image ID followed by descriptors <samp>"dn.tif"</samp> (digital number), <samp>"toa_radiance.tif"</samp> (TOA radiance), and <samp>"toa_reflectance.tif"</samp> (TOA reflectance). Note that the values for TOA radiance are scaled by 100 and rounded to the nearest integer and TOA reflectance is scaled by 10,000 and rounded to the nearest integer. This is done to reduce image file size while retaining some decimal precision.

Input/output file path examples:

If <var>imgFile</var> input equals: <samp>"C:/mss/LM10360321973191AAA04.tar.gz"</samp>,  
 output DN file will be: <samp>"C:/mss/LM10360321973191AAA04/LM10360321973191AAA04_dn.tif"</samp>,  
 output TOA radiance file will be: <samp>"C:/mss/LM10360321973191AAA04/LM10360321973191AAA04_toa_radiance.tif"</samp>,  
 output TOA reflectance file will be: <samp>"C:/mss/LM10360321973191AAA04/LM10360321973191AAA04_toa_reflectance.tif"</samp>

## Prepare DEMs

MSScvm uses a digital elevation model (DEM) to aid in separating topographic shadows from cloud shadows and for identifying water. It is important that the DEM be greater or equal to the extent of the image it is being used for, and that it matches the pixel resolution and projection of the image.

Setting up the DEM can be a hassle, but MSScvm provides helper functions to make DEM preparation easy, but you first need to download them or check that the DEMs you have are large enough or can be mosaiced to cover the image extent. If you ensure that the DEM you use has a liberal buffer out from the WRS path/row you are working on, you will only need to prepare it once. After that it can be applied to any image for that WRS path/row. So take a little extra time up front to prepare the DEM for future use.

There are many sources of DEMs, and you can use what you like, but it's recommended that they be no more than 90 meters in pixel resolution. A good source for DEMs is the [Global Landcover Facility](http://glcf.umd.edu/data/srtm/), which distributes SRTM data as Landsat WRS-2 footprints. Use the _Filled Finished-B product at 1 arc second_ (30 meter) where possible and the _Filled Finished-B product at 3 arc seconds_ (90 meter) elsewhere. If using these data keep in mind that MSS images from sensors 1-3 use the WRS-1 footprint system so you will need to download several WRS-2 DEM footprints to fully intersect the MSS WRS-1 footprint. We've also found that the actual extent of a WRS-2 SRTM DEM will often not fully intersect the extent of a given image, even when the image is also WRS-2 (sensors 4-5). For this reason, we typically mosaic 9 DEMs for each WRS footprint to ensure full overlap with any image from the WRS path/row that we are working on (the `MSScvm` function will crop it on-the-fly in memory). In any case, check for full overlap between your DEM(s) and your MSS image in a GIS.

### Mosaicking several DEMs together

If you need to mosaic several DEMs together to ensure full overlap with your image, place all of the relevant DEM files into a single directory. There should be nothing else in the directory, and the files should all be decompressed GeoTIFF files. It is also important that the DEMs are from the same source so that their background value is the same. This value is specified in the call to the `mosaicDEMs` function and will be ignored during the mosaic procedure. If you need to convert to GeoTIFF files, you can use the `reprojectDEM` function to do so.

With the all of your relevant DEMs in a directory, run the `mosaicDEMs` function as follows, where <var>dir</var> is the full path to the DEM directory, <var>projRef</var> is a <samp>*dn.tif</samp> file produced by the `MSSunpack` function that corresponds to the DEMs, <var>srcNodata</var> is the background value of the DEMs in the DEM directory, and <var>dstNoData</var> sets the desired background value for the output DEM mosaic.

Example:

<pre>mosaicDEMs(dir = "C:/mss/dems", projRef = "C:/mss/LM10360321973191AAA04/LM10360321973191AAA04_dn.tif", srcNodata = -9999, dstNodata= -32768)</pre>

The function will produce a mosaic from all the files found in the directory specified by the <var>dir</var> parameter. It will be GeoTIFF format, with the background value set to the value specified by the <var>dstNodata</var> parameter and will be placed in the same directory as <var>dir</var> with the name <samp>dem_mosaic.tif</samp>.

### Reprojecting and resampling an existing DEM

If you have an existing DEM that is >= to the extend of the MSS image you want to create a cloud and shadow mask for or you need to convert DEM files to GeoTIFF format for use in the `mosaicDEMs` function, use the `reprojectDEM` function. It will take an input DEM file specified by the <var>demFile</var> parameter and make it match the projection and resolution of the relevant MSS image specified by the <var>projRef</var> parameter. The <var>srcNodata</var> and <var>dstNodata</var> parameters are used to set the output's background value. <var>srcNodata</var> is the background value of the input DEM and <var>dstNoData</var> sets the desired background value for the output DEM.

Example:

<pre>reprojectDEM(demFile = "C:/mss/dem/wrs1_p036r032_dem.tif", projRef = "C:/mss/LM10360321973191AAA04/LM10360321973191AAA04_dn.tif", srcNodata = -9999, dstNodata = -32768)</pre>

The function will produce a new DEM file in the GeoTIFF format, with the projection and pixel resolution matching that of the <var>projRef</var> image. The the <var>srcNodata</var> value will be set to the value specified by the <var>dstNodata</var> parameter and the file will placed in the same directory as the <var>demFile</var> with <samp>_reprojected.tif</samp> replacing the input file's extension.

</div>

<div><a class="guide_anchor" id="create_cloud_mask"></a>

## Create cloud mask

Run the `MSScvm` function to create cloud and cloud shadow masks for MSS images. The inputs are the full path to a directory containing an unpacked MSS image as the result of running the `MSSunpack` function (<var>imgDir</var>) and the prepared image-corresponding DEM (<var>demFile</var>). An optional logical parameter <var>classify</var> specifies how to label the mask pixels. The default is <var>classify</var> = FALSE, which returns a binary mask where pixels are either obscured (cloud and cloud shadow aggregated) or clear-view, alternatively, TRUE will classify the pixels by clear-view, cloud shadow, and cloud.

Example of running the `MSScvm` function:

<pre>MSScvm(imgDir = "C:/mss/LM10360321973191AAA04", demFile = "C:/mss/dem/wrs1_p036r032_dem.tif", classify = FALSE)</pre>

A GeoTIFF raster image file will be placed in the <var>imgDir</var> directory with the name equal to the image ID followed by <samp>_msscvm.tif</samp>. If the <var>classify</var> parameter was set to <var>FALSE</var> then obscured pixels (cloud and cloud shadow) will be set to value 0 and clear-view pixel set to 1. If the <var>classify</var> parameter was set to <var>TRUE</var> then clear-view = 0, cloud shadow = 1, cloud = 2\.

## Auxiliary functions

MSScvm has functions to convert DN images to TOA radiance and reflectance images. These functions can optionally be called when running the `MSSunpack` function. If they were not run during unpacking, they can be run independently by running the `MSSdn2rad` and `MSSdn2refl` functions. The input (<var>imgFile</var>) for both functions is the full path to a <samp>*dn.tif</samp> file produced by running the `MSSunpack` function.

Create a TOA radiance file from a <samp>*dn.tif</samp> file:

<pre>MSSdn2rad(imgFile = "C:/mss/LM10360321973191AAA04/LM10360321973191AAA04_dn.tif")</pre>

Create a TOA reflectance file from a <samp>*dn.tif</samp> file:

<pre>MSSdn2refl(imgFile = "C:/mss/LM10360321973191AAA04/LM10360321973191AAA04_dn.tif")</pre>

Both functions will output a 4-band GeoTIFF raster image. The file will be placed in the same directory as the input <var>imgFile</var> with the name equal to the image ID followed by <samp>"_toa_radiance.tif"</samp> or <samp>"_toa_reflectance.tif"</samp>. Note that the values for TOA radiance are scaled by 100 and rounded to the nearest integer and TOA reflectance is scaled by 10,000 and rounded to the nearest integer. This is done to reduce image file size while retaining some decimal precision.
