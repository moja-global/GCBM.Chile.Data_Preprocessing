# ----------------------------
# Create the forest enhancement layers and add the new growth curves
# ----------------------------
print("Creating the forest enhancement layer (including enhancement in conservation areas)")

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

# Folder of the output data for the GCBM
output_gcbm <- "./Output_Files/layers/raw/disturbances"

# ---------------------------
# Layer names

# Permanent forest layer
layer_pf <- "CO2_Permanent_Forest_LosRios"

# Parameters

# The permanent forest layer in the FREL has two years, 2001 and 2010
year_t1 <-2001
year_t2 <-2010


# Number of quantiles to represent the forest enhancement
n_quantiles <- 20

# Random seed to ensure reproducibility
set.seed(31102020)

# Parameters

# Age in which the growth of the forest stops
age_stop_growth <- 100

# Maximum age reflected in the growth curves
age_max_curves <- 200

#-----------------------------------------------------------------
# Generate a shapefile with the all the enhancements in the permanent forest


# Read the permanent forest shapefile
pf <- st_read(dsn = input_pf, layer = layer_pf)


# The codes that indicate enhancement are 10002, 19999, 20000 and 4, 10001 in the "Carta" field
# The Change in CO2 (CAM_CO2) has to be positive
enhancement <- dplyr::filter(
  pf,
  Carta %in% c("10002", "19999", "20000", "4", "10001"),
  CAM_CO2 > 0)

# The enhancement will occur at the beginning of the period (2002)
enhancement$year <- year_t1+1


# Based on the yearly growth in volume I will create the new growth curves 

# Now I am going to calculate the yearly growth of each enhancement pixel, we will consider the stock difference as 9 years (as in the FREL excel files)
enhancement$year_grow <- enhancement$CAM_CO2 / 9


# I am going to separate the shapefile into two

# Enhancement that occurs in conservation areas
enhancement_c <- dplyr::filter(enhancement,ca_ras_erp>0)

# Enhancement that occurs outside of conservation areas
enhancement <- dplyr::filter(enhancement,ca_ras_erp==0)


# Calculate the quantiles
enhancement$quantile <- cut(enhancement$year_grow , breaks = quantile(enhancement$year_grow, seq(0,1,length.out = n_quantiles+1)),labels=1:n_quantiles, include.lowest=TRUE)

# Get the mean growth of each quantile 
means_quantile <- group_by(as.data.frame(enhancement), quantile) %>% summarize(mean_quan = mean(year_grow))

# Get the name of the enhancement disturbance according to the quantile (intensity level)
enhancement$Origen_pa <- paste0("Forest ", "Enhancement Chile"," intensity lvl ",enhancement$quantile)

# The disturbance name, it will be changed in the tiler
enhancement$Perturb <- "Enhancement"

# Now the same with the conservation enhancement

# Calculate the quantiles
enhancement_c$quantile <- cut(enhancement_c$year_grow , breaks = quantile(enhancement_c$year_grow, seq(0,1,length.out = n_quantiles+1)),labels=1:n_quantiles, include.lowest=TRUE)

# Get the mean of each quantile 
means_quantile_c <- group_by(as.data.frame(enhancement_c), quantile) %>% summarize(mean_quan = mean(year_grow))

# Get the name of the enhancement disturbance according to the quantile (intensity level)
enhancement_c$Origen_pa <- paste0("Forest Conservation ", "Enhancement Chile"," intensity lvl ",enhancement_c$quantile)

# The disturbance name, it will be changed in the tiler
enhancement_c$Perturb <- "Enhancement Conservation"

 
# Put both enhancement shapefiles together
enhancement <- rbind(enhancement,enhancement_c)


# Select the columns we care about
enhancement<-enhancement[,c("year","Perturb","Origen_pa")]

# a ? sign in the Tipofor and Estruc classfiers makes the GCBM keep the current classifiers 
enhancement$Tipofor_pa <- "?"
enhancement$Estruc_pa <- "?"


# Now, after 9 years the forest will return to the "Bosque Inicial" (Initial forest) Origin

# Create a copy of the enhancement shape
enhancement_stop <- enhancement

# Change the origin classifier to Bosque Inicial 
enhancement_stop$Origen_pa <- "Bosque Inicial"

# Make the enhancement stop one year after the FRL period
enhancement_stop$year <- year_t2+1

# Now put everything together
enhancement <- rbind(enhancement,enhancement_stop)

# Project to WGS84 latlong
enhancement<-st_transform(enhancement, "+proj=longlat +datum=WGS84 +ellps=WGS84 +towgs84=0,0,0")

# Year column as integer
enhancement$year<-as.integer(enhancement$year)

# Write shapefile as input for the tiler (GCBM)
write_sf(enhancement, paste0(output_gcbm, "/forest_enhancement_LosRios.shp"))
print(paste("Forest enhancement layer written in",paste0(output_gcbm, "/forest_enhancement_LosRios.shp")))

#--------------------------------------
# Now we are going to modify the growth curves to reflect the enhancements
print("Including the forest enhancement into the growth curves")

# Read the growth curves
growth <- read.csv("./Output_Files/input_database/Growth_Curves_LosRios.csv",stringsAsFactors=FALSE)

# Remove row names 
growth <- growth[,-1]

#----------------------------------------------------------
# Create the growth curves including all the forest enhancement curves


# For loop that starts with the enhancement outside conservation areas and then with the enhancement inside degradation areas
for (i in 1:(n_quantiles*2)) {
  
  
  # the first n_quantile iterations are for enhancement and then for enhancement in conservation areas
  if (i<= n_quantiles){
    enhancement_name <- paste0("Forest ", "Enhancement Chile"," intensity lvl ",i)
  } else {
    enhancement_name <- paste0("Forest ", "Conservation Enhancement Chile"," intensity lvl ",i-20)
  }
  
  # We are going to create a "base" of all combinations of Tipofor and Estruc values, selecting the Bosque inicial Origin classifier
  growth_base <- filter(growth,Origen %in% c("Bosque Inicial"))
  
  # Change the Origin classifier with the name of the disturbance
  growth_base$Origen <- enhancement_name
  
  # Get the yearly growth for each quantile
  if (i<= n_quantiles) {
    year_grow <- unname(means_quantile$mean_quan[i])
  } else {
    year_grow <- unname(means_quantile_c$mean_quan[i-n_quantiles])
  }
  
  # The yearly growth is in CO2, we will convert it into volume 
  # 0.2869 is the Root factor
  # 0.5 is the density of the wood
  # 0.5 is the fraction of carbon
  # 3.6666 to convert from C to CO2
  year_grow_vol <- year_grow / (1.75 * 0.5 * 0.5 * (44/12))

  # Gurld the growth curve from 0 to the end (there are 4 columns with 3 classifers and the species data)
  growth_curve <- seq(from= 0, by=year_grow_vol,length.out = ncol(growth_base)-4)
  
  # tramsform into dataframe
  growth_curve <- unname(rbind(growth_curve))
  
  # Repeat the growth curve several times (same number of rows as the growth curves)
  growth_curve <- growth_curve[rep(seq_len(nrow(growth_curve)), nrow(growth_base)), ]
  
  # Insert (replace) the growth curves into the growth base dataframe
  growth_base[,5:ncol(growth_base)] <- growth_curve
  
  # Build the full dataframe and append it to the previows growth curves
  if (i==1){
    growth_full <- rbind(growth, growth_base)
  } else {
    growth_full <- rbind(growth_full,growth_base)
  }

}

# Create growth curves for "No forestal" (non-forest), just to avoid errors in the logs


# For loop that starts with the enhancement outside conservation areas and then with the enhancement inside degradation areas
for (i in 1:(n_quantiles*2)) {
  
  
  # the first n_quantile iterations are for enhancement and then for enhancement in conservation areas
  if (i<= n_quantiles){
    enhancement_name <- paste0("Forest ", "Enhancement Chile"," intensity lvl ",i)
  } else {
    enhancement_name <- paste0("Forest ", "Conservation Enhancement Chile"," intensity lvl ",i-20)
  }
  
  growth_curve <- c("No forestal","No forestal",enhancement_name,"Not stocked",rep(as.numeric(0), ncol(growth_base)-4))
  growth_curve
  growth_full <- rbind(growth_full,growth_curve)
  
}


# Non stocked Bosque Inicial

# It does not grow, hence 0 in all years
seq_growth <- rep(0,age_max_curves + 1 )

# Use the "non stocked" species so the GCBM will ignore the growth
growth_curve <- c("No forestal","No forestal","Bosque Inicial","Not stocked",seq_growth)

# Append it to the dataframe
growth_full <- rbind(growth_full,growth_curve)



# Names of columns
seq_ages <- names(growth_full)[5:ncol(growth_full)]
seq_ages


# Convert volume values to numeric
growth_full[seq_ages] <- lapply(growth_full[seq_ages],function(x) as.numeric(as.character(x)))

# Convert clasiffiers to text
growth_full[c("Tipofor","Estruc","Origen","AIDBSPP")] <- lapply(growth_full[c("Tipofor","Estruc","Origen","AIDBSPP")],function(x) as.character(x))


# Write the csv with the growth curves including the enhancement curves
write.csv(as.data.frame(growth_full),"./Output_Files/input_database/Growth_Curves_LosRios.csv")

print("Done!")
          


