#!/usr/bin/env python3.7

# (C) Copyright 2019 UCAR
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

import matplotlib.ticker as mticker
import os
import datetime as dt
import cartopy.crs as ccrs
from netCDF4 import Dataset
import numpy as np
import re
import argparse
import matplotlib.pyplot as plt
import matplotlib
matplotlib.use("Agg")


#files = '/gpfsm/dnb31/drholdaw/NeilDemo/Data/hofx/abi_g17_obs_2019112818_NPROC.nc4'
#files = '/gpfsm/dnb31/drholdaw/NeilDemo/Data/hofxams/satwind_uv_hofxana_2019112818_NPROC.nc4'
files = '/gpfsm/dnb31/drholdaw/NeilDemo/Data/hofxams/amsua_n19_hofx_2019112818_NPROC.nc4'

variable = 'brightness_temperature_9@ObsValue'
nprocs = 1535

win_beg = dt.datetime.strptime('2019112815', '%Y%m%d%H')


# Variable name and units
# -----------------------
variable_name = variable.split('@')[0]
units = ''
if variable_name[0:22] == 'brightness_temperature':
    units = 'K'
elif variable_name == 'eastward_wind':
    units = 'ms-1'

# Filename
# --------
savename = os.path.basename(files)
savename = savename.replace('_NPROC', '')
savename = savename.replace('.nc4', '')
savename = savename + '-' + variable_name + '.png'

# Loop over files
# ---------------
hofx = []
lons = []
lats = []
time = []

for n in range(nprocs+1):

    file = files.replace('NPROC', str(n).zfill(4))
    print(" Reading "+file)

    fh = Dataset(file)

    hofx_proc = fh.variables[variable][:]
    lons_proc = fh.variables['longitude@MetaData'][:]
    lats_proc = fh.variables['latitude@MetaData'][:]
    time_proc = fh.variables['datetime@MetaData'][:]

    for m in range(len(hofx_proc)):
        hofx.append(hofx_proc[m])
        lons.append(lons_proc[m])
        lats.append(lats_proc[m])
        time_proc_ = (time_proc[m])
        time_proc_str = ''
        for l in range(20):
            time_proc_str = time_proc_str + time_proc_[l].decode('UTF-8')
        time.append((dt.datetime.strptime(time_proc_str,
                                          '%Y-%m-%dT%H:%M:%SZ') - win_beg).total_seconds())

    fh.close()

numobs = len(hofx)

obarray = np.empty([numobs, 4])

obarray[:, 0] = hofx
obarray[:, 1] = lons
obarray[:, 2] = lats
obarray[:, 3] = time


# Create figure
# -------------

fig = plt.figure(figsize=(10, 5))

# initialize the plot pointing to the projection
ax = plt.axes(projection=ccrs.PlateCarree(central_longitude=0))

# plot grid lines
gl = ax.gridlines(crs=ccrs.PlateCarree(central_longitude=0), draw_labels=True,
                  linewidth=1, color='gray', alpha=0.5, linestyle='-')
gl.xlabels_top = False
gl.ylabels_left = True
gl.xlabel_style = {'size': 10, 'color': 'black'}
gl.ylabel_style = {'size': 10, 'color': 'black'}
gl.xlocator = mticker.FixedLocator(
    [-180, -135, -90, -45, 0, 45, 90, 135, 179.9])
ax.set_ylabel("Latitude",  fontsize=7)
ax.set_xlabel("Longitude", fontsize=7)

# scatter data
sc = ax.scatter(obarray[:, 1], obarray[:, 2],
                c=obarray[:, 0], s=4, linewidth=0,
                transform=ccrs.PlateCarree(), cmap='viridis')

# colorbar
cbar = plt.colorbar(sc, ax=ax, orientation="horizontal",
                    pad=.1, fraction=0.06,)
cbar.ax.set_ylabel(units, fontsize=10)

# plot globally
ax.set_global()

# draw coastlines
ax.coastlines()

# figure labels
plt.title("Model simulated observation h(x): "+variable_name)
ax.text(0.45, -0.1,   'Longitude', transform=ax.transAxes, ha='left')
ax.text(-0.08, 0.4, 'Latitude', transform=ax.transAxes,
        rotation='vertical', va='bottom')

# show plot
plt.savefig(savename)

exit()
