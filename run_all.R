########################################
# Run this code inside of an R project
# It will source all preprocessing codes and generate the data for the GCBM
########################################


# Install packages
source("./Preprocessing_Codes/00-Install_packages.R")

# 1. Process the temperature layer (raster file from CR2)
source("./Preprocessing_Codes/01-Temperature_layer.R")

# Clean objects to save RAM
rm(list = ls())
gc()

# 2. Create growth curves
source("./Preprocessing_Codes/02-Growth_curves.R")

rm(list = ls())
gc()

# 3. Create the inventory layer (initial 1997 land cover)
source("./Preprocessing_Codes/03-Inventory_layer.R")

rm(list = ls())
gc()

# 4. Create the afforestation layer (non forest to forest)
source("./Preprocessing_Codes/04-Afforestation_layer.R")

rm(list = ls())
gc()

# 5. Create the forest loss layer (forest to non-forest)
source("./Preprocessing_Codes/05-Forest_loss_layer.R")

rm(list = ls())
gc()

# 6. Create the forest degradation layer (carbon loss in forest remaining forest)
source("./Preprocessing_Codes/06-Forest_degradation_layer.R")

rm(list = ls())
gc()

# 7. Create the forest enhancement layer (carbon gain in forest remaining forest)
source("./Preprocessing_Codes/07-Forest_enhancement_layer.R")

rm(list = ls())
gc()

print("All layers preprocessed!")

