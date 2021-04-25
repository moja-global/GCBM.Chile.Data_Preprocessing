# ----------------------------
# Create the deforestation and substitution layers
# ----------------------------
print("Creating the forest loss (deforestation and substitution) layer")


#------------------------------------------------------
# Library management

# we use the checkpoint package to secure reproducibility, 
# it will download the package version of that specific date
library("checkpoint")
checkpoint("2019-10-01", scanForPackages = FALSE) # Date of compatibility packages

# Load the necessary packages
library(sf) # simple feature package for shape processing
library(dplyr) # database handling
library(raster) # raster file processing
library(rgdal) # gdal library
library(exactextractr) # extract raster values to polygons

# ----------------------------------------------------
# Folder Paths

# Folder where the Land use change data is (Trazabilidad file)
input_traza <- "./Input_Files/LUC"

# Folder of the output data
output_gcbm <- "./Output_Files/layers/raw/disturbances"

# ---------------------------
# Layer names

# Trazabilidad (land use data)
layer_traza <- "Trazabilidad_R_LosRios_2016_V4"

# Parameters

# The Trazabilidad layer has four fields (T1, T2, T3, T4) with land use data for 4 distict years
# We need to specify those years
year_t1 <-1997
year_t2 <-2006
year_t3 <-2013
year_t4 <-2017

# Random seed to ensure reproducibility
set.seed(31102019)


#-----------------------------------------------------------------
# Generate the deforestation shapefile


# Read the LUC shapefile
traza <- st_read(dsn = input_traza, layer = layer_traza)

# Filter to identify poligons that went from forest to nonforest between T1 and T2
defor_t2<- dplyr::filter(
  traza,
  T1 %in% c("0403", "040203", "040202", "040204", "040201", "0402","0304"),
  !(T2 %in% c("0403", "040203", "040202", "040204", "040201", "0402","0401","0304")))

# Assing year and name of the disturbance
defor_t2$year<-year_t2
defor_t2$Perturb<-"Deforestacion"

# We are going to assing a random year between T1 and T2 for the disturbance
# from 1997 to 2006 (included), according to the excel files
defor_t2$year<-sample(year_t1:year_t2,nrow(defor_t2),replace=TRUE)
defor_t2$year

# Leave the important columns
defor_t2<-defor_t2[,c("year","Perturb")]

# The same with disturbances from T2 to T3

defor_t3<-dplyr::filter(
  traza,
  T2 %in% c("0403", "040203", "040202", "040204", "040201", "0402","0304"),
  !(T3 %in% c("0403", "040203", "040202", "040204", "040201", "0402","0401","0304")))

defor_t3$year<-year_t3
defor_t3$Perturb<-"Deforestacion"

#In this case 2013 was included, but not the 2006
defor_t3$year<-sample((year_t2+1):year_t3,nrow(defor_t3),replace=TRUE)
defor_t3$year

defor_t3<-defor_t3[,c("year","Perturb")]

# Same with deforestation from T3 to T4

defor_t4<-dplyr::filter(
  traza,
  T3 %in% c("0403", "040203", "040202", "040204", "040201", "0402"),
  !(T4 %in% c("0403", "040203", "040202", "040204", "040201", "0402","0401")))

defor_t4$year<-year_t4
defor_t4$Perturb<-"Deforestacion"

# Here only the 2014, 2015 and 2016 years are included
defor_t4$year<-sample((year_t3+1):(year_t4-1),nrow(defor_t4),replace=TRUE)
defor_t2$year

defor_t4<-defor_t4[,c("year","Perturb")]

# Get the partial layers togather
defor_total<-rbind(defor_t2,defor_t3,defor_t4)

defor_total


#--------------------------------------------------------------
# Substitution layer: From forest to exotic plantations

# Filter poligons that went from forest to plantations between T1 and T2
sust_t2<- dplyr::filter(
  traza,
  T1 %in% c("0403", "040203", "040202", "040204", "040201", "0402","0304"),
  T2 %in% c("0401"))

# Assing year and type of substitution
sust_t2$year<-year_t2
sust_t2$Perturb<-"Sustitucion"

# Randomize year (same as in deforestation)
sust_t2$year<-sample(year_t1:(year_t2),nrow(sust_t2),replace=TRUE)

sust_t2<-sust_t2[,c("year","Perturb")]

# Same with disturbances from T2 to t3

sust_t3<-dplyr::filter(
  traza,
  T2 %in% c("0403", "040203", "040202", "040204", "040201", "0402","0304"),
  T3 %in% c("0401")
)

sust_t3$year<-year_t3
sust_t3$Perturb<-"Sustitucion"

# randomize disturbance year
sust_t3$year<-sample((year_t2+1):year_t3,nrow(sust_t3),replace=TRUE)
sust_t3$year

sust_t3<-sust_t3[,c("year","Perturb")]

# Same with disturbances from T3 to T4
sust_t4<-dplyr::filter(
  traza,
  T3 %in% c("0403", "040203", "040202", "040204", "040201", "0402"),
  T4 %in% c("0401")
)

sust_t4$year<-year_t4
sust_t4$Perturb<-"Sustitucion"

# Randomize year of disturbance
sust_t4$year<-sample((year_t3+1):(year_t4-1),nrow(sust_t4),replace=TRUE)

sust_t4<-sust_t4[,c("year","Perturb")]

# Get the partial layers together
sust_total<-rbind(sust_t2,sust_t3,sust_t4)

#------------

# Build the forest loss disturbances layer 
dist_total<-rbind(defor_total,sust_total)

# Project to WGS84 latlong
dist_total<-st_transform(dist_total, "+proj=longlat +datum=WGS84 +ellps=WGS84 +towgs84=0,0,0")

# Year column as integer
dist_total$year<-as.integer(dist_total$year)


# Write shapefile
write_sf(dist_total, paste0(output_gcbm, "/forest_loss_LosRios.shp"))

print(paste("Forest loss layer written in",paste0(output_gcbm, "/forest_loss_LosRios.shp")))



