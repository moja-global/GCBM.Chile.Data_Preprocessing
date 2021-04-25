# ----------------------------
# Create the degradation layers and disturbance matrix values
# ----------------------------
print("Creating the forest degradation layer (including degradation in conservation areas)")


#------------------------------------------------------
# Library management

# we use the checkpoint package to secure reproducibility, 
# it will download the package version of that specific date
library("checkpoint")
checkpoint("2019-10-01", scanForPackages = FALSE) # Date of compatibility packages

# Load the necessary packages
library(sf) # simple feature package for shape processing
library(dplyr) # database handling
library(rgdal) # gdal library

# ----------------------------------------------------
# Folder Paths

# Folder where the Permanent forest files are
input_pf <- "./Input_Files/Permanent_Forest"

# Folder of the output data for the model
output_gcbm <- "./Output_Files/layers/raw/disturbances"

# ---------------------------
# Layer names

# Permanent forest layer
layer_pf <- "CO2_Permanent_Forest_LosRios"

#----------------------------
# Parameters

# The permanent forest layer in the FREL has two years, 2001 and 2010
year_t1 <-2001
year_t2 <-2010

# Number of quantiles to represent the degradation
n_quantiles <- 20

# Random seed to ensure reproducibility
set.seed(31102019)

#-----------------------------------------------------------------

# Read the permanent forest shapefile
pf <- st_read(dsn = input_pf, layer = layer_pf)


# The codes that indicate degradation are 2,3,4 and 10000, 10001 in the "Carta" 
# The Change in CO2 (CAM_CO2) has to be negative
degradation <- dplyr::filter(
  pf,
  Carta %in% c("2", "3", "4", "10000", "10001"),
  CAM_CO2 < 0)

# Define a random year for the degradation between 2002 and 2010
degradation$year<-sample((year_t1+1):year_t2,nrow(degradation),replace=TRUE)
degradation$year

# Calculate the regional average of CO2
# 375.29 is the regional average of Volume
# 0.5 is the density of the wood
# 0.5 is the fraction of carbon
# 3.6666 to convert from C to CO2
regional_CO2 <- (375.2900742 * 1.75 * 0.5)  * 0.5 * (44/12)

regional_CO2


# Now I am going to calculate the percentage of the regional CO2 that is lost in each degradation pixel
degradation$p_regional <- (degradation$CAM_CO2 / regional_CO2) * (-1)

min(degradation$CAM_CO2)
max(degradation$CAM_CO2)

min(degradation$p_regional)
max(degradation$p_regional)

# I am going to separate the shapefile into two

# Degradation that occurs in conservation areas
degradation_c <- dplyr::filter(degradation,ca_ras_erp>0)

# Degradation that occurs outside of conservation areas
degradation <- dplyr::filter(degradation,ca_ras_erp==0)


# Calculate the quantiles
degradation$quantile <- cut(degradation$p_regional , breaks = quantile(degradation$p_regional, seq(0,1,length.out = n_quantiles+1)),labels=1:n_quantiles, include.lowest=TRUE)

# Get the mean of each quantile
means_quantile <- group_by(as.data.frame(degradation), quantile) %>% summarize(mean_quan = mean(p_regional))


# Get the name of the disturbance according to the quantile (intensity level)
degradation$Perturb <- paste0("Forest ", "Degradation Chile"," intensity lvl ",degradation$quantile)


# Now the same with the degradation in degradation areas

# Calculate the quantiles
degradation_c$quantile <- cut(degradation_c$p_regional , breaks = quantile(degradation_c$p_regional, seq(0,1,length.out = n_quantiles+1)),labels=1:n_quantiles, include.lowest=TRUE)

# Get the mean of each quantile
means_quantile_c <- group_by(as.data.frame(degradation_c), quantile) %>% summarize(mean_quan = mean(p_regional))

# Get the name of the disturbance according to the quantile (intensity level), include Conservation in the name
degradation_c$Perturb <- paste0("Forest Conservation ", "Degradation Chile"," intensity lvl ",degradation_c$quantile)


# Join the two degradations into a single shape
degradation <- rbind(degradation,degradation_c)


# Select the columns we care about
degradation<-degradation[,c("year","Perturb")]

# Project to WGS84 latlong
degradation<-st_transform(degradation, "+proj=longlat +datum=WGS84 +ellps=WGS84 +towgs84=0,0,0")

# Year column as integer
degradation$year<-as.integer(degradation$year)

# Write shapefile that will be used as input for the tiler (GCBM)
write_sf(degradation, paste0(output_gcbm, "/forest_degradation_LosRios.shp"))
print(paste("Degradation layer written in",paste0(output_gcbm, "/forest_degradation_LosRios.shp")))


#---------------------------------------------
# Using the information of each quantile we will make the disturbance matrices to insert them into the gcbm_input database
# Create the distrubance types csv
print("Creating the forest degradation disturbance matrices")

# Start the id counting from 9003 (9001 and 9002 are deforestation and substitution)
id <- 9003
disturbance_category_id <- 1

# Degradation does not produce a land use change
transition_land_class_id <- "NULL"

lvl <- 1

# In a for loop we will sight a disturbance in each iteration, 
# first degradation outside conservation and then insidee conservation areas
for (i in 1:(n_quantiles*2)) {
  
  # Return to intensity level 1 when we start processing the degradation in conservation disturbances 
  if (i==n_quantiles+1){
    lvl <- 1
  }
  
  # the first n_quantile iterations are for degradation and then for degradation in conservation
  if (i<= n_quantiles){
    name <- paste0("Forest Degradation Chile intensity lvl ",lvl)
  } else {
    name <- paste0("Forest Conservation Degradation Chile intensity lvl ",lvl)
  }
  
  # Code is just the same as id
  code <- id
  
  # Form the disturbance type of this iteration
  disturbance_type <- cbind(id,disturbance_category_id,transition_land_class_id,name,code)
  
  # Genrate the dataframe with all the disturbances
  if (i==1){
    disturbance_types_full <- disturbance_type
  } else {
    disturbance_types_full <- rbind(disturbance_types_full,disturbance_type)
  }
  
  # Go for next id and intensity level
  id <- id + 1
  lvl <- lvl + 1
  
}

# Write the csv that will be inserted into the gcbm_input database
write.csv(as.data.frame(disturbance_types_full),"./Output_Files/input_database/Degradation_disturbance_types.csv",row.names = FALSE)


# Create the distrubance matrix csv
# This datafrmae just assingns an id and name to the distrubance matrix

# It starts from 903 (901 and 902 are deforestation and substitution)
id <- 903
lvl <- 1

# Same as before, first degradation outside conservation and then insidee conservation areas
for (i in 1:(n_quantiles*2)) {
  
  if (i==n_quantiles+1){
    lvl <- 1
  }
  
  if (i<= n_quantiles){
    name <- paste0("Forest Degradation Chile intensity lvl ",lvl)
  } else {
    name <- paste0("Forest Conservation Degradation Chile intensity lvl ",lvl)
  }
  
  # Get the disturbance matrix and ID
  disturbance_matrix <- cbind(id,name)
  
  
  if (i==1){
    disturbance_matrix_full <- disturbance_matrix
  } else {
    disturbance_matrix_full <- rbind(disturbance_matrix_full,disturbance_matrix)
  }
  
  id <- id + 1
  lvl <- lvl + 1
  
}

# Write the csv that will be inserted into the gcbm_input database
write.csv(as.data.frame(disturbance_matrix_full),"./Output_Files/input_database/Degradation_disturbance_matrix.csv",row.names = FALSE)


# Create the distrubance matrix association csv
# This dataframe associates the disturbance type with the disturbance matrix

# The disturbance matrix corresponds to spatial unit 36 (British columba and Pacific maritime)
spatial_unit_id <- 36

# The disturbance matrix id starts from 9003 (9001 and 9002 are deforestation and substitution)
disturbance_type_id <- 9003

# The disturbance matrix id starts from 903 (901 and 902 are deforestation and substitution)
disturbance_matrix_id <- 903


# Same as before, first degradation outside conservation and then insidee conservation areas
for (i in 1:(n_quantiles*2)) {
  
  #Build the matrix association with the spatial unit and the two ids
  disturbance_matrix_association <- cbind(spatial_unit_id,disturbance_type_id,disturbance_matrix_id)
  
  # Build the complete dataframe
  if (i==1){
    disturbance_matrix_association_full <- disturbance_matrix_association
  } else {
    disturbance_matrix_association_full <- rbind(disturbance_matrix_association_full,disturbance_matrix_association)
  }
  
  # increase the ids by one
  disturbance_type_id <- disturbance_type_id + 1
  disturbance_matrix_id <- disturbance_matrix_id + 1
  
}

# Write the csv that will be inserted into the gcbm_input database
write.csv(as.data.frame(disturbance_matrix_association_full),"./Output_Files/input_database/Degradation_disturbance_matrix_association.csv",row.names = FALSE)






# Create the disturbance matrix values csv
# This dataframe includes the proportion of each reservoir that goes to CO2

# The disturbance matrix id starts from 903 (901 and 902 are deforestation and substitution)
dist_id <- 903


for (i in 1:(n_quantiles*2)) {
  
  # Repeat the id of the matrix 10 times, as there will be 10 different transfers from one reservoir to another
  disturbance_matrix_id <- rep(dist_id,6)
  # The reservoirs  1,2,3,6,7,8 are the reservoirs of the avobe ground biomass, that will be the source
  source_pool_id <- c(1,2,3,6,7,8)
  
  # The sink reservoir (target) will be the 22 (CO2)
  sink_pool_id <- rep(22,6)
  
  # Get the mean of each quantile, in the first n_quantile iterations degradation outside conservation
  if (i<= n_quantiles){
    proportion <- rep(means_quantile$mean_quan[i],6)
  # Then, take the quantiles inside conservation areas  
  } else {
    proportion <- rep(means_quantile_c$mean_quan[i-n_quantiles],6)
  }
  
  # The disturbance matrix values is composed of the id, the source reservoir, the sink (receiver) reservoir, and the proportion of the reservoir that is transferred
  disturbance_matrix <- cbind(disturbance_matrix_id,source_pool_id,sink_pool_id,proportion)
  disturbance_matrix
  
  # Build the full disturbance matrix values dataframe
  if (i==1){
    disturbance_matrix_full <- disturbance_matrix
  } else {
    disturbance_matrix_full <- rbind(disturbance_matrix_full,disturbance_matrix)
  }
  
  dist_id <- dist_id + 1
  
}

# Write the csv that will be inserted into the gcbm_input database
write.csv(as.data.frame(disturbance_matrix_full),"./Output_Files/input_database/Degradation_disturbance_matrix_value.csv",row.names = FALSE)




