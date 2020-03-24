#!/usr/bin/env python3.7

# (C) Copyright 2019 UCAR
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

from scipy.interpolate import UnivariateSpline
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


def main():

    #files = '/gpfsm/dnb31/drholdaw/NeilDemo/Data/hofx/abi_g17_obs_2019112818_NPROC.nc4'
    #files = '/gpfsm/dnb31/drholdaw/NeilDemo/Data/hofxams/satwind_uv_hofxana_2019112818_NPROC.nc4'
    files = '/discover/nobackup/drholdaw/JediScratch/RealTime4DVarGeos/Archive/2019111915/hofx/aircraft_hofx_2019111918_NPROC.nc4'

    variable = 'air_temperature'
    nprocs = 864

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
    omba1 = []
    omba2 = []
    omba3 = []

    for n in range(nprocs+1):
        # for n in range(3):

        file = files.replace('NPROC', str(n).zfill(4))
        print(" Reading "+file)

        fh = Dataset(file)

        omba1_proc = fh.variables[variable+'@ObsValue'][:] - \
            fh.variables[variable+'@hofx0'][:]
        omba2_proc = fh.variables[variable+'@ObsValue'][:] - \
            fh.variables[variable+'@hofx1'][:]
        omba3_proc = fh.variables[variable+'@ObsValue'][:] - \
            fh.variables[variable+'@hofx2'][:]

        for m in range(len(omba1_proc)):
            omba1.append(omba1_proc[m])
            omba2.append(omba2_proc[m])
            omba3.append(omba3_proc[m])

        fh.close()

    p1, x1 = np.histogram(omba1, bins=50)
    p2, x2 = np.histogram(omba2, bins=50)
    p3, x3 = np.histogram(omba3, bins=50)

    x1 = x1[:-1] + (x1[1] - x1[0])/2
    x2 = x2[:-1] + (x2[1] - x2[0])/2
    x3 = x3[:-1] + (x3[1] - x3[0])/2
    f1 = UnivariateSpline(x1, p1, s=n)
    f2 = UnivariateSpline(x2, p2, s=n)
    f3 = UnivariateSpline(x3, p3, s=n)

    plt1 = plt.plot(x1, f1(x1), 'r')
    plt2 = plt.plot(x2, f2(x2), 'b')
    plt3 = plt.plot(x3, f3(x3), 'g')

    plt.title('Innovation statistics')
    plt.ylabel('Probability')
    plt.xlabel('Observation minus H(x)')

    plt.legend((plt1[0], plt2[0], plt3[0]),
               ('O-B', 'O-A (first)', 'O-A (second)'))

    plt.savefig('stats.png')

    exit()


if __name__ == "__main__":
    main()
