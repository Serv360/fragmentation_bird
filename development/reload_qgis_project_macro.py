from qgis.core import QgsProject

project = QgsProject.instance()
path = project.fileName()
project.read(path)