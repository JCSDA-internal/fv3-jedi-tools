# (C) Copyright 2019 UCAR
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

from ConvertEnsemble.modules.gfs import GFS
from ConvertEnsemble.modules.geos import GEOS


# Builder class for GFS
# ---------------------
class GFSBuilder:
  def __init__(self):
    self._instance = None

  def __call__(self):
    if not self._instance:
      self._instance = GFS()
    return self._instance


# Builder class for GEOS
# ----------------------
class GEOSBuilder:
  def __init__(self):
    self._instance = None

  def __call__(self):
    if not self._instance:
      self._instance = GEOS()
    return self._instance


# Generic factory
# ---------------
class ObjectFactory:
    def __init__(self):
        self._builders = {}

    def register_builder(self, key, builder):
        self._builders[key] = builder

    def create(self, key, **kwargs):
        builder = self._builders.get(key)
        if not builder:
            raise ValueError(key)
        return builder(**kwargs)


# Register the classes
# --------------------
factory = ObjectFactory()
factory.register_builder('GEOS', GEOSBuilder())
factory.register_builder('GFS', GFSBuilder())
