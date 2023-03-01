#!/bin/bash

# Source functions
source ./functions.sh

# Create data directories
mkdir -p ${data_dir_def}/${bump_dir}/dirac_cor_local_${yyyymmddhh_first}-${yyyymmddhh_last}

####################################################################
# DIRAC_COR_LOCAL ##################################################
####################################################################

# Job name
job=dirac_cor_local_${yyyymmddhh_first}-${yyyymmddhh_last}

# DIRAC_COR_LOCAL yaml
cat<< EOF > ${yaml_dir}/${job}.yaml
geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gmao
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk${npz_def}.nc4
  npx: ${npx_def}
  npy: ${npy_def}
  npz: ${npz_def}
  layout: [${nlx_def},${nly_def}]
  field metadata override: ${fv3jedi_dir}/test/Data/fieldmetadata/geos_cf.yaml

initial condition:
  datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  filetype: cube sphere history
  provider: geos
  state variables: &active_vars [volume_mixing_ratio_of_co, volume_mixing_ratio_of_no2, volume_mixing_ratio_of_o3]
  #datapath: ${data_dir_def}/${bump_dir}/${first_member_dir}
  datapath: ${data_input_dir}/ens01/holding/geoscf_jedi
  filename: codas_c90_nudge.geoscf_jedi.${yyyy_last}${mm_last}${dd_last}_${hh_last}00z.nc4

background error:
  covariance model: ensemble
  localization:
    localization method: SABER
    saber central block:
      saber block name: BUMP_NICAS
      bump:
        io:
          #data directory: ${data_dir_def}/skylab-3.0.0-geos-cf-discover
          #files prefix: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
          ##overriding nicas file: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}${rr}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}${rr}_nicas

          files prefix: /work/noaa/da/barre/jedi-release/jedi-bundle/build/fv3-jedi/test/Data/bump/bumpparameters_nicas_geos_cf
          alias:
          - in code: volume_mixing_ratio_of_no2
            in file: fixed_25000km_0.3

        drivers:
          multivariate strategy: univariate
          read local nicas: true

  members from template:
    template:
      datetime: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
      filetype: cube sphere history
      provider: geos
      state variables: *active_vars
      datapath: ${data_input_dir}/ens%mem%/holding/geoscf_jedi
      filename: codas_c90_nudge.geoscf_jedi.${yyyy_last}${mm_last}${dd_last}_${hh_last}00z.nc4
    pattern: '%mem%'
    nmembers: 5
    zero padding: 2

output dirac:
  filetype: cube sphere history
  datapath: ${data_dir_def}/${bump_dir}/dirac_cor_local_${yyyymmddhh_first}-${yyyymmddhh_last}
  filename: dirac_%id%.nc

dirac:
  ndir: 3
  ixdir: [6,84,51] #Xdir
  iydir: [6,84,9] #Ydir
  ildir: [72,72,72] #level
  itdir: [1,2,2] #tile
  ifdir: [volume_mixing_ratio_of_no2, volume_mixing_ratio_of_no2, volume_mixing_ratio_of_no2]

EOF

# DIRAC_COR_LOCAL sbatch
ntasks=${ntasks_def}
cpus_per_task=1
threads=1
time=00:10:00
exe=fv3jedi_dirac.x
prepare_sbatch ${job} ${ntasks} ${cpus_per_task} ${threads} ${time} ${exe}
