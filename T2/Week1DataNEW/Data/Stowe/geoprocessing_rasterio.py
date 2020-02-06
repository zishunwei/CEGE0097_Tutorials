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

#import geopandas as gpd
import fiona
import rasterio
from rasterio import warp
from rasterio import features
import shapely
from shapely import ops as shapely_ops

import affine

folder = pathlib.Path.home() / "Dropbox" / "Documents" / "GeoCatalog" / "Stowe"
schools_shp = folder / "Schools" / "schools.shp"
elevation_tif = folder / "Elevation" / "elevation1.tif"
landuse_tif = folder/"Landuse"/"landuse1.tif"
landuse_out_tif = folder/"Landuse"/"landuse_out.tif"
recsites_shp = folder / "Recsites" / "rec_sites.shp"
roads_shp = folder / "Roads" / "roads.shp"

#schools_layer = gpd.read_file(schools_shp.as_posix())
schools_layer = fiona.open(schools_shp.as_posix())

elevation_layer = rasterio.open(elevation_tif.as_posix())
elevation_array = elevation_layer.read(1)*0.3048000097536

sy, sx = elevation_layer.shape
width = elevation_layer.res[0]
convert = elevation_layer.affine

def point_shp_to_array(shp_layer, convert, sx, sy):
    
    array = np.zeros((sy,sx), np.bool)
    
    for each in shp_layer:
        each_geom = each['geometry']
        point = each_geom['coordinates']
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
schools_dist = ndi.distance_transform_edt(~schools_array)*width
schools_classed = classify(schools_dist)


recsites_layer = fiona.open(recsites_shp.as_posix())

recsites_array = point_shp_to_array(recsites_layer, convert, sx, sy)
recsites_dist = ndi.distance_transform_edt(~recsites_array)*width
recsites_classed = classify(recsites_dist, True)

gradient_array = np.gradient(elevation_array/width)
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


landuse_layer = rasterio.open(landuse_tif.as_posix())

source = landuse_layer.read(1)
landuse_array = np.empty(elevation_layer.shape, dtype=np.uint8)
src_transform = landuse_layer.affine.to_gdal()
dst_transform = elevation_layer.affine.to_gdal()
src_crs = landuse_layer.crs
dest_crs = elevation_layer.crs

warp.reproject(source,landuse_array,src_transform=src_transform,src_crs=src_crs,dst_transform=dst_transform,dst_crs=dest_crs)

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
classed1 = classed1.copy()
classed_shp = folder/"classed.shp"

classed_features = features.shapes(classed1, transform=dst_transform)

roads_layer = fiona.open(roads_shp.as_posix())
road_geom = [shapely.geometry.shape(each['geometry']) for each in roads_layer]
roads_union = shapely_ops.cascaded_union(road_geom)

filtered = []
id_ = 0
for n,each in enumerate(classed_features):
    if each[1] != 255.0:
        continue
    geometry = shapely.geometry.shape(each[0])
    if not geometry.intersects(roads_union):
        continue
    if geometry.area  < 40469.0:
        continue
    record = {'id' : str(id_), 'geometry' : each[0], 'properties' : {}}
    filtered.append(record)


final_site_shp = folder/"final_site1.shp"

meta = schools_layer.meta
meta['schema']['geometry'] = "Polygon"
meta['schema']['properties'] = {}

with fiona.open(final_site_shp.as_posix(), "w", **meta) as final:
    for each_record in filtered:
        final.write(each_record)

print (time.time()-time_start)

if input("Press ']' to show image") =='[]':plt.show()



    






