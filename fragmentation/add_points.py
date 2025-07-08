import pandas as pd

from utils_fragscape import multiple_points_features
from download_clc import multiple_points_shape
from recover_frag_index import results_to_csv

from get_points import get_sites_to_keep


sites_to_keep_all_three_path = "C:/Users/Serv3/Desktop/Cambridge/Course/3 Easter/Dissertation EP/data/biodiversity/STOC/sites_to_keep_all_three.csv"
sites_to_keep_at = get_sites_to_keep(sites_to_keep_all_three_path)

sites_to_keep_two_out_of_three_path = "C:/Users/Serv3/Desktop/Cambridge/Course/3 Easter/Dissertation EP/data/biodiversity/STOC/sites_to_keep_two_out_of_three.csv"
sites_to_keep_toot = get_sites_to_keep(sites_to_keep_two_out_of_three_path)

#print(sites_to_keep_toot.groupby("site").count())

sites_with_two = sites_to_keep_toot[~sites_to_keep_toot["site"].isin(sites_to_keep_at["site"])]
#print(sites_with_two)

sites_count = sites_with_two[sites_with_two["annee"].isin([2008, 2018])].groupby("site").count()["annee"]
print(sites_count.value_counts())


site_ids_to_add = sites_count[sites_count == 2]

print(site_ids_to_add.count())