#!/usr/bin/env python3.7

# (C) Copyright 2019 UCAR
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import argparse
import re
import numpy as np

# User input
# ----------

sargs=argparse.ArgumentParser()
sargs.add_argument( "-l", "--log_file", default='jedi.log')
sargs.add_argument( "-j", "--jnorm", default='Jred') # Jred, J, Jb, Jo

args = sargs.parse_args()
log_file = args.log_file
jnorm2plot = args.jnorm

# --------------------------------------------------------------------------------------------------

pos = 6

if jnorm2plot=='Jred':
  search_pattern = 'Norm reduction= '
  pos = 7
  ylabel = 'Norm reduction'
  yscale = 'linear'
elif jnorm2plot=='J':
  search_pattern = 'Quadratic cost function: J '
  ylabel = 'Quadratic cost function J'
  yscale = 'log'
elif jnorm2plot=='Jb':
  search_pattern = 'Quadratic cost function: Jb '
  ylabel = 'Quadratic cost function Jb'
  yscale = 'linear'
elif jnorm2plot=='JoJc':
  search_pattern = 'Quadratic cost function: JoJc'
  ylabel = 'Quadratic cost function JoJc'
  yscale = 'linear'
  pos = 5
else:
  print("Invalid jnorm argument provided, J, Jb or JoJc")
  exit()


print(search_pattern)

jnorm = []

# Search through the file for matching string
file = open(log_file, "r")
for line in file:
  if re.search(search_pattern, line):
    if (line[0:5] != 'GMRES'):
      print(line)
      jnorm.append(line.split()[pos])


# Convert to numpy arrays
jnorma = np.asarray(jnorm, dtype=np.float32)
iter = np.arange(1,len(jnorma)+1)

print(jnorma)

plt.figure(figsize=(15,7.5))
plt.plot(iter,jnorma, linestyle='-', marker='x')
plt.title("Convergence")
plt.xlabel("Iteration number")
plt.ylabel(ylabel);
plt.yscale(yscale)
#plt.gca().invert_yaxis()

plt.savefig('jnorm.png')

exit()
