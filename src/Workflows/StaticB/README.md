# Static B training workflow

The static B training workflow is based on two directories:
- `bump_1.0` contains all the bash scripts to compute and test the static B, version 1.0. Their usage is detailed hereafter.
- `env_script` contains two scripts to load modules for GNU-OpenMPI and Intel-IMPI on Orion. They should be updated on other machines.

## BUMP 1.0

### Bash scripts
In `bump_1.0`, the driving bash script is `main.sh`. The upper section of this script should be updated to provide:
- Directories: for data, FV3-JEDI source and binaries, and experiments files.
- Environment script path: examples are provided in `env_script`.
- Parameters: variables, number of ensemble members, list of dates for the training, background and observation dates.
- What should be run: replace `false` with `true` to run a specific step.

Other bash scripts are called by `main.sh` to:
- create appropriate directories,
- generate `yaml` files,
- generate `sbatch` files to run jobs on Orion (should be updated on other machines and with other accounts).

### Tasks goal and dependencies
Tasks dependencies are given between brackets. Except for the first two tasks (`create directories` and `get data`), all dependencies are implemented in the bash scripts.
```
├── create directories: create all need directories, should be run only once
├── get data [create directories]: download data from S3
├── daily runs: BUMP pre-computations for each cycle
│   ├── daily vbal [get data]: vertical balance pre-computations for each cycle
│   ├── daily unbal [daily vbal]: unbalance ensemble members for each cycle
│   └── daily var-mom [daily unbal]: variance and moments pre-computations for each cycle
├── final runs: BUMP final tasks based on pre-computations
│   ├── final vbal [daily vbal]: final vertical balance computation
│   ├── final var [daily var-mom]: final variance computation
│   ├── final cor [daily var-mom]: final correlation length-scales computation
│   ├── final nicas [final cor]: NICAS operator computation
│   └── final psichitouv [get data]: psi/chi to u/v operator computation
├── merge runs: merge final runs results computed independently for each variable
│   ├── merge var-cor [final var, final cor]: merge variance and correlation length-scales files
│   └── merge nicas [final nicas]: merge NICAS files
├── spilt runs: split global BUMP files to use local files with a 7x7 layout
│   ├── split vbal [final vbal]: split global vertical balance file
│   ├── split nicas [merge nicas]: split global NICAS files
│   └── split psichitouv [final psichitouv]: split global psi/chi to u/v file
├── regrid runs: regrid files to use the static B at another resolution
│   ├── regrid background [get data]: regrid background
│   ├── regrid first member [get data]: regrid first ensemble member
│   ├── regrid psichitouv [final psichitouv, regrid first member]: regrid psi/chi to u/v file
│   ├── regrid var-cor [merge var-cor]: regrid variance and correlation length-scales fields
│   ├── regrid nicas [final nicas, regrid first member]: regrid NICAS files
│   └── regrid merge nicas [regrid nicas]: merge regridded NICAS files
├── dirac runs: Dirac test for each component
│   ├── dirac cor local [merge nicas]: Dirac test for local NICAS correlation operator
│   ├── dirac cor global [merge nicas]: Dirac test for global NICAS correlation operator
│   ├── dirac cov local [merge nicas, merge var-cor]: Dirac test for local NICAS correlation operator + standard-deviation
│   ├── dirac cov global [merge nicas, merge var-cor]: Dirac test for global NICAS correlation operator + standard-deviation
│   ├── dirac cov multi local [merge nicas, merge var-cor, final vbal]: Dirac test for local NICAS correlation operator + standard-deviation + vertical balance
│   ├── dirac cov multi global [merge nicas, merge var-cor, final vbal]: Dirac test for global NICAS correlation operator + standard-deviation + vertical balance
│   ├── dirac full c2a local [merge nicas, merge var-cor, final vbal]: Dirac test of the full local static B, using the FV3-JEDI-based psi/chi to u/v transform
│   ├── dirac full psichitouv local [merge nicas, merge var-cor, final vbal, final psichitouv]: Dirac test of the full local static B, using the BUMP-based psi/chi to u/v transform
│   ├── dirac full global [merge nicas, merge var-cor, final vbal]: Dirac test of the full static B, using the full global static B, using the BUMP-based psi/chi to u/v transform
│   ├── dirac full c192 local [regrid merge nicas, regrid var-cor, final vbal, regrid psichitouv, regrid background]: Dirac test of the full local static B at resolution C192, using the BUMP-based psi/chi to u/v transform
│   └── dirac full 7x7 local [split nicas, merge var-cor, split vbal, split psichitouv]: Dirac test of the full local static B with a 7x7 layout, using the BUMP-based psi/chi to u/v transform
└── variational runs: variational runs using the static B
    └── variational 3dvar [merge nica, merge varcor, final vbal, final psichitouv]: 3DVar using the static B
```
