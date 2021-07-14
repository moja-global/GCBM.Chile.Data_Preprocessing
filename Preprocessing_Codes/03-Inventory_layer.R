# ----------------------------
# Create the inventory layer (initial layer)
# ----------------------------
print("Creating the inventory layer (initial year)")

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
library(exactextractr) # extract raster values to a shape




# ----------------------------------------------------
# Folders paths

# Folder where the Land use change data is (Trazabilidad file)
input_traza <- "./Input_Files/LUC"

# Folder where the soil organic carbon data is
input_SOC <- "./Input_Files/SOC"

# Folder of the output data
output_gcbm <- "./Output_Files/layers/raw/inventory"

#----------------------------------------------------
# Parameters

# inital year of model execution
inventory_year <- 1997

# ---------------------------
# Layer names

# Trazabilidad (land use data)
layer_traza <- "Trazabilidad_R_LosRios_2016_V4"

# Soil organic carbon data from FAO (GSOC map version 1.5.0)
layer_SOC<-"SOC_South_Chile_GSOCmap_v1_5_0.tiff"

#-----------------------------------------------------------------
# generate the inventory layer from the trazabilidad file

# Read the Trazabilidad file
traza <- st_read(dsn = input_traza, layer = layer_traza)

# Filter the database (Optional)
# Include the polygons that were forest ar some point of the time series of data (T1, T2, T3, T4)
# traza<- dplyr::filter(
#   traza,
#   T1 %in% c("0403", "040203", "040202", "040204", "040201", "0402","0304")|
#     T2 %in% c("0403", "040203", "040202", "040204", "040201", "0402","0304")|
#     T3 %in% c("0403", "040203", "040202", "040204", "040201", "0402","0304")|
#     T4 %in% c("0403", "040203", "040202", "040204", "040201", "0402","0304")
# )

#---------------------------------------------------------
# Assign classifiers

# Tipofor classifier, it refers to the local classification of Forest types (Donoso, 1981)

# Get the forest types from the 1997 map
traza$Tipofor <- as.character(traza$T_F_97)

# Assign the "Bosque Mixto" forest type from the T1 column
traza$Tipofor <- ifelse(traza$T1 == "0403", "Bosque Mixto", as.character(traza$Tipofor))

# Assign the "Matorral Arborescente" forest type from the T1 column
traza$Tipofor <- ifelse(traza$T1 == "0304", "Matorral Arborescente", as.character(traza$Tipofor))

# All polygons without a forest types will be leaved as "No Forestal" (nonforest)
traza$Tipofor <- ifelse(is.na(traza$Tipofor), "No forestal", as.character(traza$Tipofor))

# Forest structure classifier

traza$Estruc <- as.character(recode(traza$ID_EST_97,
  "01" = "Adulto",
  "02" = "Renoval",
  "03" = "Adulto Renoval",
  "04" = "Achaparrado"
))

# Same as before, I have to assing the bosque mixto and matorral arborescente from the T1 column
traza$Estruc <- ifelse(traza$T1 == "0403", "Bosque Mixto", as.character(traza$Estruc))
traza$Estruc <- ifelse(traza$T1 == "0304", "Matorral Arborescente", as.character(traza$Estruc))

# All polygons without a forest types will be leaved as "No Forestal" (nonforest)
traza$Estruc <- ifelse(is.na(traza$Estruc), "No forestal", as.character(traza$Estruc))

# Filter to leave only 4 columns
traza <- traza[, c("IDtra", "Tipofor", "Estruc", "SUP_HA")]

# Origin classifier, to distinguish between forest that come from the initial inventory (bosque inicial), for accounting purposes

traza$Origen<-ifelse(traza$Tipofor %in% c("No forestal", "Plantaciones"), "No forestal", "Bosque Inicial")

#--------------------------------------------------------------------
# Determine age and SOC

# I will leave all ages as 100 for the initial forest
traza$Edad <- ifelse(!(traza$Tipofor %in% c("No forestal", "Plantacion")), 100, 0)

# Reproject shapefile to lat long
traza<-st_transform(traza, "+proj=longlat +datum=WGS84 +ellps=WGS84 +towgs84=0,0,0")

# Extract SOC data
# Load SOC data
SOC <- raster(paste0(input_SOC, "/", layer_SOC))

# Extract the soc data by calculating the mean in each polygon
traza$CdelSuelo <- exact_extract(SOC, traza, "mean")

# Assign 100 if I have an NA (Optional)
traza$CdelSuelo <- ifelse(is.na(traza$CdelSuelo), 100, traza$CdelSuelo)

# If the GCBM detects a SOC greater than 0 in a forest pixel it will not work (bug), most recent versions have fixed this bug
traza$CdelSuelo <- ifelse(!(traza$Tipofor %in% c("No forestal", "Plantacion")), 0, traza$CdelSuelo)

# Historic and current land use assumptions

# Historic land use assumptions, FL if it is a native forest, CL if not
traza$LC_Hist<-ifelse(traza$Tipofor %in% c("No forestal", "Plantacion"),"CL","FL")

# Current land use assumptions, FL if it is a native forest, CL if not
traza$LC_Curr<-ifelse(traza$Tipofor %in% c("No forestal", "Plantacion"),"CL","FL")

# Leave only important fields
traza<-traza[,c("IDtra","Tipofor","Estruc","Origen","Edad","CdelSuelo","LC_Hist","LC_Curr")]

# Write shapefile
write_sf(traza, paste0(output_gcbm, "/inventory_LosRios.shp"))

print(paste("Inventory layer written in",paste0(output_gcbm, "/inventory_LosRios.shp")))


