# ----------------------------
# Create the afforestation layer: Land use changes from non forest to forest
# ----------------------------
print("Creating the afforestation layer (planting of new forests)")

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
set.seed(01112019)

#-----------------------------------------------------------------
# Generate the afforestation shapefile

# Read the LUC shapefile
traza <- st_read(dsn = input_traza, layer = layer_traza)

# Filter to identify poligons that went from nonforest to forest between T1 and T2
afor_t2<- dplyr::filter(
  traza,
  !(T1 %in% c("0403", "040203", "040202", "040204", "040201", "0402","0304")),
  T2 %in% c("0403", "040203", "040202", "040204", "040201", "0402","0304"))


# Assing year and name of the disturbance
afor_t2$year <- year_t2
afor_t2$Perturb <- "Aforestacion"

# We are going to assing a random year between T1 and T2 for the disturbance
# from 1997 to 2006 (included), according to the excel files
afor_t2$year<-sample(year_t1:(year_t2),nrow(afor_t2),replace=TRUE)
afor_t2$year

# I need the post-disturbance forest type
afor_t2$Tipofor_pa <- as.character(afor_t2$T_F_06)

# In case of Bosque Mixto Forest Type
afor_t2$Tipofor_pa <- ifelse(afor_t2$T2 == "0403", "Bosque Mixto", as.character(afor_t2$Tipofor_pa))

# In case of Matrorral Arborescente Forest type
afor_t2$Tipofor_pa <- ifelse(afor_t2$T2 == "0304", "Matorral Arborescente", as.character(afor_t2$Tipofor_pa))

# The ones without forest type will have the regional average growth, according to the REDD+ Technical annex
afor_t2$Tipofor_pa <- ifelse(is.na(afor_t2$Tipofor_pa), "Promedio Regional", as.character(afor_t2$Tipofor_pa))

# Post- Disturbance Forest Structure
afor_t2$Estruc_pa <- as.character(recode(afor_t2$ID_EST_06,
                                    "01" = "Adulto",
                                    "02" = "Renoval",
                                    "03" = "Adulto Renoval",
                                    "04" = "Achaparrado"
                                      ))

# In case of Bosque Mixto Forest Type
afor_t2$Estruc_pa <- ifelse(afor_t2$T2 == "0403", "Bosque Mixto", as.character(afor_t2$Estruc_pa))

# In case of Matrorral Arborescente Forest type
afor_t2$Estruc_pa <- ifelse(afor_t2$T2 == "0304", "Matorral Arborescente", as.character(afor_t2$Estruc_pa))

# The ones without forest type will have the regional average growth, according to the REDD+ Technical annex
afor_t2$Estruc_pa <- ifelse(is.na(afor_t2$Estruc_pa), "Promedio Regional", as.character(afor_t2$Estruc_pa))

# I will leave the important columns
afor_t2<-afor_t2[,c("year","Perturb","Tipofor_pa","Estruc_pa")]

#---------------------------------------------------------
# Same process with T3, refer to comments on T2

afor_t3<-dplyr::filter(
  traza,
  !(T2 %in% c("0403", "040203", "040202", "040204", "040201", "0402","0304")),
  T3 %in% c("0403", "040203", "040202", "040204", "040201", "0402","0304")
  )

afor_t3$year<-year_t3
afor_t3$Perturb<-"Aforestacion"

# In this case the 2013 is included, but not 2006
afor_t3$year<-sample((year_t2+1):year_t3,nrow(afor_t3),replace=TRUE)

# Post - disturbance forest type and structure

afor_t3$Tipofor_pa <- as.character(afor_t3$T_F_13)

afor_t3$Tipofor_pa <- ifelse(afor_t3$T3 == "0403", "Bosque Mixto", as.character(afor_t3$Tipofor_pa))

afor_t3$Tipofor_pa <- ifelse(afor_t3$T3 == "0304", "Matorral Arborescente", as.character(afor_t3$Tipofor_pa))

afor_t3$Tipofor_pa <- ifelse(is.na(afor_t3$Tipofor_pa), "Promedio Regional", as.character(afor_t3$Tipofor_pa))

afor_t3$Estruc_pa <- as.character(recode(afor_t3$ID_EST_13,
                                           "01" = "Adulto",
                                           "02" = "Renoval",
                                           "03" = "Adulto Renoval",
                                           "04" = "Achaparrado"
                                            ))

afor_t3$Estruc_pa <- ifelse(afor_t3$T3 == "0403", "Bosque Mixto", as.character(afor_t3$Estruc_pa))

afor_t3$Estruc_pa <- ifelse(afor_t3$T3 == "0304", "Matorral Arborescente", as.character(afor_t3$Estruc_pa))

afor_t3$Estruc_pa <- ifelse(is.na(afor_t3$Estruc_pa), "Promedio Regional", as.character(afor_t3$Estruc_pa))

afor_t3<-afor_t3[,c("year","Perturb","Tipofor_pa","Estruc_pa")]


#_----------------------------------------------------------
# Same with T4, the only thing that changes is that the Matorral Arborescente forest type is nos included as Afforestation

afor_t4<-dplyr::filter(
  traza,
  !(T3 %in% c("0403", "040203", "040202", "040204", "040201", "0402")),
  T4 %in% c("0403", "040203", "040202", "040204", "040201", "0402")
  )

afor_t4$year<-year_t4
afor_t4$Perturb<-"Aforestacion"

# Here only the 2014, 2015 and 2016 years are included
afor_t4$year<-sample((year_t3+1):(year_t4-1),nrow(afor_t4),replace=TRUE)
afor_t4$year

# Post - disturbance forest type and structure
afor_t4$Tipofor_pa <- as.character(afor_t4$T_F_17)

afor_t4$Tipofor_pa <- ifelse(afor_t4$T4 == "0403", "Bosque Mixto", as.character(afor_t4$Tipofor_pa))

afor_t4$Tipofor_pa <- ifelse(afor_t4$T4 == "0304", "Matorral Arborescente", as.character(afor_t4$Tipofor_pa))

afor_t4$Tipofor_pa <- ifelse(is.na(afor_t4$Tipofor_pa), "Promedio Regional", as.character(afor_t4$Tipofor_pa))

afor_t4$Estruc_pa <- as.character(recode(afor_t4$ID_EST_17,
                                           "01" = "Adulto",
                                           "02" = "Renoval",
                                           "03" = "Adulto Renoval",
                                           "04" = "Achaparrado"
                                            ))

afor_t4$Estruc_pa <- ifelse(afor_t4$T4 == "0403", "Bosque Mixto", as.character(afor_t4$Estruc_pa))

afor_t4$Estruc_pa <- ifelse(afor_t4$T4 == "0304", "Matorral Arborescente", as.character(afor_t4$Estruc_pa))

afor_t4$Estruc_pa <- ifelse(is.na(afor_t4$Estruc_pa), "Promedio Regional", as.character(afor_t4$Estruc_pa))

afor_t4<-afor_t4[,c("year","Perturb","Tipofor_pa","Estruc_pa")]


#---------------------------------------------------
# Get the afforestation layers together in a single file
afor_total<-rbind(afor_t2,afor_t3,afor_t4)

# Add Origin classier type to distinguish the afforestation forest (aumento)
afor_total$Origen_pa<-ifelse(afor_total$year>2001 & afor_total$year<2014, "Bosque Aumento FREL","Bosque Aumento preFREL")

# Project to latlong
afor_total<-st_transform(afor_total, "+proj=longlat +datum=WGS84 +ellps=WGS84 +towgs84=0,0,0")

# Year column as integer
afor_total$year<-as.integer(afor_total$year)

# Write the shapefile
write_sf(afor_total, paste0(output_gcbm, "/afforestation_LosRios.shp"))

print(paste("Afforestation layer written in",paste0(output_gcbm, "/afforestation_LosRios.shp")))

