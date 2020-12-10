# (C) Copyright 2020 UCAR
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

import cartopy.crs as ccrs
import matplotlib.pyplot as plt
import netCDF4
import numpy as np
import os

import fv3jeditools.utils as utils

# --------------------------------------------------------------------------------------------------
## @package field_plot
#
#  This application can be triggered by using "application name: field_plot"
#
#  Configuration options:
#  ----------------------
#
#  fields file | File containing field on lat/lon grid
#  field name  | Name of field to plot as it appears in the file
#  model layer | Model layer to plot if rank 3 field is chosen.
#
#  This function can be used to plot fields that are on a lon/lat grid as written by fv3-jedi.
#
#
# --------------------------------------------------------------------------------------------------

def field_plot(datetime, conf):

    # File containing field to plot
    try:
        fields_file = conf['fields file']
    except:
        utils.abort('\'fields file\' must be present in the configuration')

    # Replace datetime in logfile name
    isodatestr = datetime.strftime("%Y-%m-%dT%H:%M:%S")
    fields_file = utils.stringReplaceDatetimeTemplate(isodatestr, fields_file)

    # Get field to plot
    try:
        field_name = conf['field name']
    except:
        utils.abort('\'field name\' must be present in the configuration')

    # Get model layer to plot
    try:
        model_layer = conf['model layer']
    except:
        model_layer = None


    # Open the file
    print('\nOpening ', fields_file, 'for reading')
    ncfile = netCDF4.Dataset(fields_file, mode='r')

    # Get metadata from the file
    npx = ncfile.dimensions["lon"].size
    npy = ncfile.dimensions["lat"].size
    npz = ncfile.dimensions["lev"].size
    lons = ncfile.variables["lons"][:]
    lats = ncfile.variables["lats"][:]

    # Print field dimensions
    print(" Grid dimensions", npx, 'x', npy, 'x', npz)

    # Get field units from the file
    units = ncfile.variables[field_name].units

    # Zero out array to fill with field
    field = np.zeros((npy, npx))

    # Check if field is two or three dimensions
    if len(ncfile.variables[field_name].shape) == 4:

      # User must provide layer/level to plot if 3D
      if (model_layer == None):
          utils.abort("If plotting 3D variable user must provide \'model layer\' in the configuration")

      # Message and read the field at provided layer
      print(" Reading layer ", model_layer, " from field ", field_name)
      field[:,:] = ncfile.variables[field_name][:,model_layer-1,:,:]

      # Set plot title and output file to include level plotted
      title = "Contour of "+field_name+" ("+units+") for layer "+str(model_layer)
      outfile = os.path.splitext(fields_file)[0]+"_"+field_name+"_layer-"+str(model_layer)+".png"

    elif len(ncfile.variables[field_name].shape) == 3:

      # Message and read the field at provided layer
      print(" Reading field ", field_name)
      field[:,:] = ncfile.variables[field_name][:,:]
      title = "Contour of "+field_name+" ("+units+")"
      outfile = os.path.splitext(fields_file)[0]+"_"+field_name+".png"

    # Close the file
    ncfile.close()

    # Check if field has positve and negative values
    # ----------------------------------------------
    if np.min(field) < 0:
      cmax = np.max(np.abs(field))
      cmin = -cmax
      cmap = 'RdBu'
    else:
      cmax = np.max(field)
      cmin = np.min(field)
      cmap = 'nipy_spectral'

    levels = np.linspace(cmin,cmax,25)

    # Create two dimensional contour plot of field
    # --------------------------------------------

    # Set the projection
    projection = ccrs.PlateCarree()

    # Create figure to hold plot
    fig = plt.figure(figsize=(10, 5))

    # Just one subplot for now
    ax = fig.add_subplot(1, 1, 1, projection=projection)

    # Contour the field
    im = ax.contourf(lons, lats, field,
                     transform=projection,
                     cmap=cmap,
                     levels=levels)

    # Add coast lines to the plot
    ax.coastlines()

    # Add labels to the plot
    ax.set_xticks(np.linspace(-180, 180, 5), crs=projection)
    ax.set_yticks(np.linspace(-90, 90, 5), crs=projection)
    ax.set_xlabel('Longitude')
    ax.set_ylabel('Latitude')
    ax.set_title(title)
    ax.set_global()

    # Add a colorbar for the filled contour.
    fig.colorbar(im)

    # Show the figure
    print(" Saving figure as", outfile, "\n")
    plt.savefig(outfile)


# --------------------------------------------------------------------------------------------------
