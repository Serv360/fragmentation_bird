import os

# Define the target parent folder
base_folder = "C:/Users/Serv3/Desktop/Cambridge/Course/3 Easter/Dissertation EP/data/roads_rails/2018"  # Replace with your actual path

# List of all French départements (metropolitan + Corse A/B)
departements = (
    [str(i) for i in range(1, 96) if i != 20] +  # 1 to 95, skipping 20
    ['2A', '2B']  # Special Corsican codes
)

# Optional: format numbers with leading zeros (e.g. '01', '02', ..., '09')
departements = [d.zfill(2) if d.isdigit() else d for d in departements]

# Create each folder
for dept in departements:
    folder_path = os.path.join(base_folder, dept)
    os.makedirs(folder_path, exist_ok=True)

print("Folders created successfully.")