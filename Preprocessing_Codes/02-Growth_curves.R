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
if (!require(openxlsx)) install.packages("openxlsx")

# Load the necessary packages
library(openxlsx) # Handle exel files


# ----------------------------------------------------
# Folders paths

# Temperature raster folder
input_growth <- "./Input_Files/Growth"

# Output folder
output_gcbm <- "./Output_Files/input_database"

# ---------------------------
# File names

# Excel spreadsheet with growth curves (and explanations on how they were obtained)
growth_excel <- "Growth_Curves_LosRios.xlsx"

# ---------------------------

# Read excel file
growth <- read.xlsx(paste0(input_growth,"/",growth_excel))

# Write csv file
write.csv(growth,paste0(output_gcbm,"/Growth_Curves_LosRios.csv"))


