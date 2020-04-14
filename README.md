[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

# Tools for fv3-jedi 

## Installation
`fv3-jedi-tools` uses `pip` for installation.
Valid python versions: python 3.5 - 3.8
```
$ git clone https://github.com/jcsda/fv3-jedi-tools
$ cd fv3-jedi-tools
$ pip install --prefix=<installationPrefix> -e .
```
`<installationPrefix>/bin` should be in your `PATH`.


## Contents
1. Workflow scripts
	- Retrieve GFS ensemble from archive and convert to stream function and velocity potential.
	- Get GSI diags from hpss and convert to ioda format

2. Diagnostics:
	- Plotting of Poisson solver convergence

3. Config file generation
