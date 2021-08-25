#!/bin/bash

# Date
yyyymmddhh=$1

# Input file
input_file=${data_dir}/coupler/coupler.res

# Internal parameters
yyyy=${yyyymmddhh:0:4}
mm=${yyyymmddhh:4:2}
dd=${yyyymmddhh:6:2}
hh=${yyyymmddhh:8:2}
m=${mm##0}
d=${dd##0}
h=${hh##0}

for imem in $(seq 1 1 ${nmem}); do
   imemp=$(printf "%.3d" "${imem}")

   # Output file
   output_file=${data_dir_c384}/${yyyymmddhh}/mem${imemp}/bvars.coupler.res

   # Print
   echo `date`": - create coupler file ${output_file} for date ${yyyy}/${m}/${d}-${h}"

   # Create coupler file
   sed -e s/"_YYYY_"/${yyyy}/g ${input_file} > ${output_file}
   if test "${m}" -le "9" ; then
      sed -i -e s/"_M_"/" "${m}/g ${output_file}
   else
      sed -i -e s/"_M_"/${m}/g ${output_file}
   fi
   if test "${d}" -le "9" ; then
      sed -i -e s/"_D_"/" "${d}/g ${output_file}
   else
      sed -i -e s/"_D_"/${d}/g ${output_file}
   fi
   if test "${h}" -le "9" ; then
      sed -i -e s/"_H_"/" "${h}/g ${output_file}
   else
      sed -i -e s/"_H_"/${h}/g ${output_file}
   fi
done
