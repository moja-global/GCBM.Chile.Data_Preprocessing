Forest Loss Layer
=================

The Forest Loss Layer code creates the forest loss (deforestation and
substitution) layer. The ``input_traza`` and ``output_gcbm`` parameters
define the folder where the land-use change data is (Trazabilidad file)
and the output data folder respectively.

The ``layer_traza`` parameter defines the land use data (Trazabilidad)
with the Trazabilidad layer having four fields (T1, T2, T3, T4) with
land use data for 4 distinct years. Initially, the LUC shapefile is read
and a filter is used to identify polygons that went from non-forest to
forest between T1 and T2. The year and name of the disturbance are
assigned and a random year is assigned between T1 and T2 for the
disturbance.

The important columns are left out, with 2014, 2015 and 2016 years being
included and the partial layers bind together. The substitution layer is
further developed, from forest to exotic plantations. The polygons that
went from forest to plantations between T1 and T2 are filtered and the
year and type of substitution are assessed.

.. code:: R

   sust_t2<- dplyr::filter(
     traza,
     T1 %in% c("0403", "040203", "040202", "040204", "040201", "0402","0304"),
     T2 %in% c("0401"))

   sust_t2$year<-year_t2
   sust_t2$Perturb<-"Sustitucion"

   sust_t2$year<-sample(year_t1:(year_t2),nrow(sust_t2),replace=TRUE)

   sust_t2<-sust_t2[,c("year","Perturb")]

The disturbance year is randomized, along with disturbances from T3 to
T4. The partial layers are bind together and the forest loss
disturbances layer is bound together. We add the project to the WGS84
latitude and longitude and finally write the shapefile.
