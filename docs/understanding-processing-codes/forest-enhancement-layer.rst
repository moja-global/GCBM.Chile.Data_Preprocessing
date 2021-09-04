Forest Enhancement Layer
========================

The Forest Enhancement layer code creates the forest enhancement layers
and adds the new growth curves, including enhancement in conservation
areas. The ``input_pf`` and ``output_gcbm`` parameters provide the path
of the input folder, where the permanent forest files are, and the
output data for GCBM respectively.

The other parameters include ``year_t1`` and ``year_t2`` which consists
of the permanent forest layer in the FREL for 2001 and 2010
respectively. ``n_quantiles`` denote the number of quantiles to
represent the forest enhancement. On the other hand, ``age_stop_growth``
and ``age_max_curves`` represent the age at which the growth of the
forest stops and the maximum age reflected in the growth curves
respectively.

A shapefile is generated with all the enhancements in the permanent
forest. We read from the permanent forest shapefile and the codes that
indicate enhancement are 10002, 19999, 20000 and 4, 10001 in the "Carta"
field. Do note that the change in CO2 (CAM_CO2) has to be positive.

.. code:: R

   pf <- st_read(dsn = input_pf, layer = layer_pf)

   enhancement <- dplyr::filter(
     pf,
     Carta %in% c("10002", "19999", "20000", "4", "10001"),
     CAM_CO2 > 0)

   enhancement$year <- year_t1+1

Based on the yearly growth in volume we will create the new growth
curves, which includes the yearly growth of each enhancement pixel,
where we will consider the stock difference like 9 years (as in the FREL
excel files). We will further divide the shapefiles into two, one for
the enhancement that occurs in conservation areas while the other for
the enhancement that occurs outside of conservation areas.

.. code:: R

   enhancement$year_grow <- enhancement$CAM_CO2 / 9

   enhancement_c <- dplyr::filter(enhancement,ca_ras_erp>0)

   enhancement <- dplyr::filter(enhancement,ca_ras_erp==0)

The quantiles are calculated, along with the mean growth of each
quantile and the name of the enhancement disturbance according to the
quantile (intensity level). The same process is repeated for the
conservation enhancement.

.. code:: R

   enhancement$quantile <- cut(enhancement$year_grow , breaks = quantile(enhancement$year_grow, seq(0,1,length.out = n_quantiles+1)),labels=1:n_quantiles, include.lowest=TRUE)

   means_quantile <- group_by(as.data.frame(enhancement), quantile) %>% summarize(mean_quan = mean(year_grow))

   enhancement$Origen_pa <- paste0("Forest ", "Enhancement Chile"," intensity lvl ",enhancement$quantile)

   enhancement$Perturb <- "Enhancement"

Both of the enhancement shapefiles are put together and we select the
necessary columns for our use case. After 9 years the forest will return
to the "Bosque Inicial" (Initial forest) Origin and thus we will create
a copy of the enhancement shape and change the origin classifier to
Bosque Inicial. The enhancement stops one year after the FREL period
(2001-2013) and we put everything together and write the shapefile as
input for the tiler (GCBM).

.. code:: R

   enhancement_stop <- enhancement

   enhancement_stop$Origen_pa <- "Bosque Inicial"

   enhancement_stop$year <- year_t2+1

   enhancement <- rbind(enhancement,enhancement_stop)

   enhancement<-st_transform(enhancement, "+proj=longlat +datum=WGS84 +ellps=WGS84 +towgs84=0,0,0")

   enhancement$year<-as.integer(enhancement$year)

   write_sf(enhancement, paste0(output_gcbm, "/forest_enhancement_LosRios.shp"))

In a similar manner, we are going to modify the growth curves to reflect
the enhancements and create the growth curves including all the forest
enhancement curves. A loop that starts with the enhancement outside
conservation areas and then with the enhancement inside degradation
areas is initiated.

.. code:: R

   for (i in 1:(n_quantiles*2)) {
     if (i<= n_quantiles){
       enhancement_name <- paste0("Forest ", "Enhancement Chile"," intensity lvl ",i)
     } else {
       enhancement_name <- paste0("Forest ", "Conservation Enhancement Chile"," intensity lvl ",i-20)
     }

     growth_base <- filter(growth,Origen %in% c("Bosque Inicial"))
     growth_base$Origen <- enhancement_name
     if (i<= n_quantiles) {
       year_grow <- unname(means_quantile$mean_quan[i])
     } else {
       year_grow <- unname(means_quantile_c$mean_quan[i-n_quantiles])
     }
     year_grow_vol <- year_grow / (1.75 * 0.5 * 0.5 * (44/12))
     growth_curve <- seq(from= 0, by=year_grow_vol,length.out = ncol(growth_base)-4)
     growth_curve <- unname(rbind(growth_curve))
     growth_curve <- growth_curve[rep(seq_len(nrow(growth_curve)), nrow(growth_base)), ]
     growth_base[,5:ncol(growth_base)] <- growth_curve
     if (i==1){
       growth_full <- rbind(growth, growth_base)
     } else {
       growth_full <- rbind(growth_full,growth_base)
     }
   }

In a similar manner to create the growth curves for "No forestal"
(non-forest) regions, a loop is initiated that starts with the
enhancement outside conservation areas and then with the enhancement
inside degradation areas.

.. code:: R

   for (i in 1:(n_quantiles*2)) {
     if (i<= n_quantiles){
       enhancement_name <- paste0("Forest ", "Enhancement Chile"," intensity lvl ",i)
     } else {
       enhancement_name <- paste0("Forest ", "Conservation Enhancement Chile"," intensity lvl ",i-20)
     }

     growth_curve <- c("No forestal","No forestal",enhancement_name,"Not stocked",rep(as.numeric(0), ncol(growth_base)-4))
     growth_curve
     growth_full <- rbind(growth_full,growth_curve)
   }

Finally, we use the "non stocked" species so that the GCBM will ignore
the growth, and append the non-stocked growth curves to the dataframe.
The volume values are converted to numeric data and classifiers are
converted to text. We finally write the CSV with the growth curves
including the enhancement curves.
