#!/usr/bin/env python3.7

# (C) Copyright 2020 UCAR
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

import argparse
import datetime as dt

sargs = argparse.ArgumentParser()
sargs.add_argument("-s", "--date",  default='20200101')
sargs.add_argument("-p", "--config_in",  default='/path/config_in.yaml')
sargs.add_argument("-p", "--config_out", default='/path/config_out.yaml')

# --------------------------------------------------------------------------------------------------

args = sargs.parse_args()
date = args.date
config_in = args.config_in
config_out = args.config_out

datetime = dt.datetime.strptime(date, '%Y%m%d%H')

yyyy = datetime.strftime("%Y")
mm = datetime.strftime("%m")
dd = datetime.strftime("%d")
hh = datetime.strftime("%H")

# Read template and set datetime
conf_in = open(config_in).read()
conf_in = conf_in.replace('%Y', yyyy)
conf_in = conf_in.replace('%m', mm)
conf_in = conf_in.replace('%d', dd)
conf_in = conf_in.replace('%H', hh)

# Write the new conf file
conf_out = open(config_out, 'w')
conf_out.write(conf_in)
conf_out.close()
