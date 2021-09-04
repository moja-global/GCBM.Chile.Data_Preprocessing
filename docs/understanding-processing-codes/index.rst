Understanding preprocessing codes
=================================

The Preprocessing codes host all the preprocessing algorithms utilized
by the GCBM Chile Data Pre-Processing project. The code is hosted on the
`Preprocessing_Codes`_ sub-directory of the repository and allows
developers to concentrate on running individual simulations on the input
dataset and retrieve the necessary output. In this section, we would
delve deep into the individual code file and understand them.

Listing all Preprocessing Codes
-------------------------------

All the individual code files should be run using R Studio which
abstracts away complex configurations and package management. You can
primarily run ``run_all.R`` present on the repository root, to run all
the processing codes.

.. _Preprocessing_Codes: https://github.com/moja-global/GCBM.Chile.Data_Preprocessing/tree/master/Preprocessing_Codes

.. list-table::
   :header-rows: 1

   * - **Preprocessing Code Name**
     - **Description**
     - **Preprocessing Code Source**
   * - Install packages
     - Install the necessary packages using the checkpoint package.
     - `00-Install_packages.R <https://github.com/moja-global/GCBM.Chile.Data_Preprocessing/blob/master/Preprocessing_Codes/00-Install_packages.R>`_
   * - Temperature layer
     - Process the CR2 temperature product to obtain the mean temperature layer (1997-2016).
     - `01-Temperature_layer.R <https://github.com/moja-global/GCBM.Chile.Data_Preprocessing/blob/master/Preprocessing_Codes/01-Temperature_layer.R>`_
   * - Growth Curves
     - Build the Growth curves using the Annual Growth values for each forest type.
     - `02-Growth_curves.R <https://github.com/moja-global/GCBM.Chile.Data_Preprocessing/blob/master/Preprocessing_Codes/02-Growth_curves.R>`_
   * - Inventory layer
     - Create the inventory layer (initial layer).
     - `03-Inventory_layer.R <https://github.com/moja-global/GCBM.Chile.Data_Preprocessing/blob/master/Preprocessing_Codes/03-Inventory_layer.R>`_
   * - Afforestation layer
     - Create the afforestation layer: Land use changes from non-forest to forest.
     - `04-Afforestation_layer.R <https://github.com/moja-global/GCBM.Chile.Data_Preprocessing/blob/master/Preprocessing_Codes/04-Afforestation_layer.R>`_
   * - Forest loss layer
     - Create the deforestation and substitution layers.
     - `05-Forest_loss_layer.R <https://github.com/moja-global/GCBM.Chile.Data_Preprocessing/blob/master/Preprocessing_Codes/05-Forest_loss_layer.R>`_
   * - Forest degradation layer
     - Create the degradation layers and disturbance matrix values.
     - `06-Forest_degradation_layer.R <https://github.com/moja-global/GCBM.Chile.Data_Preprocessing/blob/master/Preprocessing_Codes/06-Forest_degradation_layer.R>`_
   * - Forest enhancement layer
     - Create the forest enhancement layers and add the new growth curves.
     - `07-Forest_enhancement_layer.R <https://github.com/moja-global/GCBM.Chile.Data_Preprocessing/blob/master/Preprocessing_Codes/07-Forest_enhancement_layer.R>`_

Official Preprocessing Codes
----------------------------

The Preprocessing Code files describe the packages needed, folder paths,
parameters, layers and the core algorithm organized in a separate single
unit. You can run each of the Preprocessing codes individually, provided
the folder paths are configured correctly as described in the
installation.


.. toctree::
   :maxdepth: 1
   :caption: Contents:

   install-packages
   temperature-layer
   growth-curves
   inventory-layer
   afforestation-layer
   forest-loss
   forest-degradation-layer
   forest-enhancement-layer
