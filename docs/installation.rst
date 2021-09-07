Moja global Chile data pre-processing project setup
===================================================

The following section describes how to set up the project on your local
machine. The following are minimum requirements:

1. `R programming language`_
2. `R Studio`_
3. `Git`_

Setting up the project
----------------------

The following instructions describe how to install all the required
tools to do live data pre-processing on a Windows 10 system.

After installing, R Studio and R programming language, start the R
Studio IDE and follow these steps:

1. Click on ``File`` and select ``New Project``.

2. Click on ``Version Control`` to checkout a project from a version
   control repository.

3. Click on ``Git`` to clone the project from our GitHub repository.

4. Add the repository URL:
   ``https://github.com/moja-global/GCBM.Chile.Data_Preprocessing``.
   Select the subdirectory as per your needs and click on
   ``Create Project``.

5. After the repository is cloned and a workspace is initialized,
   download the Input data required for the data pre-processing. You can
   download it from the GitHub releases:

   1. Visit the GitHub releases on the GCBM Chile Data Preprocessing
      repository and check out the latest release.
   2. Scroll down to find the ``Input_Files.rar`` which contains the
      dataset used by the pre-processing algorithm.
   3. Click on ``Input_Files.rar`` and download it on your local
      machine. Extract the ``Input_Files`` directory on the root of the
      cloned GCBM Chile Data Preprocessing repository.
   4. **Optional**: You can download the ``Output_Files.rar`` as well
      for reproducibility and checking the results of the pre-processing
      algorithm.

6. Ensure the following directory structure for the project:

::

   ├── Input_Files
   │   ├── Growth                # Excel spreadsheet with growth data
   │   ├── LUC                   # Trazabilidad (Land use) data
   │   ├── SOC                   # Soil Organic carbon data
   |   └── Temperature           # Temperature raw data (NetCDF)
   ├── Output_Files
   │   ├── input_database
   │   └── layers
   │     └── raw
           ├── disturbances
   │       ├── environment
   |       └── inventory
   ├── Processing_codes
   ├── README.md
   ├── docs/
   ├── run_all.R
   └── ...

Running the project
-------------------

With the initial setup complete, you are now ready to run the
pre-processing algorithm code.

1. From the R Studio IDE, select the ``run_all.R`` file and click on
   ``Run`` to run all the pre-processing code.
2. Optionally, choose the individual files in the
   ``Preprocessing_Codes`` to run them singularly. Make sure to install
   the R packages as suggested by the R Studio.

With the repository and tools set up on your workstation, you can now
either edit existing code or prepare local datasets for a GCBM run using
R.

.. _R programming language: https://www.r-project.org/
.. _R Studio: https://www.rstudio.com/
.. _Git: http://www.git-scm.com/
