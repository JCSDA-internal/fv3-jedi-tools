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

`<installationPrefix>/lib/python3.<version>/site-packages` should be in your `PYTHONPATH`.

## Usage

Once installed `<installationPrefix>/bin` will contain fv3jeditools.x. This executable is used for all applications contained within fv3-jedi-tools. This executable has a strict interface and is run with:

`fv3jeditools.x YYYY-mm-ddTHH:MM:SS application.yaml`

The first argument is an ISO date-time that might be used to parse datetimes in the application, the second argument is the application configuration yaml file. The configuration tells the program which application to run and contains required inputs for the application. Example configurations for the applications are included in the `src/Workflow` directory in the repository.

