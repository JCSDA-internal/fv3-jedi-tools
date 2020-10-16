# (C) Copyright 2019-2020 UCAR
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

import datetime as dt
import fv3jeditools

# --------------------------------------------------------------------------------------------------

# Datetime formats
dtformat_jedi = '%Y-%m-%dT%H:%M:%S'
dtformat_cylc = '%Y%m%dT%H%MZ'
dtformat_geos = '%Y%m%d_%H%M%S'
dtformat_da_h = '%Y%m%d_%H'

# --------------------------------------------------------------------------------------------------

def stringToDateTime(isodate_string):

    # Input an iso like datetime string and convert it to Python datetime object

    try:
        datetime = dt.datetime.strptime(isodate_string, dtformat_jedi)
    except ValueError:
        try:
            datetime = dt.datetime.strptime(isodate_string, dtformat_cylc)
        except ValueError:
            try:
                datetime = dt.datetime.strptime(isodate_string, dtformat_geos)
            except:
                try:
                    datetime = dt.datetime.strptime(isodate_string, dtformat_da_h)
                except:
                    fv3jeditools.utils.abort("stringToDateTime in utils_datetime could not convert")

    return datetime

# --------------------------------------------------------------------------------------------------

def parseDatetimeString(datetime, string_in):

    # Input datetime object and string containing %y %m etc and return with actual times

    return datetime.strftime(string_in)

# ------------------------------------------------------------------------------------------------
