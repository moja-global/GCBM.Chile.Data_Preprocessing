Afforestation Layer
===================

The afforestation layer denotes the land-use changes from non-forest to
the forest and creates the afforestation layer. The ``input_traza`` and
``output_gcbm`` parameters define the folder where the land-use change
data is (Trazabilidad file) and the output data folder respectively.

The ``layer_traza`` parameter defines the land use data (Trazabilidad)
with the Trazabilidad layer having four fields (T1, T2, T3, T4) with
land use data for 4 distinct years. Initially, the LUC shapefile is read
and a filter is used to identify polygons that went from non-forest to
forest between T1 and T2.

After assigning the year and name of the disturbance, we assign a random
year between T1 and T2 for the disturbance. We calculate the
post-disturbance forest type for Bosque Mixto forest type, Matrorral
Arborescente forest type including the ones without forest type which
will have the regional average growth, according to the REDD+ Technical
annexe.

.. code:: R

   afor_t2$Tipofor_pa <- as.character(afor_t2$T_F_06)

   afor_t2$Tipofor_pa <- ifelse(afor_t2$T2 == "0403", "Bosque Mixto", as.character(afor_t2$Tipofor_pa))

   afor_t2$Tipofor_pa <- ifelse(afor_t2$T2 == "0304", "Matorral Arborescente", as.character(afor_t2$Tipofor_pa))

   afor_t2$Tipofor_pa <- ifelse(is.na(afor_t2$Tipofor_pa), "Promedio Regional", as.character(afor_t2$Tipofor_pa))

In a similar manner, we calculate the post-disturbance forest structure:

.. code:: R

   afor_t2$Estruc_pa <- as.character(recode(afor_t2$ID_EST_06,
                                       "01" = "Adulto",
                                       "02" = "Renoval",
                                       "03" = "Adulto Renoval",
                                       "04" = "Achaparrado"
                                         ))

   afor_t2$Estruc_pa <- ifelse(afor_t2$T2 == "0403", "Bosque Mixto", as.character(afor_t2$Estruc_pa))

   afor_t2$Estruc_pa <- ifelse(afor_t2$T2 == "0304", "Matorral Arborescente", as.character(afor_t2$Estruc_pa))

   afor_t2$Estruc_pa <- ifelse(is.na(afor_t2$Estruc_pa), "Promedio Regional", as.character(afor_t2$Estruc_pa))

   afor_t2<-afor_t2[,c("year","Perturb","Tipofor_pa","Estruc_pa")]

We will further repeat the same process with T3 and T4. Once completed,
all the afforestation layers are bind together in a single file. We add
the origin classier type to distinguish the afforestation forest and
finally write the shapefile.
