# (C) Copyright 2019 UCAR
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

# --------------------------------------------------------------------------------------------------

__all__ = ['varcha_d2a_dict']

def varcha_d2a_dict(invars,outvars):

  varchadict = {
    "varchange": "D2AWinds",
    "doinverse": "0",
    "inputVariables": {
    "variables": invars,
    },
    "outputVariables": {
    "variables": outvars,
    },
  }

  return varchadict

# --------------------------------------------------------------------------------------------------
