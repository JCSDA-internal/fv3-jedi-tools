#!/bin/bash

dates="2022021418 2022021500 2022021506 2022021512 2022021518 2022021600 2022021606 2022021612 2022021618 2022021700 2022021706 2022021712 2022021718 2022021800 2022021806 2022021812 2022021818"
export num_mems=20
datesconverted=("20220215T000000Z" "20220215T060000Z" "20220215T120000Z" "20220215T180000Z" "20220216T000000Z" "20220216T060000Z" "20220216T120000Z" "20220216T180000Z" "20220217T000000Z" "20220217T060000Z" "20220217T120000Z" "20220217T180000Z" "20220218T000000Z" "20220218T060000Z" "20220218T120000Z" "20220218T180000Z" "20220219T000000Z")
export conv_data_dir=/work/noaa/da/cgas/JEDI/jedi-bundle/ewok/tmp/ewok/3fbcd8

#tasks to do
export make_dirs=1
export get_data=0
export make_yamls=1
export make_sbatch=1


# set up directories and environoment
if test ${make_dirs} -eq 1; then
export Data_dir=/work/noaa/da/csampson/c12staticb
export executable_dir=/work/noaa/da/csampson/qgewoktesting/build/bin
export yaml_dir=/work/noaa/da/csampson/qgewoktesting/build/fv3-jedi/test/testinput
export environment_dir=~/environments
export environment=spack-env-gnu.sh
export log_dir=${Data_dir}/logs
export run_dir=/work/noaa/da/csampson/qgewoktesting/build/fv3-jedi/test/ #for current yamls needs to be test folder for needed sym links

mkdir -p ${Data_dir}
mkdir -p ${Data_dir}/logs
mkdir -p ${Data_dir}/newstaticb
export staticb_dir= ${Data_dir}/newstaticb
mkdir -p ${Data_dir}/newstaticb/ensemble
export ensemble_dir=${Data_dir}/newstaticb/ensemble
mkdir -p ${Data_dir}/newstaticb/unbalanced
export unbalanced_dir=${Data_dir}/newstaticb/unbalanced
mkdir -p ${Data_dir}/newstaticb/balanced
export balanced_dir=${Data_dir}/newstaticb/balanced
mkdir -p ${Data_dir}/newensembleb
export ensembleb_dir=${Data_dir}/newensembleb
for i in $( seq 0 $(( num_mems-1 )) ); do
member=mem$(printf "%03d\t" "$i")
mkdir -p ${Data_dir}/newstaticb/unbalanced/${member}
mkdir -p ${Data_dir}/newstaticb/balanced/${member}
mkdir -p ${Data_dir}/newstaticb/ensemble/${member}
done
fi

if test ${make_yamls} -eq 1; then
###make needed yamls
bash make_new_staticb_ens_to_psichi_gfs.sh ${dates}
bash make_new_staticb_prep_gfs.sh ${dates}
bash make_new_staticb_vbal_gfs.sh ${dates}
bash make_new_staticb_var_gfs.sh ${dates}
bash make_new_staticb_cor_gfs.sh ${dates}
bash make_new_staticb_nicas_gfs.sh ${dates}
bash make_new_staticb_split_vbal_gfs.sh ${dates}
bash make_new_staticb_split_nicas_gfs.sh ${dates}
#make needed for ensemble b
bash make_new_ensembleb_prep_gfs.sh ${dates}
bash make_new_ensembleb_loc_gfs.sh ${dates}
bash make_new_ensembleb_nicas_gfs.sh ${dates}
bash make_new_ensembleb_split_nicas_gfs.sh ${dates}
mv *.yaml "${yaml_dir}"
fi

if test ${make_sbatch} = 1; then
rm submit_* 
##make convert state sbatch
for date in ${dates}; do
export yaml=new_staticb_ens_to_psichi_${date}_gfs.yaml
export executable=fv3jedi_convertstate.x
bash make_new_staticb_sbatch.sh
cat << EOF >> submit_new_staticb_ens_to_psichi.sh
sbatch sbatch_${yaml/.yaml/}.sh
EOF
done


##make staticb ensemble prep sbatch
for date in ${dates}; do
export yaml=new_staticb_prep_${date}_gfs.yaml
export executable=fv3jedi_error_covariance_training.x
bash make_new_staticb_sbatch.sh
cat << EOF >> "submit_new_staticb_prep.sh"
sbatch sbatch_${yaml/.yaml/}.sh
EOF
done

##make vbal sbatch
export yaml=new_staticb_vbal_gfs.yaml
export executable=fv3jedi_error_covariance_training.x
bash make_new_staticb_sbatch.sh

##make var sbatch
export yaml=new_staticb_var_gfs.yaml
export executable=fv3jedi_error_covariance_training.x
bash make_new_staticb_sbatch.sh

##make cor sbatch
export yaml=new_staticb_cor_gfs.yaml
export executable=fv3jedi_error_covariance_training.x
bash make_new_staticb_sbatch.sh

##make nicas sbatch
export yaml=new_staticb_nicas_gfs.yaml
export executable=fv3jedi_error_covariance_training.x
bash make_new_staticb_sbatch.sh

##make nicas split sbatch
export yaml=new_staticb_split_nicas_gfs.yaml
export executable=fv3jedi_error_covariance_training.x
bash make_new_staticb_sbatch.sh

##make var split sbatch
export yaml=new_staticb_split_vbal_gfs.yaml
export executable=fv3jedi_error_covariance_training.x
bash make_new_staticb_sbatch.sh

##make ensembleb prep sbatch
for date in ${dates}; do
export yaml=new_ensembleb_prep_${date}_gfs.yaml
export executable=fv3jedi_error_covariance_training.x
bash make_new_staticb_sbatch.sh
cat << EOF >> "submit_new_ensembleb_prep.sh"
sbatch sbatch_${yaml/.yaml/}.sh
EOF
done

##make ensembleb loc sbatch
export yaml=new_ensembleb_loc_gfs.yaml
export executable=fv3jedi_error_covariance_training.x
bash make_new_staticb_sbatch.sh

##make ensembleb nicas sbatch
export yaml=new_ensembleb_nicas_gfs.yaml
export executable=fv3jedi_error_covariance_training.x
bash make_new_staticb_sbatch.sh

##make loc sbatch
export yaml=new_ensembleb_split_nicas_gfs.yaml
export executable=fv3jedi_error_covariance_training.x
bash make_new_staticb_sbatch.sh

fi

#get data from raw dta directory set names for scripts
if test ${get_data} -eq 1; then

for i in $( seq 0 $(( num_mems - 1 )) ); do
member=mem$(printf "%03d\t" "$i")
memberclem=member$i
for date in "${datesconverted[@]}"; do
echo ${conv_data_dir}/${date}/ensemble/${memberclem}___to__${Data_dir}/newstaticb/ensemble/${member}
cp -r ${conv_data_dir}/${date}/ensemble/${memberclem}/* ${Data_dir}/newstaticb/ensemble/${member}
done
done 


##convert file names
for i in $( seq 0 $(( num_mems - 1 )) ); do
member=mem$(printf "%03d\t" "$i")

## loop over the files in the folder
cd ${Data_dir}/newstaticb/ensemble/${member}/
for file in *PT6H*; do
    # get the file name   
    filename=$file
    echo $filename
    # remove the unwanted parts from the file name using parameter expansion  (This is faily specific and likely needs to be edited. )
    newname="${filename/3fbcd8.c12.fc./}"
    newname="${newname/.PT6H/}"
    newname="${newname/Z/}"
    newname="${newname//T/.}"
    echo $newname
    # rename the file
    mv ${file} ${newname}
done
done
fi



 
