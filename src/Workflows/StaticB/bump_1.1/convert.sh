#!/bin/bash

####################################################################
# BACKGROUND #######################################################
####################################################################

# Create directories
mkdir -p ${work_dir}/convert_background

# BACKGROUND yaml
yaml_name="convert_background.yaml"
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
  npx: 385
  npy: 385
  npz: 127
  fieldsets:
  - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/dynamics.yaml
states:
- input:
    filetype: gfs
    datapath: ${data_dir_c384}/${bkg_dir}
    filename_cplr: coupler.res
    filename_core: fv_core.res.nc
    filename_trcr: fv_tracer.res.nc
    state variables: [ua,va,tv,ps,rh]
    psinfile: true
  output:
    filetype: geos
    datapath: ${data_dir_c384}/${bkg_dir}
    filename_bkgd: bkg.nc4
EOF

# BACKGROUND sbatch
sbatch_name="convert_background.sh"
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=convert_background
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --ntasks=216
#SBATCH --cpus-per-task=1
#SBATCH --time=00:10:00
#SBATCH -e ${work_dir}/convert_background/convert_background.err
#SBATCH -o ${work_dir}/convert_background/convert_background.out

source ${env_script}

cd ${work_dir}/convert_background
mpirun -n 216 ${bin_dir}/fv3jedi_convertstate.x ${yaml_dir}/${yaml_name}

exit 0
EOF
