
#=====# Functions #=====#

def merge(bird_data, bird_indicators, habitat_data, climate_data, fragmentation_data, agric_data, output_path):
    """
    Join on (site, year).
    year in [2008, 2012, 2018]
    land cover first year is 2006.
    Done for a buffer of size 3km(?)
    Output format: (site, year, 
                    [abundance, sp_richness, shannon, simpson,]*5 (for each category and all birds together)
                    frag, 
                    perc1, perc2, perc3, perc4, 
                    temperature, precipitation, radiation, 
                    ag_intensity)
    """
    pass

def load_data(bird_path, bird_indic_path, habitat_path, climate_path, fragmentation_path, agric_path):
    pass

#=====# Global variables #=====#

bird_path = ""
bird_indic_path = ""
habitat_path = ""
climate_path = ""
fragmentation_path = ""
agric_path = ""
output_path = ""

bird_data, bird_indicators, habitat_data, climate_data, fragmentation_data, agric_data = load_data(
    bird_path, bird_indic_path, habitat_path, climate_path, fragmentation_path, agric_path
)

merge(bird_data, bird_indicators, habitat_data, climate_data, fragmentation_data, agric_data, output_path)