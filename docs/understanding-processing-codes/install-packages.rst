Install Packages
================

The Install Packages code installs all the necessary packages using the
``checkpoint`` package. The ``checkpoint`` package is used to secure
reproducibility and downloads the package version of that specific date.

.. code:: R

   if (!require(checkpoint)) install.packages("checkpoint")
   library("checkpoint")
   checkpoint("2019-10-01")

Here ``2019-10-01`` is the date of the compatibility packages.
