#!/bin/csh -f

# DA allocation (advda queue)
# ---------------------------
#SBATCH -A g0613
#SBATCH --qos=advda

# JCSDA allocation
# ----------------
#### #SBATCH -A s2127

#SBATCH --export=NONE
#SBATCH --job-name=jedicycle
#SBATCH --output=jedicycle.o%j
##SBATCH --ntasks=$nprocs
#SBATCH --ntasks-per-node=24
#SBATCH --nodes=36
#SBATCH --constraint=hasw
#SBATCH --time=04:00:00

# Modules
source /usr/share/modules/init/csh
source $HOME/bin/jedi_modeles_intel17

# Environment variables
setenv date %YWBEG%mWBEG%dWBEG%HWBEG
setenv date_ %YWBEG%mWBEG%dWBEG_%HWBEG
setenv dateendnext_ %YWENT%mWENT%dWENT_%HWENT
setenv nprocs 864

setenv jedibin /discover/nobackup/drholdaw/JediDev/fv3-bundle-dev/build-intel-17.0.7.259-release-default/bin/
setenv geosbin /gpfsm/dhome/dao_ops/GEOSadas-5_22/GEOSadas/Linux/bin

setenv runhome /gpfsm/dnb31/drholdaw/JediScratch/RealTime4DVarGeos/
setenv jedirundir $runhome/JediRuns
setenv geosrundir $runhome/GeosRunDir

# Convert ensemble members to backgrounds
# ---------------------------------------
if ( ! -f Data/Ensemble/f522_dh.atmens_erst.${date_}z/mem032/geos.bkg.${date_}z.nc4) then
  mpirun -np $nprocs $jedibin/fv3jedi_convertstate.x Config/a1_convert_ensemble.yaml > Logs/${date}_a1_convert_ensemble.log
  mpirun -np $nprocs $jedibin/fv3jedi_convertstate.x Config/a2_convert_ensemble.yaml > Logs/${date}_a2_convert_ensemble.log
  mpirun -np $nprocs $jedibin/fv3jedi_convertstate.x Config/a3_convert_ensemble.yaml > Logs/${date}_a3_convert_ensemble.log
else
  echo "Convert ensemble already run"
endif

# Generate localization parameters
# --------------------------------
#if ( ! -f Data/Bump/${nprocs}_ens/bumpparameters_loc_diag.nc ) then
#  mkdir -p Data/Bump/${nprocs}_ens
#  mpirun -np $nprocs $jedibin/fv3jedi_parameters.x Config/b_parameters_loc_ens.yaml > Logs/${date}_b_parameters_loc_ens.log
#else
#  echo "Generate ensemble localization done"
#endif
if ( ! -f Data/Bump/${nprocs}_fix/bumpparameters_loc_cmat_common.nc ) then
  mkdir -p Data/Bump/${nprocs}_fix
  mpirun -np $nprocs $jedibin/fv3jedi_parameters.x Config/b_parameters_loc_fix.yaml > Logs/${date}_b_parameters_loc_fix.log
else
  echo "Generate static localization done"
endif

# Run Variational
if ( ! -f ${jedirundir}/Data/Analysis/geos.ana.${date_}0000z.nc4 ) then
  mpirun -np $nprocs $jedibin/fv3jedi_var.x Config/c_hyb-4dvar_geos.yaml > Logs/${date}_c_hyb-fgat_geos.log
else
  echo "Run variational done"
endif

# Check for success
# -----------------
if ( ! -f ${jedirundir}/Data/Analysis/geos.ana.${date_}0000z.nc4 ) then
  echo "No analysis file found, abort"
  exit()
endif

# Archive hofx
mkdir -p $runhome/Archive/$date/hofx
mv Data/hofx/* $runhome/Archive/$date/hofx/

# Convert low res background and analysis to restart variables
mpirun -np $nprocs $jedibin/fv3jedi_convertstate.x Config/d_convert_ana_and_bkg.yaml > Logs/${date}_d_convert_ana_and_bkg.log

# Create increment in restart space at model resolution
mpirun -np $nprocs $jedibin/fv3jedi_diffstates.x Config/e_analysis_to_increment.yaml > Logs/${date}_e_analysis_to_increment.log

# Add high res increment to model checkpoint
rm -r Data/RestartNew
mkdir -p Data/RestartNew
cp $geosrundir/fvcore_internal_checkpoint.${date_}00z.nc4 Data/RestartNew/fvcore_internal_checkpoint.${date_}00z.nc4
cp $geosrundir/moist_internal_checkpoint.${date_}00z.nc4 Data/RestartNew/moist_internal_checkpoint.${date_}00z.nc4

mpirun -np $nprocs $jedibin/fv3jedi_addincrement.x Config/f_add_increment.yaml > Logs/${date}_f_add_increment.log

# Check for success before running the model again
setenv logfile Logs/${date}_f_add_increment.log
setenv runstat `grep 'with status' ${logfile} | cut -d ' ' -f 7`
if ( $runstat == '0' ) then
  echo "Success for ${logfile}!"
else
  echo " ABORT: failure detected in "${logfile}
  exit 1
endif

# Run model again
# ---------------
cd $geosrundir

# Archive background restart
# --------------------------
echo "Archive background restart"
mkdir -p $runhome/Archive/$date/RestartBackground
cp catch_internal_checkpoint.${date_}00z.nc4 $runhome/Archive/$date/RestartBackground/catch_internal_rst
cp fvcore_internal_checkpoint.${date_}00z.nc4 $runhome/Archive/$date/RestartBackground/fvcore_internal_rst
cp gocart_import_checkpoint.${date_}00z.nc4 $runhome/Archive/$date/RestartBackground/gocart_import_rst
cp gocart_internal_checkpoint.${date_}00z.nc4 $runhome/Archive/$date/RestartBackground/gocart_internal_rst
cp irrad_internal_checkpoint.${date_}00z.nc4 $runhome/Archive/$date/RestartBackground/irrad_internal_rst
cp lake_internal_checkpoint.${date_}00z.nc4 $runhome/Archive/$date/RestartBackground/lake_internal_rst
cp landice_internal_checkpoint.${date_}00z.nc4 $runhome/Archive/$date/RestartBackground/landice_internal_rst
cp moist_import_checkpoint.${date_}00z.nc4 $runhome/Archive/$date/RestartBackground/moist_import_rst
cp moist_internal_rst.${date_}00z.nc4 $runhome/Archive/$date/RestartBackground/moist_internal_rst
cp openwater_internal_checkpoint.${date_}00z.nc4 $runhome/Archive/$date/RestartBackground/openwater_internal_rst
cp pchem_internal_checkpoint.${date_}00z.nc4 $runhome/Archive/$date/RestartBackground/pchem_internal_rst
cp saltwater_import_checkpoint.${date_}00z.nc4 $runhome/Archive/$date/RestartBackground/saltwater_import_rst
cp seaicethermo_internal_checkpoint.${date_}00z.nc4 $runhome/Archive/$date/RestartBackground/seaicethermo_internal_rst
cp solar_internal_checkpoint.${date_}00z.nc4 $runhome/Archive/$date/RestartBackground/solar_internal_rst
cp surf_import_checkpoint.${date_}00z.nc4 $runhome/Archive/$date/RestartBackground/surf_import_rst
cp tr_import_checkpoint.${date_}00z.nc4 $runhome/Archive/$date/RestartBackground/tr_import_rst
cp tr_internal_checkpoint.${date_}00z.nc4 $runhome/Archive/$date/RestartBackground/tr_internal_rst
cp turb_import_checkpoint.${date_}00z.nc4 $runhome/Archive/$date/RestartBackground/turb_import_rst
cp turb_internal_checkpoint.${date_}00z.nc4 $runhome/Archive/$date/RestartBackground/turb_internal_rst

# Move analysis to restart ready to run again with analysis
echo "Move analysis to restart"
mv ${jedirundir}/Data/RestartNew/fvcore_internal_checkpoint.${date_}00z.nc4 fvcore_internal_rst
mv ${jedirundir}/Data/RestartNew/moist_internal_checkpoint.${date_}00z.nc4 moist_internal_rst

# Move checkpoint to background
echo "Move checkpoint to background"
mv catch_internal_checkpoint.${date_}00z.nc4 catch_internal_rst
mv gocart_import_checkpoint.${date_}00z.nc4 gocart_import_rst
mv gocart_internal_checkpoint.${date_}00z.nc4 gocart_internal_rst
mv irrad_internal_checkpoint.${date_}00z.nc4 irrad_internal_rst
mv lake_internal_checkpoint.${date_}00z.nc4 lake_internal_rst
mv landice_internal_checkpoint.${date_}00z.nc4 landice_internal_rst
mv moist_import_checkpoint.${date_}00z.nc4 moist_import_rst
mv openwater_internal_checkpoint.${date_}00z.nc4 openwater_internal_rst
mv pchem_internal_checkpoint.${date_}00z.nc4 pchem_internal_rst
mv saltwater_import_checkpoint.${date_}00z.nc4 saltwater_import_rst
mv seaicethermo_internal_checkpoint.${date_}00z.nc4 seaicethermo_internal_rst
mv solar_internal_checkpoint.${date_}00z.nc4 solar_internal_rst
mv surf_import_checkpoint.${date_}00z.nc4 surf_import_rst
mv tr_import_checkpoint.${date_}00z.nc4 tr_import_rst
mv tr_internal_checkpoint.${date_}00z.nc4 tr_internal_rst
mv turb_import_checkpoint.${date_}00z.nc4 turb_import_rst
mv turb_internal_checkpoint.${date_}00z.nc4 turb_internal_rst

# Save backgrounds from previous runs
echo "Save backgrounds from background run"
mkdir -p $runhome/Archive/$date/Backgrounds
mv f522_dh.geos.bkg.* $runhome/Archive/$date/Backgrounds

# Convert analysis restart to analysis background
# -----------------------------------------------
echo "Convert analysis restart to background"
cd $jedirundir
mpirun -np $nprocs $jedibin/fv3jedi_convertstate.x Config/g_restart_to_background.yaml > Logs/${date}_g_restart_to_background.log
cd $geosrundir

# Forecast through next window
# ----------------------------
echo "Run the forecast"
source $geosbin/g5_modules
if ( ! -f ${geosrundir}/f522_dh.geos.bkg.${dateendnext_}00z.nc4 ) then
  mpiexec_mpt -np $nprocs $geosbin/GEOSgcm.x > ${jedirundir}/Logs/${date}_h_forecast.log
else
  echo "Run forecast done"
endif

# Check for success
# -----------------
if ( ! -f ${geosrundir}/f522_dh.geos.bkg.${dateendnext_}00z.nc4 ) then
  echo "Forecast step appears to have failed, abort"
  exit()
endif

# Analysis hofx
# -------------
echo "Run Analysis H(x) calculation"
cd $jedirundir
source $HOME/bin/jedi_modeles_intel17
mpirun -np $nprocs $jedibin/fv3jedi_hofx.x Config/h_hofx.yaml > $jedirundir/Logs/${date}_h_hofx.log
mv Data/hofx/* $runhome/Archive/$date/hofx/
cd $geosrundir

# Archive analysis background
# ---------------------------
echo "Archive analysis files"
mkdir -p $runhome/Archive/$date/Analysis
cp f522_dh.geos.bkg.* $runhome/Archive/$date/Analysis

# Archive analysis restart
# ------------------------
echo "Archive analysis restart"
mkdir -p $runhome/Archive/$date/RestartAnalysis
mv fvcore_internal_rst $runhome/Archive/$date/RestartAnalysis/fvcore_internal_rst
mv moist_internal_rst $runhome/Archive/$date/RestartAnalysis/moist_internal_rst
mv catch_internal_rst $runhome/Archive/$date/RestartAnalysis/catch_internal_rst
mv gocart_import_rst $runhome/Archive/$date/RestartAnalysis/gocart_import_rst
mv gocart_internal_rst $runhome/Archive/$date/RestartAnalysis/gocart_internal_rst
mv irrad_internal_rst $runhome/Archive/$date/RestartAnalysis/irrad_internal_rst
mv lake_internal_rst $runhome/Archive/$date/RestartAnalysis/lake_internal_rst
mv landice_internal_rst $runhome/Archive/$date/RestartAnalysis/landice_internal_rst
mv moist_import_rst $runhome/Archive/$date/RestartAnalysis/moist_import_rst
mv openwater_internal_rst $runhome/Archive/$date/RestartAnalysis/openwater_internal_rst
mv pchem_internal_rst $runhome/Archive/$date/RestartAnalysis/pchem_internal_rst
mv saltwater_import_rst $runhome/Archive/$date/RestartAnalysis/saltwater_import_rst
mv seaicethermo_internal_rst $runhome/Archive/$date/RestartAnalysis/seaicethermo_internal_rst
mv solar_internal_rst $runhome/Archive/$date/RestartAnalysis/solar_internal_rst
mv surf_import_rst $runhome/Archive/$date/RestartAnalysis/surf_import_rst
mv tr_import_rst $runhome/Archive/$date/RestartAnalysis/tr_import_rst
mv tr_internal_rst $runhome/Archive/$date/RestartAnalysis/tr_internal_rst
mv turb_import_rst $runhome/Archive/$date/RestartAnalysis/turb_import_rst
mv turb_internal_rst $runhome/Archive/$date/RestartAnalysis/turb_internal_rst
