# ----------------------------
# Install the necesary packages using the checkpoint package
# ----------------------------

# IMPORTANT: Run this code inside a project executed in the preprocess folder

#------------------------------------------------------
# Library management

# we use the checkpoint package to secure reproducibility,
# it will download the package version of that specific date
if (!require(checkpoint)) install.packages("checkpoint")
library("checkpoint")
# The checkpoint command will scan and install the packages used in the entire project
checkpoint("2019-10-01") # Date of compatibility packages
