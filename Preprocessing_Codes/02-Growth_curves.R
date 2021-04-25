# ----------------------------
# Export the Excel spreadsheet with growth curves to accepted csv format
# ----------------------------
print("Building the growth curves")

#------------------------------------------------------
# Library management

# we use the checkpoint package to secure reproducibility, 
# it will download the package version of that specific date
library("checkpoint")
checkpoint("2019-10-01", scanForPackages = FALSE) # Date of compatibility packages

# Load the necessary packages
library(dplyr)

#-----------------------------
# Parameters

# Age in which the growth of the forest stops
age_stop_growth <- 100

# Maximum age reflected in the growth curves
age_max_curves <- 200

# Annual periodic increment tables (m3/ha/year), this is increments in commertial wood (aboveground)
growth_table <- tibble::tribble(
        ~TipoFor_classifier, ~Annual_Growth_Renoval, ~Annual_Growth_AdultoRenoval,
                   "Alerce",                   0.45,                         0.45,
                "Araucaria",                    4.6,                          4.6,
             "Bosque Mixto",                   3.68,                         3.68, # Weighted Annual Growth average in Los Rios Region (see: FREL/FRL)
  "Cipres de la Cordillera",                    4.7,                          3.9,
  "Cipres de las Guaitecas",                    3.9,                          3.9,
    "Coihue - Rauli - Tepa",                    5.1,                            4,
     "Coihue de Magallanes",                    6.1,                          4.6,
              "Esclerofilo",                    2.2,                          1.9,
                    "Lenga",                      6,                          5.2,
   "Roble - Rauli - Coihue",                    6.1,                            5,
             "Siempreverde",                    5.8,                          3.2,
    "Matorral Arborescente",                    1.9,                          1.9,
        "Promedio Regional",                   4.96,                         4.96 # Weighted Annual Growth average in Los Rios Region (see: FREL/FRL)

  )

# Regional average volume (m3/ha)
regional_vol <- 375.2900742

# Regional average volume for the Matorral Arborescente forest type
# This value was calculated using a the avobeground biomass of the matorral arborecente (21.78 ton/ha)
regional_vol_ma <- 24.89143

# ----------------------------------------------------
# Folders paths

# Output folder for the gcbm
output_gcbm <- "./Output_Files/input_database"

# ---------------------------
# Construct the growth curves

# Forest types (Tipofor classifier) present in the area
forest_types <- c("Alerce", "Araucaria", "Cipres de la Cordillera", "Cipres de las Guaitecas", "Coihue - Rauli - Tepa",
                  "Coihue de Magallanes", "Esclerofilo", "Lenga", "Roble - Rauli - Coihue", "Siempreverde")

# Forest Structures in the area 
structures <- c("Renoval","Adulto Renoval","Adulto","Achaparrado")

# I am going to start with the forest coming from forestation activities (Bosque Aumento)
Origen <- "Bosque Aumento FREL"

# I am gpoing to assing the Red Alder species, this will be replaced afterwards with a Chilean generic species parameters
AIDBSPP <- "Red alder"

counter <- 1

# I am going to create a growth curve for each bombination of forest type (Tipofor) and structure (Estruc)
for (Tipofor in forest_types){
  for (Estruc in structures){
    
    # I am going to create a growth curve for each combination of forest type and structure
    
    # If the structure is renoval or adulto renoval use the annual growth rate of the renoval forest, as in the FREL (check excel files)
    if (Estruc %in% c("Renoval","Adulto Renoval")){
      growth_year <- dplyr::select(filter(growth_table,TipoFor_classifier == Tipofor),Annual_Growth_Renoval)
    } 
    
    # If the structure is Adulto or Achaparrado use the annual growth rate of the Adulto-renoval forest, as in the FREL (check excel files)
    if (Estruc %in% c("Adulto","Achaparrado")){
      growth_year <- dplyr::select(filter(growth_table,TipoFor_classifier == Tipofor),Annual_Growth_AdultoRenoval)
    } 

    # The forest will grow for age_stop_growth years and then stop
    seq_growth_first <- seq(from= 0, by=as.numeric(unname(growth_year)),length.out = age_stop_growth+1)
    
    # Repeat the last value until the end of the curve
    seq_growth_last <- rep(seq_growth_first[length(seq_growth_first)],age_max_curves - age_stop_growth)
    
    # Merge the two parts of the growth curve
    seq_growth <- c(seq_growth_first,seq_growth_last)
    
    # Join the volume sequence with the classfiers
    growth_curve <- c(Tipofor,Estruc,Origen,AIDBSPP,seq_growth)
    growth_curve
    
    # Create the complete dataframe
    if (counter == 1){
      growth <- rbind(growth_curve)
    } else {
      growth <- rbind(growth,growth_curve)
    }
    
    counter = counter + 1
    
  }
}

# Now add extra classifiers curves

#######
# Bosque mixto is a mix of several forest types and has its own classifier
growth_year <- dplyr::select(filter(growth_table,TipoFor_classifier == "Bosque Mixto"),Annual_Growth_Renoval)

# Build the growth curve growing n years and then stopping
seq_growth_first <- seq(from= 0, by=as.numeric(unname(growth_year)),length.out = age_stop_growth+1)
seq_growth_last <- rep(seq_growth_first[length(seq_growth_first)],age_max_curves - age_stop_growth)
seq_growth <- c(seq_growth_first,seq_growth_last)

growth_curve <- c("Bosque Mixto","Bosque Mixto",Origen,AIDBSPP,seq_growth)

# Append it to the dataframe
growth <- rbind(growth,growth_curve)

######
# Matorral Arborescente is not properly a forest type but due to a change in the forest definition it is included in the FREL
growth_year <- dplyr::select(filter(growth_table,TipoFor_classifier == "Matorral Arborescente"),Annual_Growth_Renoval)

# Build the growth curve growing n years and then stopping
seq_growth_first <- seq(from= 0, by=as.numeric(unname(growth_year)),length.out = age_stop_growth+1)
seq_growth_last <- rep(seq_growth_first[length(seq_growth_first)],age_max_curves - age_stop_growth)
seq_growth <- c(seq_growth_first,seq_growth_last)

# As it has a different root factor, here I will se the Western larch species in the AIDBSPP field, that will be replaced with a Chilean custom species
growth_curve <- c("Matorral Arborescente","Matorral Arborescente",Origen,"Western larch",seq_growth)

# Append it to the dataframe
growth <- rbind(growth,growth_curve)

######
# Promedio Regional is a "artifitial" forest type created when the forest type is not possible to determnine (included in the REDD+ Annex)
growth_year <- dplyr::select(filter(growth_table,TipoFor_classifier == "Promedio Regional"),Annual_Growth_Renoval)

# Build the growth curve growing n years and then stopping
seq_growth_first <- seq(from= 0, by=as.numeric(unname(growth_year)),length.out = age_stop_growth+1)
seq_growth_last <- rep(seq_growth_first[length(seq_growth_first)],age_max_curves - age_stop_growth)
seq_growth <- c(seq_growth_first,seq_growth_last)

growth_curve <- c("Promedio Regional","Promedio Regional",Origen,AIDBSPP,seq_growth)

# Append it to the dataframe
growth <- rbind(growth,growth_curve)



# Repeat the growth curve to represent pre FREL forests, that have the same growth curves
growth_pre <- growth
growth_pre[,3] <- "Bosque Aumento preFREL"
growth <- rbind(growth,growth_pre)


#---------------------------------------------
# Now we will create the growth curves for the Bosque Inicial (Initial Forest)

Origen <- "Bosque Inicial"

# I am going to assign the Red Alder species, this will be replaced afterwards with a Chilean generic species parameters
AIDBSPP <- "Red alder"

# Go for all combinations of forest type and structure
for (Tipofor in forest_types){
  for (Estruc in structures){
    
    # This is the forest that will be deforested, then a regional average will be used to get the same growth for all forest types
    growth_year <- regional_vol / age_stop_growth


    # Build the growth curve growing n years and then stopping
    # The growth curve will give a fixed value of volume for all the forest in the area
    seq_growth_first <- seq(from= 0, by=as.numeric(unname(growth_year)),length.out = age_stop_growth+1)
    seq_growth_last <- rep(seq_growth_first[length(seq_growth_first)],age_max_curves - age_stop_growth)
    seq_growth <- c(seq_growth_first,seq_growth_last)
    

    # Join the volume values with the classifiers
    growth_curve <- c(Tipofor,Estruc,Origen,AIDBSPP,seq_growth)
    
    # Append the curve to the dataframe
    growth <- rbind(growth,growth_curve)

    
  }
}

# Now add extra classifiers curves for the Initial forest

# Bosque mixto is a mix of several forest types and has its own classifier
# We will use the same sequence of growth as the rest of the forest types
growth_curve <- c("Bosque Mixto","Bosque Mixto",Origen,AIDBSPP,seq_growth)

# Append it to the dataframe
growth <- rbind(growth,growth_curve)


# Promedio Regional is a "artifitial" forest type created when the forest type is not possible to determnine (included in the REDD+ Annex)
# We will use the same sequence of growth as the rest of the forest types
growth_curve <- c("Promedio Regional","Promedio Regional",Origen,AIDBSPP,seq_growth)

# Append it to the dataframe
growth <- rbind(growth,growth_curve)


# Matorral Arborescente is not properly a forest type but due to a change in the forest definition it is included in the FREL
# It has a different regional volume average, that will be used to calculate the growth
growth_year <- regional_vol_ma / age_stop_growth

# Build the growth curve growing n years and then stopping
seq_growth_first <- seq(from= 0, by=as.numeric(unname(growth_year)),length.out = age_stop_growth+1)
seq_growth_last <- rep(seq_growth_first[length(seq_growth_first)],age_max_curves - age_stop_growth)
seq_growth <- c(seq_growth_first,seq_growth_last)

# As it has a different root factor, here I will se the Western larch species in the AIDBSPP field, that will be replaced with a Chilean custom species
growth_curve <- c("Matorral Arborescente","Matorral Arborescente",Origen,"Western larch",seq_growth)

# Append it to the dataframe
growth <- rbind(growth,growth_curve)


# ---------------------------------
# One last curve for non-stocked (non forest) pixels

# It does not grow, hence 0 in all years
seq_growth <- rep(0,age_max_curves + 1 )

# Use the "non stocked" species so the GCBM will ignore the growth
growth_curve <- c("No forestal","No forestal","No forestal","Not stocked",seq_growth)

# Append it to the dataframe
growth <- rbind(growth,growth_curve)



#----------------------------------------
# Assing names to the dataframe
seq_ages <- paste0("A",0:age_max_curves)
column_names <- c("Tipofor","Estruc","Origen","AIDBSPP",seq_ages)
growth <- as.data.frame(growth)
names(growth) <- column_names

# Convert volume values to numeric
growth[seq_ages] <- lapply(growth[seq_ages],function(x) as.numeric(as.character(x)))

# Convert clasiffiers to text
growth[c("Tipofor","Estruc","Origen","AIDBSPP")] <- lapply(growth[c("Tipofor","Estruc","Origen","AIDBSPP")],function(x) as.character(x))

# Write csv file
write.csv(growth,paste0(output_gcbm,"/Growth_Curves_LosRios.csv"))

print(paste("Growth curves file created, file written in:", paste0(output_gcbm, "/Growth_Curves_LosRios.csv")))


