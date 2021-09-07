Welcome to GCBM Chile Data Preprocessing's documentation!
=========================================================

Moja global’s GCBM Chile data pre-processing project aims to host the
data pre-processing algorithms used by Chile to pre-process datasets to
be used by the Generic Carbon Budget Model (GCBM). The dataset has been
sourced from Forest Cadastre maps, and the National Forest Inventory,
with the Los Rios Region, in southern Chile, utilized as a proof of
concept for demonstrating the implementation of the model.

GCBM has been utilized as an open-source modelling framework that
implements the IPCC gain-loss method to estimate stocks and stock
changes. With the help of GCBM, the overall ecosystem carbon balance
from all sources and sinks at each annual time step is modelled. The
model then tracks carbon mass transfers in and out of the forest
ecosystem to ensure the carbon mass balance.

The preprocessing algorithms are designed to replicate the data
preparation conducted by Chile in the elaboration of its Forest
Reference Emissions Level / Forest Reference Level, `FREL/FRL`_,
submitted on August 31st, 2016. The results derived from the use of
these algorithms do not reflect the positions of the Government of Chile
for REDD+ accounting or any other purpose.

The methods and results of this work were compiled into the `technical
document`_ **"Modelling forest carbon dynamics for REDD+ using the
Generic Carbon Budget Model (GCBM)"**, where more details can be found.

.. _FREL/FRL: https://redd.unfccc.int/files/chile_mod_sub_final_01032017_english.pdf
.. _technical document: https://www.researchgate.net/publication/341041237_Modelling_forest_carbon_dynamics_for_REDD_using_the_Generic_Carbon_Budget_Model_GCBM_Pilot_Project_Los_Rios_Region_-_Chile


.. toctree::
   :maxdepth: 1
   :caption: Contents:

   installation
   understanding-processing-codes/index
