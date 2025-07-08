# The effects of natural habitat fragmentation on bird populations in mainland France.

(Add abstract)

This project was carried out as part of the Cambridge Master's programme in Environmental Policy. \\

Supervisor: S.V.

## How to run

Main path: the main path, at the top of each file, just after package imports, has to be changed. It points to where data should be stored.

### Package requirements

Python: package required are listed in the requirements_python.txt file. I used the python environment associated with QGIS 3.34.14 (3.12.8 (main, Dec 20 2024, 15:21:15) [MSC v.1938 64 bit (AMD64)]). To be able to use this environment with vscode, I followed the tutorial https://www.youtube.com/watch?v=qobogVuXtJU.

QGIS: the fragscape package is not compatible with QGIS versions 3.3X.XX and later. I therefore used version 3.28.9.

R: R version 4.3.2 (2023-10-31 ucrt) - Eye Holes (packages used are listed in the requirements_R.txt file)

### Data transformation

#### Data download

- BD TOPO: it has to be download by hand here - https://geoservices.ign.fr/bdtopo
- CORINE Land Cover: the function download_clc_year can be used from the main_fragmentation.py file.
- AgERA5 data: it has to be downloaded by hand here - https://cds.climate.copernicus.eu/datasets/sis-agrometeorological-indicators?tab=overview 
- STOC data: not available online. It was kindly provided by the Muséum National d'Histoire Naturel (MNHN)
- Altitude data: recovered from the RGE ALTI API of the National Institute of Geographic and Forest Information (IGN)

Here is the structure of the data folder.
- biodiversity
    - div_indicators
    - STOC
- control_variable
    - climate
    - habitat
- fragmentation
    - computation
    - results
- land_cover
    - corine_land_cover
        - 2008
        - 2012
        - 2018
        - merged
- merged_data
- results
- roads_rails
    - 2008
    - 2012
    - 2018
    - merged

#### Files to transform the data

To produce bird indices, the bird_indicators.R file in the bird_indicator folder should be use.

To produce connectivity metrics, one should run all the commented sections in the main_fragmentation.py file, down to *create layer with features all three*. Then by batch, one should use fragscape on QGIS 3.28.9. Finally, one should run the commented sections *recover fragmentation data* and *merge fragmentation data*.

To produce climate indicators, one should run the two R files in control_variables/climate.

To produce land cover percentages, one should run the python file in control_variables/habitat.

To merge all the dataset created in the relevant folders in the main data folder, one should use the main_merge.py file in the merge folder.

At the end, one obtains two dataset, final_data, which contains absolute values of each variable and difference_data, which contains differences of these variables for all couples of two years among 2008, 2012 and 2018. These datasets are stored in main_path/data/merged_data.

### Analysis

Analysis is carried out in R. To produce all figures and tables of the report, piece_wise_regression.R, analysis_level_diff.R and diff_in_diffs_subset.R are used. The other files were used for exploration. 