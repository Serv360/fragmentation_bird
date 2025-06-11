import pandas as pd

def get_bird_points(file_path, year, all_years=False):
    df = pd.read_csv(file_path)
    if (not all_years):df = df[df["annee"]==year]
    df = df[['site', 'longitude', 'latitude']].drop_duplicates()
    return df