Temperature Layer
=================

The Temperature Layer code processes the CR2 temperature product to
obtain the mean temperature layer between 1997 to 2016. The
``initial_year`` and ``final_year`` defines the initial and last year of
execution respectively. The ``initial_year_temp`` and the
``final_year_temp`` as the initial and last year of execution of the CR2
product respectively.

The ``layer_temp`` is defined as the product of the average mean
temperature defined by the CR2 climate research centre. After the
definition of the Temperature raster folder for the ``input_temp``, we
read the first layer of the netCDF file. Each netCDF band is a month and
the band corresponding to January of the first year of the simulation is
calculated.

.. code:: R

   temp <- raster(paste0(input_temp, "/", layer_temp), band = 1)
   dif_year <- initial_year - initial_year_temp
   initial_band <- (dif_year * 12) + 1
   final_band <- ((final_year_temp - initial_year_temp) * 12) + 12

Later we calculate the mean temperature by adding all the bands and
dividing them by the number of bands.

.. code:: R

   for (i in initial_band:final_band) {
     temp <- raster(paste0(input_temp, "/", layer_temp), band = i)
     if (i == initial_band) {

       sum_temp <- temp
       count <- 0
     } else {
       sum_temp <- sum_temp + temp
       count <- count + 1
     }
     setTxtProgressBar(pb, i)
   }

   mean_temp <- sum_temp / count

The maximum and minimum temperature is calculated and the output is
written to a raster file.
