Inventory Layer
===============

The Inventory Layer file creates the initial inventory layer. The
``input_traza``, ``input_SOC`` and the ``output_gcbm`` parameters define
the Trazabilidad file where the land usage data is stored, the folder
where the soil organic carbon data is stored and the folder of the
output data respectively.

Apart from this, we define the ``inventory_year`` which denotes the
initial year of model execution. The ``layer_traza`` and ``layer_SOC``
defines the land use data (Trazabilidad) and the Soil organic carbon
data from FAO respectively.

We will be generating the inventory layer from the trazabilidad file by
reading the same and optionally filtering the database to accommodate
the polygons that were forest at a particular point in the time-series
data. Further, the classifiers are assigned, which includes the Tipofor
classifier, Forest structure classifier and Origin classifier.

The Tipofor classifier gets the forest types from the 1997 map and
assigns the "Bosque Mixto" and "Matorral Arborescente" forest type from
the T1 column. Polygons that are "non forest" will be left as No
Forestal.

.. code:: R

   traza$Tipofor <- as.character(traza$T_F_97)

   traza$Tipofor <- ifelse(traza$T1 == "0403", "Bosque Mixto", as.character(traza$Tipofor))

   traza$Tipofor <- ifelse(traza$T1 == "0304", "Matorral Arborescente", as.character(traza$Tipofor))

   traza$Tipofor <- ifelse(is.na(traza$Tipofor), "No forestal", as.character(traza$Tipofor))

The Forest structure classifier follows the same steps, albeit we add a
filter to leave only 4 columns. The origin classifier is used to
distinguish between forests that comes from the initial inventory
(bosque inicial) for accounting purposes.

Initially, the shapefile is reprojected and the SOC is calculated by
calculating the mean of each polygon. Later the age and SOC is
determined by reprojecting the input shapefile to latitude and longitude
and calculating the mean data in each polygon. If the GCBM detects a SOC
greater than 0 in a forest pixel it will not work.

Finally, the historic and current land use assumptions are made, taking
into account, FL if it is a native forest, and CL if not. The shapefile
is written and the inventory layer is published in the ``Output_files``
directory.
