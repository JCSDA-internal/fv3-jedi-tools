#! /usr/bin/env python

import os
import re
import sys
import time
import argparse

# Retrieve command-line arguments
# ===============================

parser = argparse.ArgumentParser(description='Locates gsi-diag files')
parser.add_argument('datetime', metavar='datetime', type=str,
                    help='ISO datetime as ccyy-mm-ddThh:mm:ss')
parser.add_argument('config', metavar='config', type=str,
                    help='configuration file (.yml)')
parser.add_argument('--tau', metavar='tau', type=int, required=False,
                    help='hours', default=0)

args = parser.parse_args()

dattim = re.sub('[^0-9]','', args.datetime+'000000')
idate  = int(dattim[0:8])
itime  = int(dattim[8:14])
tau    = args.tau

print("Executing " + sys.argv[0])
time.sleep(5)

sys.exit(0)
