#!/bin/bash

####################################################################
# CONVERT_TO_C192 ##################################################
####################################################################

# Create specific work directory
mkdir -p ${work_dir}/convert_to_c192_${yyyymmddhh_last}

# CONVERT_TO_C192 yaml
yaml_name="convert_to_c192_${yyyymmddhh_last}.yaml"
cat<< EOF > ${yaml_dir}/${yaml_name}
input geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
  layout: [6,6]
  npx: 385
  npy: 385
  npz: 127
  fieldsets:
  - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/dynamics.yaml
output geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
  layout: [6,6]
  npx: 193
  npy: 193
  npz: 127
  fieldsets:
  - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/dynamics.yaml
states:
- input:
    filetype: gfs
    state variables: [ua,va,t,delp,ps,sphum,ice_wat,liq_wat,o3mr]
    datapath: ${data_dir_c384}/${bkg_dir}
    filename_core: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.fv_core.res.nc
    filename_trcr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.fv_tracer.res.nc
    filename_cplr: ${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.coupler.res
  output:
    filetype: gfs
    datapath: ${data_dir_c192}/${bkg_dir}
    filename_core: fv_core.res.nc
    filename_trcr: fv_tracer.res.nc
    filename_cplr: coupler.res
- input:
    filetype: gfs
    state variables: [psi,chi,t,delp,ps,sphum,ice_wat,liq_wat,o3mr]
    datapath: ${data_dir_c384}/${first_member_dir}
    filename_core: bvars.fv_core.res.nc
    filename_trcr: bvars.fv_tracer.res.nc
    filename_cplr: bvars.coupler.res
  output:
    filetype: gfs
    datapath: ${data_dir_c192}/${first_member_dir}
    filename_core: bvars.fv_core.res.nc
    filename_trcr: bvars.fv_tracer.res.nc
    filename_cplr: bvars.coupler.res
EOF

# CONVERT_TO_C192 sbatch
sbatch_name="convert_to_c192_${yyyymmddhh_last}.sh"
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=convert_to_c192_${yyyymmddhh_last}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --ntasks=216
#SBATCH --cpus-per-task=1
#SBATCH --time=00:10:00
#SBATCH -e ${work_dir}/convert_to_c192_${yyyymmddhh_last}/convert_to_c192_${yyyymmddhh_last}.err
#SBATCH -o ${work_dir}/convert_to_c192_${yyyymmddhh_last}/convert_to_c192_${yyyymmddhh_last}.out

source ${env_script}

cd ${work_dir}/convert_to_c192_${yyyymmddhh_last}
mpirun -n 216 ${bin_dir}/fv3jedi_convertstate.x ${yaml_dir}/${yaml_name}

for i in \$(seq 1 6); do
   mv ${data_dir_c192}/${first_member_dir}/${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.bvars.fv_core.res.tile\${i}.nc ${data_dir_c192}/${first_member_dir}/bvars.fv_core.res.tile\${i}.nc
   mv ${data_dir_c192}/${first_member_dir}/${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.bvars.fv_tracer.res.tile\${i}.nc ${data_dir_c192}/${first_member_dir}/bvars.fv_tracer.res.tile\${i}.nc
done
mv ${data_dir_c192}/${first_member_dir}/${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.bvars.coupler.res ${data_dir_c192}/${first_member_dir}/bvars.coupler.res

exit 0
EOF
