#!/bin/bash

# Date
yyyymmddhh=$1
output_file=$2

# Internal parameters
yyyy=${yyyymmddhh:0:4}
mm=${yyyymmddhh:4:2}
dd=${yyyymmddhh:6:2}
hh=${yyyymmddhh:8:2}
m=${mm##0}
d=${dd##0}
h=${hh##0}

# Print
echo `date`": - create coupler file ${output_file} for date ${yyyy}/${m}/${d}-${h}"

# Create template file
cat<< EOF > ${output_file}
     0        (Calendar: no_calendar=0, thirty_day_months=1, julian=2, gregorian=3, noleap=4)
     0     0     0     0     0     0        Model start time:   year, month, day, hour, minute, second
  _YYYY_    _M_    _D_    _H_     0     0        Current model time: year, month, day, hour, minute, second
EOF

# Update the template file with input date
sed -i -e s/"_YYYY_"/${yyyy}/g ${output_file}
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
