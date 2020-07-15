# ----------------------------
# Process the CR2 temperature product to obtain the mean temperature layer (1997-2016)
# ----------------------------

#------------------------------------------------------
# Library management

# we use the checkpoint package to secure reproducibility, \
#it will download the package version of that specific dat
if (!require(chackpoint)) install.packages("checkpoint")
library("checkpoint")
checkpoint("2020-07-08") # Date in which this package was run for the last time

# Install necessary packages (if not already installed)
if (!require(raster)) install.packages("raster")
if (!require(ncdf4)) install.packages("ncdf4")

# Load the necessary packages
library(raster) # Handle raster files
library(ncdf4) # Handle netCDF files

#----------------------------------------------------
# Parameters

# Initial year of execution of the model
initial_year <- 1997

# Last year of execution of the model
final_year <- 2016

# Initial year of the CR2 product
initial_year_temp <- 1979

# Final year of the CR2 product
final_year_temp <- 2016

# ----------------------------------------------------
# Folders paths

# Temperature raster folder
input_temp <- "./Input_Files/Temperature"

# Output folder
output_gcbm <- "./Output_Files/layers/raw/environment"

# ---------------------------
# File names

# Product of average mean temperature (res: 0.005 degress), elaborated bu the CR2 climate research center
layer_temp <- "CR2MET_v1.3_tmonth_1979_2016_005deg.nc"


#----------------------------

# Read the first layer of the netCDF file
temp <- raster(paste0(input_temp, "/", layer_temp), band = 1)

# Each netCDF band is a month, we need to knlw which band correspong to january of the first year of the simulation
# Difference between the first year of the simulation and the first year of the raster product
dif_year <- initial_year - initial_year_temp

# I calculated the initial band using the year difference (+1 to get the january layer)
initial_band <- (dif_year * 12) + 1

# I calculate the total number bands in the CDF (I can also see this in the metadata)
final_band <- ((final_year_temp - initial_year_temp) * 12) + 12


# Calculate the mean temperature by adding all the bands and dividing them by the number of bands

# Progress bar
pb <- txtProgressBar(min = initial_band, max = final_band, initial = 1, style = 3)

for (i in initial_band:final_band) {

  # Read band
  temp <- raster(paste0(input_temp, "/", layer_temp), band = i)

  # If it is the first iteration create new object
  if (i == initial_band) {

    sum_temp <- temp
    count <- 0
    
  } else {
    
    sum_temp <- sum_temp + temp
    count <- count + 1
  }

  setTxtProgressBar(pb, i)
}


# Get the mean
mean_temp <- sum_temp / count

# Plot result
plot(mean_temp)

# Check the maximum and minimum temprature to see if everything is OK
cellStats(mean_temp, stat = "max")
cellStats(mean_temp, stat = "min")

# Escribir el raster
writeRaster(mean_temp, paste0(output_gcbm, "/Temp_average_CR2_1997_2016.tif"))
