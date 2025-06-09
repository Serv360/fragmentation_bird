import pandas as pd

def get_bird_points(file_path, year):
    df = pd.read_csv(file_path)
    df = df[df["annee"]==year]
    df = df[['site', 'longitude', 'latitude']].drop_duplicates()
    return df