# (C) Copyright 2020 UCAR
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

import click
import fv3jeditools
from ruamel.yaml import YAML

# --------------------------------------------------------------------------------------------------
## @package fv3jeditools
#
#  This is the driver for stand-alone driving of all other applications in fv3jeditools
#
#  Positional arguments:
#   - Datetime in ISO format yyyy-mm-ddThh:MM:dd
#   - Configuration yaml file, e.g. application.yaml
#
# --------------------------------------------------------------------------------------------------

@click.command()
@click.argument('datetime')
@click.argument('config')
def main(datetime, config):

    # Configure the yaml object
    yaml = YAML(typ='safe')
    yaml.default_flow_style = False

    # Read the configuration yaml file
    with open(config) as full_conf:
        conf = yaml.load(full_conf)

    # Get configuration for the application
    try:
        app_conf = conf['application']
    except:
        fv3jeditools.utils.abort("In fv3-jedi-tool driver yaml must include application")

    # Get application name
    try:
        app_name = app_conf['application name']
    except:
        fv3jeditools.utils.abort("In fv3-jedi-tool driver yaml must include application name")

    # Remove application name key
    del app_conf['application name']

    # Print information
    print("\n")
    print("fv3jeditools: calling application "+app_name+" with the config: \n")
    print(app_conf)
    print("\n")

    # Execute the application
    getattr(fv3jeditools, app_name)(datetime, app_conf)

# --------------------------------------------------------------------------------------------------

if __name__ == '__main__':
    main()

# --------------------------------------------------------------------------------------------------
