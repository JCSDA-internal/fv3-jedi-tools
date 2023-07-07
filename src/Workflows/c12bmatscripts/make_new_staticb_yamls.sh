#!/bin/bash
#dates=("2020121421" "2020121500" "2020121503")
#dates="2020121421 2020121500 2020121503"
#dates="2022021418 2022021500 2022021506 2022021512"
#export num_mems=20
#dates=("$@")
bash make_new_staticb_ens_to_psichi_gfs.sh ${dates}
bash make_new_staticb_prep_gfs.sh ${dates}
bash make_new_staticb_vbal_gfs.sh ${dates}
bash make_new_staticb_var_gfs.sh ${dates}
bash make_new_staticb_cor_gfs.sh ${dates}
bash make_new_staticb_nicas_gfs.sh ${dates}
bash make_new_staticb_split_vbal_gfs.sh ${dates}
bash make_new_staticb_split_nicas_gfs.sh ${dates}
#mv *.yaml ${yaml_dir}
