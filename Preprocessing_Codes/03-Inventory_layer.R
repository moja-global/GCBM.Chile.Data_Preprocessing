# ----------------------------
# Export the Excel spreadsheet with growth curves to accepted csv format
# ----------------------------

#------------------------------------------------------
# Library management

# we use the checkpoint package to secure reproducibility, 
# it will download the package version of that specific date
if (!require(checkpoint)) install.packages("checkpoint")
library("checkpoint")
checkpoint("2019-10-01", scanForPackages = FALSE) # Date of compatibility packages

# Install necessary packages (if not already installed)
if (!require(sf)) install.packages("sf")
if (!require(dplyr)) install.packages("dplyr")
if (!require(raster)) install.packages("raster")
if (!require(rgdal)) install.packages("rgdal")
if (!require(exactextractr)) install.packages("exactextractr")

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
anio_inventario <- 1997

# ---------------------------
# Layer names

# Trazabilidad (land use data)
capa_traza <- "Trazabilidad_R_LosRios_2016_V4"

# Soil organic carbon data from FAO (GSOC map version 1.5.0)
capa_SOC<-"SOC_South_Chile_GSOCmap_v1_5_0.tiff"

#-----------------------------------------------------------------
# generate the inventory layer from the trazabilidad file

# Read the Trazabilidad file
traza <- st_read(dsn = input_traza, layer = capa_traza)

# Filter the database (Optional)
# Include the polygons that were forest ar some point of the time series of data (T1, T2, T3, T4)
traza<- dplyr::filter(
  traza,
  T1 %in% c("0403", "040203", "040202", "040204", "040201", "0402","0304")|
    T2 %in% c("0403", "040203", "040202", "040204", "040201", "0402","0304")|
    T3 %in% c("0403", "040203", "040202", "040204", "040201", "0402","0304")|
    T4 %in% c("0403", "040203", "040202", "040204", "040201", "0402","0304")
)

#---------------------------------------------------------
# Assing classfiers

# Tipofor clasiffier, it refers to the local classification of Forest types (Donoso, 1981)

# Get the forest types from the 1997 map
traza$Tipofor <- as.character(traza$T_F_97)

# Assing the "Bosque Mixto" forest type from the T1 column
traza$Tipofor <- ifelse(traza$T1 == "0403", "Bosque Mixto", as.character(traza$Tipofor))

# Assing the "Matorral Arborescente" forest type from the T1 column
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

# ReProject shapefile to lat long
traza<-st_transform(traza, "+proj=longlat +datum=WGS84 +ellps=WGS84 +towgs84=0,0,0")

# Extract SOC data
# Load SOC data
SOC <- raster(paste0(input_SOC, "/", capa_SOC))

# Extract the soc data by calculating the mean in each polygon
traza$CdelSuelo <- exact_extract(SOC, traza, "mean")

# Asignn 100 if I have an NA
traza$CdelSuelo <- ifelse(is.na(traza$CdelSuelo), 100, traza$CdelSuelo)

# If the GCBM detects a SOC greater than 0 in a forest pixel it will not work (bug), most reacent versions have fixed this bug
traza$CdelSuelo <- ifelse(!(traza$Tipofor %in% c("No forestal", "Plantacion")), 0, traza$CdelSuelo)

# Historic and current land use assumptions

# Historic land use assumptions, FL if it is a native forest, CL if not
traza$LC_Hist<-ifelse(traza$Tipofor %in% c("No forestal", "Plantacion"),"CL","FL")

# Current land use assumptions, FL if it is a native forest, CL if not
traza$LC_Curr<-ifelse(traza$Tipofor %in% c("No forestal", "Plantacion"),"CL","FL")

# Leave only important fields
traza<-traza[,c("IDtra","Tipofor","Estruc","Origen","Edad","CdelSuelo","LC_Hist","LC_Curr")]

# Write shapefile
write_sf(traza, paste0(output_gcbm, "/inventario_97_v2.shp"))

print(paste("Inventory layer written in",paste0(output_gcbm, "/inventario_97_v2.shp")))

