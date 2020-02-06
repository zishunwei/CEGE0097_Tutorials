#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#python2 not tested

import time
time_start = time.time()

import math
import pathlib
from pprint import pprint

import numpy as np
import matplotlib.pyplot as plt
import matplotlib.cm as cm 
import scipy.ndimage as ndi

from PIL import Image
from PIL import ImageFilter

import ogr
import gdal
import osr
import affine

folder = pathlib.Path.home() / "Dropbox" / "Documents" / "GeoCatalog" / "Stowe"
schools_shp = folder / "Schools" / "schools.shp"
elevation_tif = folder / "Elevation" / "elevation1.tif"
landuse_tif = folder/"Landuse"/"landuse1.tif"
landuse_out_tif = folder/"Landuse"/"landuse_out.tif"
recsites_shp = folder / "Recsites" / "rec_sites.shp"
roads_shp = folder / "Roads" / "roads.shp"


schools = ogr.Open(schools_shp.as_posix())
schools_layer = schools.GetLayer()

elevation_ds = gdal.Open(elevation_tif.as_posix())
sx = elevation_ds.RasterXSize
sy = elevation_ds.RasterYSize
elevation_band = elevation_ds.GetRasterBand(1)
elevation_array = elevation_band.ReadAsArray()*0.3048000097536

trans = elevation_ds.GetGeoTransform()
proj = elevation_ds.GetProjection()
convert = affine.Affine.from_gdal(*elevation_ds.GetGeoTransform())

def point_shp_to_array(shp_layer, convert, sx, sy):
    
    array = np.zeros((sy,sx), np.bool)
    
    for each in shp_layer:
        each_geom = each.geometry()
        point = each_geom.GetPoint()[:2]
        converted_point = ~convert * point
        rounded_point = round(converted_point[1]), round(converted_point[0])
        array[rounded_point] = 1

    return array

def classify(array, reverse = False):
    
    max_ = array.max()
    classes = np.array(range(11))*(max_/10)
    if reverse:
        classes = classes[::-1]
    classed = np.digitize(array, classes)
    
    return classed.astype(np.float)

schools_array = point_shp_to_array(schools_layer, convert, sx, sy)

schools_dist = ndi.distance_transform_edt(~schools_array)*trans[1]

schools_classed = classify(schools_dist)


recsites = ogr.Open(recsites_shp.as_posix())
recsites_layer = recsites.GetLayer()

recsites_array = point_shp_to_array(recsites_layer, convert, sx, sy)
recsites_dist = ndi.distance_transform_edt(~recsites_array)*trans[1]
recsites_classed = classify(recsites_dist, True)
    

gradient_array = np.gradient(elevation_array/30)
gradient_array = np.hypot(gradient_array[0], gradient_array[1])
gradient_array = np.arctan(gradient_array)*180/math.pi
gradient_array = np.clip(gradient_array,0,60)

gradient_array[0,:] = 0
gradient_array[1,:] = 0
gradient_array[-1,:] = 0
gradient_array[-2,:] = 0
gradient_array[:,0] = 0
gradient_array[:,1] = 0

gradient_classed = classify(gradient_array, True)

gradient_classed=gradient_classed.astype(np.float)
gradient_classed[gradient_classed ==1] = np.nan
gradient_classed[gradient_classed ==2] = np.nan
gradient_classed[gradient_classed ==3] = np.nan


landuse_ds = gdal.Open(landuse_tif.as_posix())

target_ds = gdal.GetDriverByName('GTiff').Create(landuse_out_tif.as_posix(), sx, sy, 1, gdal.GDT_Byte)
target_ds.SetGeoTransform(trans)
stat = gdal.ReprojectImage(landuse_ds, target_ds, None, None, 0)


landuse_array = target_ds.GetRasterBand(1).ReadAsArray()
landuse_classed = landuse_array.astype(np.float)



'''
1 Brush/Transitional  = 5
2 Water = Restricted
3 Barren Land = 10
4 Built Up = 3
5 Agriculture = 9
6 Forrest = 4
7 Wetlands = Restricted
'''

landuse_classed[landuse_classed ==1] = 5
landuse_classed[landuse_classed ==2] = np.nan
landuse_classed[landuse_classed ==3] = 10
landuse_classed[landuse_classed ==4] = 3
landuse_classed[landuse_classed ==5] = 9
landuse_classed[landuse_classed ==6] = 4
landuse_classed[landuse_classed ==7] = np.nan


classed = recsites_classed *0.5 +\
          schools_classed * 0.25 +\
          landuse_classed * 0.12 +\
          gradient_classed * 0.13

classed = np.nan_to_num(classed)
classed = np.round(classed)

classed = classed.astype(np.int)
max_ = classed.max()

classed[classed != max_] = 0
classed[classed == max_] = 1

classed = classed.astype(np.uint8)

im = Image.fromarray(255*classed, mode = 'L')

imf = ImageFilter.ModeFilter(3)
im1 = im.filter(imf)

classed1 = np.asarray(im1)
#plt.imshow(classed1)

def array2raster(newRasterfn,geotrans, proj, array):

    cols = array.shape[1]
    rows = array.shape[0]
    driver = gdal.GetDriverByName('GTiff')
    outRaster = driver.Create(newRasterfn, cols, rows, 1, gdal.GDT_Byte)
    outRaster.SetGeoTransform(geotrans)
    outband = outRaster.GetRasterBand(1)
    outband.WriteArray(array, 0, 0)

    outRaster.SetProjection(proj)
    outband.FlushCache()
    outRaster = None

    return outRaster

classed_tif = folder / "classed.tif"
classed_src = array2raster(classed_tif.as_posix(), trans, proj, classed1)
classed_src = None

new_src = gdal.Open(classed_tif.as_posix())
classed_band = new_src.GetRasterBand(1)
im2 = classed_band.ReadAsArray()

plt.imshow(im2)

classed_shp = folder/"classed.shp"

drv = ogr.GetDriverByName("ESRI Shapefile")
classed_ds = drv.CreateDataSource( classed_shp.as_posix() )
classed_layer_SRS = osr.SpatialReference()
classed_layer_SRS.ImportFromWkt(proj)
classed_layer = classed_ds.CreateLayer("classed", srs = classed_layer_SRS )

valueField = ogr.FieldDefn("value", ogr.OFTInteger)
classed_layer.CreateField(valueField)
ld = classed_layer.GetLayerDefn()
a = ld.GetFieldIndex('value')


gdal.Polygonize( classed_band, None, classed_layer, 0, [], callback=None )

classed_ds = None
classed_ds = ogr.Open(classed_shp.as_posix())
classed_layer = classed_ds.GetLayer("classed")

classed_layer.SetAttributeFilter("value = 255")

roads_ds = ogr.Open(roads_shp.as_posix())
roads_layer = roads_ds.GetLayer()
roads_union = ogr.Geometry(ogr.wkbMultiLineString)
for feat in roads_layer:
    roads_union.AddGeometry(feat.GetGeometryRef())
    


### Intersection

final_site_shp = folder/"final_site.shp"
driver = ogr.GetDriverByName('ESRI Shapefile')
final_site_ds = driver.CreateDataSource(final_site_shp.as_posix())
final_site_layer = final_site_ds.CreateLayer('final_site_layer', geom_type=ogr.wkbPolygon, srs = classed_layer_SRS)

for each_feature in classed_layer:
    each_geom = each_feature.GetGeometryRef()
    area  = each_geom.GetArea()
    if each_geom.Intersects(roads_union) and area >= 40469.0: 
        new_feature = ogr.Feature(final_site_layer.GetLayerDefn())
        new_feature.SetGeometry(each_geom)
        final_site_layer.CreateFeature(new_feature)
        new_feature.Destroy()
    each_feature.Destroy()

final_site_ds = None

print (time.time()-time_start)

if input("Press ']' to show image") =='[]':plt.show()
