Growth Curves
=============

The Growth Curves Code file builds the Growth curves using the Annual
Growth values for each forest type. The ``age_stop_growth`` and
``age_max_curves`` parameters define the age at which the growth of the
forest stops and the maximum age reflected in the growth curves
respectively. The ``growth_table`` defines the annual periodic increment
tables which increment in commercial wood. The ``regional_vol`` and
``regional_vol_ma`` defines the regional average volume and the average
volume for the Matorral Arborescente forest type respectively.

The growth curves are constructed with the help of forest types, forest
structures defined as a list in the R programming language. A growth
curve is constructed for each combination of forest type and forest
structure. Taking an example here where the forest type is Tipofor and
the structure is Estruc:

.. code:: R

   for (Tipofor in forest_types){
     for (Estruc in structures){
       if (Estruc %in% c("Renoval","Adulto Renoval")){
         growth_year <- dplyr::select(filter(growth_table,TipoFor_classifier == Tipofor),Annual_Growth_Renoval)
       }
       if (Estruc %in% c("Adulto","Achaparrado")){
         growth_year <- dplyr::select(filter(growth_table,TipoFor_classifier == Tipofor),Annual_Growth_AdultoRenoval)
       }
       seq_growth_first <- seq(from= 0, by=as.numeric(unname(growth_year)),length.out = age_stop_growth+1)
       seq_growth_last <- rep(seq_growth_first[length(seq_growth_first)],age_max_curves - age_stop_growth)
       seq_growth <- c(seq_growth_first,seq_growth_last)
       growth_curve <- c(Tipofor,Estruc,Origen,AIDBSPP,seq_growth)
       growth_curve
       if (counter == 1){
         growth <- rbind(growth_curve)
       } else {
         growth <- rbind(growth,growth_curve)
       }
       counter = counter + 1
     }
   }

Furthermore, extra classifiers are added. The Bosque mixto is a mix of
several forest types and has its own classifier:

.. code:: R

   growth_year <- dplyr::select(filter(growth_table,TipoFor_classifier == "Bosque Mixto"),Annual_Growth_Renoval)

   seq_growth_first <- seq(from= 0, by=as.numeric(unname(growth_year)),length.out = age_stop_growth+1)
   seq_growth_last <- rep(seq_growth_first[length(seq_growth_first)],age_max_curves - age_stop_growth)
   seq_growth <- c(seq_growth_first,seq_growth_last)

   growth_curve <- c("Bosque Mixto","Bosque Mixto",Origen,AIDBSPP,seq_growth)
   growth <- rbind(growth,growth_curve)

The Matorral Arborescente is not properly a forest type but due to a
change in the forest definition it is included in the FREL:

.. code:: R

   growth_year <- dplyr::select(filter(growth_table,TipoFor_classifier == "Matorral Arborescente"),Annual_Growth_Renoval)

   seq_growth_first <- seq(from= 0, by=as.numeric(unname(growth_year)),length.out = age_stop_growth+1)
   seq_growth_last <- rep(seq_growth_first[length(seq_growth_first)],age_max_curves - age_stop_growth)
   seq_growth <- c(seq_growth_first,seq_growth_last)

   growth_curve <- c("Matorral Arborescente","Matorral Arborescente",Origen,"Western larch",seq_growth)
   growth <- rbind(growth,growth_curve)

The Promedio Regional is an "artificial" forest type created when the
forest type is not possible to determine (included in the REDD+ Annex):

.. code:: R

   growth_year <- dplyr::select(filter(growth_table,TipoFor_classifier == "Promedio Regional"),Annual_Growth_Renoval)

   seq_growth_first <- seq(from= 0, by=as.numeric(unname(growth_year)),length.out = age_stop_growth+1)
   seq_growth_last <- rep(seq_growth_first[length(seq_growth_first)],age_max_curves - age_stop_growth)
   seq_growth <- c(seq_growth_first,seq_growth_last)

   growth_curve <- c("Promedio Regional","Promedio Regional",Origen,AIDBSPP,seq_growth)
   growth <- rbind(growth,growth_curve)

We can then create the growth curves for the Bosque Inicial (Initial
Forest). Right now we are using assign the Red Alder species, which will
be replaced afterwards with Chilean generic species parameters. We go
for all combinations of forest type and structure and the growth curve
will give a fixed value of volume for all the forests in the area:

.. code:: R

   Origen <- "Bosque Inicial"
   AIDBSPP <- "Red alder"

   for (Tipofor in forest_types){
     for (Estruc in structures){
       growth_year <- regional_vol / age_stop_growth
       seq_growth_first <- seq(from= 0, by=as.numeric(unname(growth_year)),length.out = age_stop_growth+1)
       seq_growth_last <- rep(seq_growth_first[length(seq_growth_first)],age_max_curves - age_stop_growth)
       seq_growth <- c(seq_growth_first,seq_growth_last)
       growth_curve <- c(Tipofor,Estruc,Origen,AIDBSPP,seq_growth)
       growth <- rbind(growth,growth_curve)
     }
   }

In a similar manner, we can add extra classifiers curves for the initial
forest. For non-stocked (non-forest) pixels, we can use the "non
stocked" species so the GCBM will ignore the growth:

.. code:: R

   seq_growth <- rep(0,age_max_curves + 1 )
   growth_curve <- c("No forestal","No forestal","No forestal","Not stocked",seq_growth)
   growth <- rbind(growth,growth_curve)

The names are finally assigned to the dataframe and the volume values
are converted to numeric and appended to the dataframe. The CSV files
are written and the growth curve is created.
