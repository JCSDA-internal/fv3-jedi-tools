#!/usr/bin/env python3.7

# (C) Copyright 2019 UCAR
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

import argparse
import matplotlib.pyplot as plt
import matplotlib
import numpy as np
import os

matplotlib.use("Agg")


def lines_that_contain(string, fh):
    return [line for line in fh if string in line]


def main():

    # User input
    # ----------

    sargs = argparse.ArgumentParser()
    sargs.add_argument("-p", "--plot_level", default='50')
    sargs.add_argument("-f", "--field",      default='psi')
    sargs.add_argument("-l", "--log_file",   default='femps_rmse.txt')

    args = sargs.parse_args()

    levelstr = args.plot_level
    field = args.field
    if field == 'psi':
        psi_or_chi = 0
    elif field == 'chi':
        psi_or_chi = 1
    else:
        print("ABORT: field should be psi or chi based on default fv3-jedi runs")
        exit()

    log_file = args.log_file

    print("\n FEMPS convergence analysis tool")
    print(" - Level to plot "+levelstr)
    print(" - Field to plot: "+field)
    print(" - File to read: "+log_file)
    print("\n")

    level = float(levelstr)-1

    # Search log for matching string

    convergence_all = []
    # Open and get lines that match
    with open(log_file, 'r') as fh:
        for line in lines_that_contain("INVERSELAP RMSE:", fh):
            convergence_all.append(line)

    nsize = len(convergence_all)

    ind_levl = 0
    ind_iter = 1
    ind_rmse = 2

    # Array of convergence data
    convergence = np.empty((nsize, 3))
    for n in range(nsize):
        for m in range(2, 5):
            convergence[n, m-2] = float(convergence_all[n].split()[m])

    niter = int(np.max(convergence[:, ind_iter]))

    convergence_levl = np.empty((2*niter, 3))
    convergence_levl[:, :] = convergence[np.where(
        convergence[:, ind_levl] == level), :]

    convergence_var = np.empty((niter, 3))
    convergence_var[:, :] = convergence_levl[psi_or_chi*niter:psi_or_chi*niter+niter, :]

    iter_array = np.empty((niter))
    iter_array[:] = convergence_var[:, ind_iter]

    rmse_array = np.empty((niter))
    rmse_array[:] = convergence_var[:, ind_rmse]

    figfile = 'fempsconv-'+os.path.splitext(os.path.split(log_file)[1])[0]+'-level'+levelstr.zfill(2)+'-'+field+'.png'

    plt.figure(figsize=(15, 7.5))
    plt.plot(iter_array, rmse_array, linestyle='-', marker='x')
    plt.title("Convergence for "+field)
    plt.xlabel("Iteration number")
    plt.ylabel("Root mean squared error")
    plt.xlim(0.9, niter)
    plt.yscale('log')

    print(" Saving figure as", figfile, "\n")
    plt.savefig(figfile, transparent=True)


if __name__ == "__main__":
    main()
