from qgis.core import QgsProject, QgsVectorLayer, QgsApplication
QGIS_PREFIX_PATH = "C:/Program Files/QGIS 3.34.14"

QgsApplication.setPrefixPath(QGIS_PREFIX_PATH, True)
qgs = QgsApplication([], False)
qgs.initQgis()

project = QgsProject.instance()
project.read("C:/Users/Serv3/Desktop/Cambridge/Course/3 Easter/Dissertation EP/code/fragmentation_bird/development/qgis/fragmentation.qgz")

print("Project file path:", project.fileName())

qgs.exitQgis()