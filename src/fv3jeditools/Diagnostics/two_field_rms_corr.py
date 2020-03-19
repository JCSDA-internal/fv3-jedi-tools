#!/usr/bin/env python3.7

# (C) Copyright 2019 UCAR
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

from netCDF4 import Dataset
import argparse
import matplotlib.pyplot as plt
import numpy as np
import matplotlib
matplotlib.use("Agg")


def main():

    # User input
    # ----------

    sargs = argparse.ArgumentParser()
    sargs.add_argument("-r", "--file_ref")
    sargs.add_argument("-f1", "--file1")
    sargs.add_argument("-f2", "--file2")
    sargs.add_argument("-f", "--field")

    args = sargs.parse_args()

    file_ref = args.file_ref
    file1 = args.file1
    file2 = args.file2
    fieldname = args.field

    # --------------------------------------------------------------------------------------------------

    fh_r = Dataset(file_ref)
    fh_1 = Dataset(file1)
    fh_2 = Dataset(file2)

    Xdim = len(fh_r.dimensions['Xdim'])
    Ydim = len(fh_r.dimensions['Ydim'])
    nf = len(fh_r.dimensions['nf'])
    lev = len(fh_r.dimensions['lev'])

    Xdim1 = len(fh_r.dimensions['Xdim'])
    Ydim1 = len(fh_r.dimensions['Ydim'])
    nf1 = len(fh_r.dimensions['nf'])
    lev1 = len(fh_r.dimensions['lev'])

    Xdim2 = len(fh_r.dimensions['Xdim'])
    Ydim2 = len(fh_r.dimensions['Ydim'])
    nf2 = len(fh_r.dimensions['nf'])
    lev2 = len(fh_r.dimensions['lev'])

    if (Xdim1-Xdim != 0 or Xdim2-Xdim != 0 or Ydim1-Ydim != 0 or Ydim2-Ydim != 0):
        print("Dimension mismatch between input files")
        exit()

    fieldr = np.zeros([lev, nf, Ydim, Xdim])
    field1 = np.zeros([lev, nf, Ydim, Xdim])
    field2 = np.zeros([lev, nf, Ydim, Xdim])

    print('Reading field: '+fieldname)
    fieldr[:, :, :] = fh_r.variables[fieldname][:, :, :, :]
    field1[:, :, :] = fh_1.variables[fieldname][:, :, :, :]
    field2[:, :, :] = fh_2.variables[fieldname][:, :, :, :]

    fieldrrs = np.reshape(fieldr, (lev, nf*Ydim*Xdim))
    field1rs = np.reshape(field1, (lev, nf*Ydim*Xdim))
    field2rs = np.reshape(field2, (lev, nf*Ydim*Xdim))

    rmse1 = np.zeros([lev])
    corr1 = np.zeros([lev])
    rmse2 = np.zeros([lev])
    corr2 = np.zeros([lev])

    # Compute RMS and Correlation
    for l in range(lev):

        print('Computing RMS and correlation at level ', +l)

        rmse1[l] = np.sqrt(np.mean((field1rs[l, :] - fieldrrs[l, :])**2))
        rmse2[l] = np.sqrt(np.mean((field2rs[l, :] - fieldrrs[l, :])**2))

        ccm = np.corrcoef(field1rs[l, :], fieldrrs[l, :])
        corr1[l] = ccm[0, 1]

        ccm = np.corrcoef(field2rs[l, :], fieldrrs[l, :])
        corr2[l] = ccm[0, 1]

    print('Create plots')

    fig, axs = plt.subplots(1, 2, figsize=(6, 8))
    axs[0].plot(rmse1, np.arange(1, lev+1))
    axs[1].plot(corr1, np.arange(1, lev+1))
    axs[0].plot(rmse2, np.arange(1, lev+1), 'r--')
    axs[1].plot(corr2, np.arange(1, lev+1), 'r--')

    axs[0].set_ylim(1, lev)
    axs[0].invert_yaxis()
    axs[0].set_title('RMSE')
    axs[1].set_ylim(1, lev)
    axs[1].invert_yaxis()
    axs[1].set_title('Correlation')
    axs[1].set_xlim(0.99, 1.0)

    fig.savefig("twofieldstats.png")


if __name__ == "__main__":
    main()
