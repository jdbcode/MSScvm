# MSScvm

An automated cloud and cloud shadow masking system for Landsat MSS imagery. It provides a means of more easily incorporating MSS imagery in large-area and time series analysis by providing an efficient way to prevent cloud and cloud shadow pixels from contaminating mosaics, composites, and time series analysis.

http://www.msscvm.jdbcode.com/

Overview
--------

MSScvm will take Landsat LPGS MSS images and preform the following processes:

-   Decompress
-   Stack individual image bands to a single 4-band file
-   Write image files for spectral units of DN, TOA radiance, and TOA reflectance
-   Help prepare a required DEM file by providing convenient functions to mosaic, reproject, and resample
-   Create cloud and cloud shadow masks

The program uses the R programming environment and GDAL to execute the work. Therefore you must install both R and GDAL, and we recommended that you use RStudio as the front-end to interact with the R environment. This guide will walk you through installing the required software and R packages, as well as demonstrate the use of MSScvm. Note that on the [Download] page the MSScvm R package manual can be downloaded. It contains standard R documentation for each function described below. In the R command prompt you can also type `?` followed by a function name to display the function’s help page. As in: `?MSSunpack`.

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

System requirements
-------------------

### Computer

MSScvm was developed and tested on computers running Windows 7 64-bit OS with &gt;= 8 GB of RAM.

### Software

-   R
-   RStudio
-   GDAL

<span id="install_software"></span></a>
Install software
----------------

MSScvm requires R, RStudio, and GDAL programs be installed on your computer. R is a free computer programming language for statistical computing and graphics. RStudio provides a convenient front-end interface to the R environment. GDAL is a program for reading, writing, and manipulating geospatial data.

If you don’t already have a current version of these programs you’ll need to download and install them to your computer.

### R

Follow the install directions on the [R] website

### RStudio

Follow the install directions on the [RStudio] website

### MSScvm

See the [Download] page for instructions and the most current version

### GDAL

There are numerous ways you can install GDAL, the following is one example.

<ol>
<li>
Go to <http://www.gisinternals.com/sdk/>
</li>
<li>
Click on the *Downloads* link for the version that best matches your system (we use MSVC 2010 - x64)
</li>
<li>
Download the *Generic installer for the GDAL core components*
</li>
<li>
Run the installer
</li>
<li>
Include GDAL in your system’s environmental variable *PATH*
</li>
1.  Open Windows *Control Panel* and select *System*
2.  Click on *Advanced system settings*
3.  Click the *Environmental Variables…* button
4.  Under System variables, scroll down to the *Path* variable and click on it to highlight it
5.  Click the *edit* button
6.  Get your cursor to the end of the line, add a semi-colon (;) and add the path to the GDAL installation location. Example: C:\\GDAL (this may not actually be the location on your system)
</ol>
