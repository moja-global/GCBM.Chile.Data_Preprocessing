Forest Degradation Layer
========================

The Forest Degradation layer code creates the degradation layers and
disturbance matrix values, including the conservation areas. The
parameters ``input_pf`` and ``output_gcbm`` define the folders where the
permanent forest files are and the folder of the output data for the
model.

The other parameters include the permanent forest layer in the FREL for
two years, 2001 and 2010, defined as ``year_t1`` and ``year_t2``. The
number of quantiles to represent the degradation is defined as
``n_quantiles``.

We read the permanent forest shapefile and the codes that indicate
degradation are 2,3,4 and 10000, 10001 in the "Carta". Do note that the
change in CO2 (CAM_CO2) has to be negative.

.. code:: R

   pf <- st_read(dsn = input_pf, layer = layer_pf)

   degradation <- dplyr::filter(
     pf,
     Carta %in% c("2", "3", "4", "10000", "10001"),
     CAM_CO2 < 0)

A random year is defined for the degradation between 2002 and 2010 and
the regional average of CO2 is calculated. The percentage of the
regional CO2 that is lost in each degradation pixel is also calculated
and the shapefile is divided into two parts: degradation that occurs in
conservation areas and degradation that occurs outside of conservation
areas.

.. code:: R

   degradation$year<-sample((year_t1+1):year_t2,nrow(degradation),replace=TRUE)
   degradation$year

   regional_CO2 <- (375.2900742 * 1.75 * 0.5)  * 0.5 * (44/12)

   degradation$p_regional <- (degradation$CAM_CO2 / regional_CO2) * (-1)

   degradation_c <- dplyr::filter(degradation,ca_ras_erp>0)

   degradation <- dplyr::filter(degradation,ca_ras_erp==0)

The quantiles are further calculated and the mean of each quantile is
calculated. The name of the disturbance according to the quantile
(intensity level) is also fetched.

.. code:: R

   degradation$quantile <- cut(degradation$p_regional , breaks = quantile(degradation$p_regional, seq(0,1,length.out = n_quantiles+1)),labels=1:n_quantiles, include.lowest=TRUE)

   means_quantile <- group_by(as.data.frame(degradation), quantile) %>% summarize(mean_quan = mean(p_regional))

   degradation$Perturb <- paste0("Forest ", "Degradation Chile"," intensity lvl ",degradation$quantile)

The same operation is performed with the degradation in conservation
areas. Both of the degradations are joined in a single shape, and a
shapefile is written which will be used as input for the tiler (GCBM).

.. code:: R

   degradation <- rbind(degradation,degradation_c)

   degradation<-degradation[,c("year","Perturb")]

   degradation<-st_transform(degradation, "+proj=longlat +datum=WGS84 +ellps=WGS84 +towgs84=0,0,0")

   degradation$year<-as.integer(degradation$year)

We then use the information of each quantile to make the disturbance
matrices to insert them into the ``gcbm_input`` database. For the same,
we create the disturbance type CSV and start the id counting from 9003
(9001 and 9002 are deforestation and substitution).

In a for loop, we will calculate the disturbance in each iteration, with
the first degradation outside conservation and then inside conservation
areas.

.. code:: R

   for (i in 1:(n_quantiles*2)) {
     if (i==n_quantiles+1){
       lvl <- 1
     }
     if (i<= n_quantiles){
       name <- paste0("Forest Degradation Chile intensity lvl ",lvl)
     } else {
       name <- paste0("Forest Conservation Degradation Chile intensity lvl ",lvl)
     }
     code <- id
     disturbance_type <- cbind(id,disturbance_category_id,transition_land_class_id,name,code)
     if (i==1){
       disturbance_types_full <- disturbance_type
     } else {
       disturbance_types_full <- rbind(disturbance_types_full,disturbance_type)
     }
     id <- id + 1
     lvl <- lvl + 1
   }

The same process is repeated for the disturbance matrix CSV where the
data frame just assigns an id and name to the disturbance matrix. It
starts from 903 (901 and 902 are deforestation and substitution) and the
first degradation is calculated outside conservation and then inside
conservation areas.

Finally, the CSV is inputted into the ``gcbm_input`` database and the
disturbance matrix association CSV is created. The disturbance matrix
corresponds to spatial unit 36 (British Columbia and Pacific maritime).
The disturbance type ID starts from 9003 while the disturbance matrix ID
starts from 903. Similar to prior methods, the first degradation is
calculated outside conservation and then inside conservation areas.

.. code:: R

   for (i in 1:(n_quantiles*2)) {
     disturbance_matrix_association <- cbind(spatial_unit_id,disturbance_type_id,disturbance_matrix_id)
     if (i==1){
       disturbance_matrix_association_full <- disturbance_matrix_association
     } else {
       disturbance_matrix_association_full <- rbind(disturbance_matrix_association_full,disturbance_matrix_association)
     }
     disturbance_type_id <- disturbance_type_id + 1
     disturbance_matrix_id <- disturbance_matrix_id + 1
   }

In a similar manner, we calculate the disturbance matrix values CSV
where the dataframe includes the proportion of each reservoir that goes
to CO2.

.. code:: R

   for (i in 1:(n_quantiles*2)) {
     disturbance_matrix_id <- rep(dist_id,6)
     source_pool_id <- c(1,2,3,6,7,8)
     sink_pool_id <- rep(22,6)
     if (i<= n_quantiles){
       proportion <- rep(means_quantile$mean_quan[i],6)
     } else {
       proportion <- rep(means_quantile_c$mean_quan[i-n_quantiles],6)
     }

     disturbance_matrix <- cbind(disturbance_matrix_id,source_pool_id,sink_pool_id,proportion)

     if (i==1){
       disturbance_matrix_full <- disturbance_matrix
     } else {
       disturbance_matrix_full <- rbind(disturbance_matrix_full,disturbance_matrix)
     }
     dist_id <- dist_id + 1
   }

Finally, we write the CSV that is inserted into the ``gcbm_input``
database.
