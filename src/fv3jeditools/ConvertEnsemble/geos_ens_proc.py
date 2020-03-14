# (C) Copyright 2019 UCAR
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

__all__ = ['GEOS']

class GEOS:
  def __init__(self):
    self.myName = 'geos'

  def function1(self):
    print('function1', self.myName)

  def function2(self):
    print('function2', self.myName)
