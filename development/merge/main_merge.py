import pandas as pd
import numpy as np

#=====# Functions #=====#

def merge(bird_indicators, habitat_data, climate_data, fragmentation_data, agric_data, output_folder, version):
    """
    Join on (site, year).
    year in [2008, 2012, 2018]
    land cover first year is 2006.
    Done for a buffer of size 3km(?)
    Output format: (site, year, 
                    [abundance, sp_richness, shannon, simpson,]*5 (for each category and all birds together)
                    [frag_index1, frag_index2, ...], 
                    perc1, perc2, perc3, perc4, 
                    temperature, precipitation, radiation, 
                    ag_intensity)
    """
    final_data = pd.merge(fragmentation_data, bird_indicators, on=['site', 'year'], how='left')
    final_data = pd.merge(final_data, habitat_data, on=['site', 'year'], how='left')
    final_data = pd.merge(final_data, climate_data, on=['site', 'year'], how='left')
    if agric_data is None:
        print("No agriculture data.")
    else:
        final_data = pd.merge(final_data, agric_data, on=['site', 'year'], how='left')
    
    final_data.to_csv(output_folder + "/" + f"final_data_{version}.csv", index=False)

def load_data(bird_indic_path, habitat_folder, climate_path, 
              fragmentation_folder, agric_path, 
              years_clc, years_STOC, year_clc_to_STOC, buffer_size=3000):
    
    # Load bird indicators
    indicator_data_int = pd.read_csv(bird_indic_path)
    # Assuming df is your DataFrame
    indicator_data = indicator_data_int.pivot_table(
    index=['site', 'annee'],
    columns='habitat_category',
    values=['Total_Abundance', 'Species_Richness', 'Shannon_Diversity', 'Simpson_Diversity']
    )
    # Flatten the MultiIndex in columns
    indicator_data.columns = [f'{var}_{habitat}' for var, habitat in indicator_data.columns]
    # Reset index if needed
    indicator_data.reset_index(inplace=True)
    indicator_data.rename(columns={'annee': 'year'}, inplace=True)
    
    # Load fragmentation
    fragmentations_list = []
    for year_STOC in years_STOC:
        fragmentation_year = pd.read_csv(fragmentation_folder + "/" + f"results_all_three_{year_STOC}.csv")
        fragmentation_year["year"] = year_STOC
        fragmentations_list.append(fragmentation_year)
    fragmentation_data = pd.concat(fragmentations_list, ignore_index=True)

    # Load habitat
    habitats_list = []
    for year_clc in years_clc:
        habitat_year = pd.read_csv(habitat_folder + "/" + f"habitat_control_{year_clc}_{buffer_size}.csv")
        habitat_year["year"] = year_clc_to_STOC[year_clc]
        habitats_list.append(habitat_year)
    habitat_data = pd.concat(habitats_list, ignore_index=True)

    # Load climate variables
    climate_data = pd.read_csv(climate_path)

    # Load agric intensity
    if agric_path is None:
        agric_data = None
    else:
        agric_data = pd.read_csv(agric_path)

    return indicator_data, habitat_data, climate_data, fragmentation_data, agric_data

def build_difference_dataset(final_data_folder, output_folder, version):
    final_data = pd.read_csv(final_data_folder + f"/final_data_{version}.csv")

    # Step 1: Do a self-merge on site
    merged = final_data.merge(final_data, on='site', suffixes=('_j', '_i'))

    # Step 2: Filter only where year_j > year_i
    merged = merged[merged['year_j'] > merged['year_i']]

    # Step 3: Compute differences
    for col in final_data.columns:
        if col not in ["site", "year"]:
            merged[f'diff_{col}'] = merged[f'{col}_j'] - merged[f'{col}_i']

    difference_data = merged[['site', 'year_j', 'year_i'] + [f"diff_{col}" for col in final_data.columns if col not in ["site", "year"]]].copy()

    difference_data["year_diff"] = difference_data["year_j"].astype(str) + "-" + difference_data["year_i"].astype(str)

    difference_data.to_csv(output_folder + "/" + f"difference_data_{version}.csv", index=False)

#=====# Global variables #=====#

# MERGE THE DATASETS
bird_indic_path = "C:/Users/Serv3/Desktop/Cambridge/Course/3 Easter/Dissertation EP/data/biodiversity/div_indicators/indicators.csv"
habitat_folder = "C:/Users/Serv3/Desktop/Cambridge/Course/3 Easter/Dissertation EP/data/control_variables/habitat"
climate_path = "C:/Users/Serv3/Desktop/Cambridge/Course/3 Easter/Dissertation EP/data/control_variables/climate/climate_controls.csv"
fragmentation_folder = "C:/Users/Serv3/Desktop/Cambridge/Course/3 Easter/Dissertation EP/data/fragmentation/results"
agric_path = None
output_folder = "C:/Users/Serv3/Desktop/Cambridge/Course/3 Easter/Dissertation EP/data/merged_data"
years_STOC = [2008, 2012, 2018]
years_clc = [2006, 2012, 2018]
year_clc_to_STOC = {2006:2008, 2012:2012, 2018:2018}
version = "all_three"

indicator_data, habitat_data, climate_data, fragmentation_data, agric_data = load_data(
    bird_indic_path, habitat_folder, climate_path, fragmentation_folder, agric_path, years_clc, years_STOC, year_clc_to_STOC
)
merge(indicator_data, habitat_data, climate_data, fragmentation_data, agric_data, output_folder, version)


# CONSTRUCT THE DIFFERENCE DATASET
version = "all_three"
final_data_folder = f"C:/Users/Serv3/Desktop/Cambridge/Course/3 Easter/Dissertation EP/data/merged_data"
output_folder = "C:/Users/Serv3/Desktop/Cambridge/Course/3 Easter/Dissertation EP/data/merged_data"
build_difference_dataset(final_data_folder, output_folder, version)