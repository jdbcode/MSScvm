# MSScvm

An automated cloud and cloud shadow masking system for Landsat MSS imagery. It provides a means of more easily incorporating MSS imagery in large-area and time series analysis by providing an efficient way to prevent cloud and cloud shadow pixels from contaminating mosaics, composites, and time series analysis.

http://www.msscvm.jdbcode.com/

<h2 class="page-header no_top_margin">Overview</h2>
<p>MSScvm will take Landsat LPGS MSS images and preform the following processes:</p>
	<ul>
		<li>Decompress</li>
		<li>Stack individual image bands to a single 4-band file</li>
		<li>Write image files for spectral units of DN, TOA radiance, and TOA reflectance</li>
		<li>Help prepare a required DEM file by providing convenient functions to mosaic, reproject, and resample</li>
		<li>Create cloud and cloud shadow masks</li>
	</ul>
	<p>The program uses the R programming environment and GDAL to execute the work. Therefore you must 
		install both R and GDAL, and we recommended that you use RStudio as the front-end to interact with 
		the R environment. This guide will walk you through installing the required software and R packages,
		as well as demonstrate the use of MSScvm. Note that on the <a href="download.html">Download</a> page
		the MSScvm R package manual can be downloaded. It contains standard R documentation for each function
		described below. In the R command prompt you can also type <code>?</code> followed by a function name to display the 
		function's help page. As in: <code>?MSSunpack</code>.</p>
