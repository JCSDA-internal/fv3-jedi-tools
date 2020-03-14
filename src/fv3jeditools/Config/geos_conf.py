# (C) Copyright 2019 UCAR
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

__all__ = ['geometry_dict', 'state_dict', 'output_dict']

# --------------------------------------------------------------------------------------------------

def geometry_dict(section_name,path,levs):

  geomdict = {
    section_name: {
      "nml_file_mpp": path+"/fmsmpp.nml",
      "nml_file": path+"/input.nml",
      "trc_file": path+"/field_table",
      "pathfile_akbk": path+"/akbk"+levs+".nc4",
    },
  }
  return geomdict

# --------------------------------------------------------------------------------------------------

def state_dict(section_name,path,filename_bkgd='',filename_crtm='',filename_core='',
                                 filename_mois='',filename_surf='',variables=''):

  statedict = {
    section_name: {
      "filetype": "geos",
      "datapath": path,
    },
  }

  if filename_bkgd != '':
    statedict[section_name]['filename_bkgd'] = filename_bkgd
  if filename_crtm != '':
    statedict[section_name]['filename_crtm'] = filename_crtm
  if filename_core != '':
    statedict[section_name]['filename_core'] = filename_core
  if filename_mois != '':
    statedict[section_name]['filename_mois'] = filename_mois
  if filename_surf != '':
    statedict[section_name]['filename_surf'] = filename_surf

  if variables != '':
    statedict[section_name]['variables'] = variables

  return statedict

# --------------------------------------------------------------------------------------------------

def output_dict(section_name,path,filename_bkgd='',filename_crtm='',filename_core='',
                                 filename_mois='',filename_surf=''):

  outputdict = {
    section_name: {
      "filetype": "geos",
      "datapath": path,
    },
  }

  if filename_bkgd != '':
    outputdict[section_name]['filename_bkgd'] = filename_bkgd
  if filename_crtm != '':
    outputdict[section_name]['filename_crtm'] = filename_crtm
  if filename_core != '':
    outputdict[section_name]['filename_core'] = filename_core
  if filename_mois != '':
    outputdict[section_name]['filename_mois'] = filename_mois
  if filename_surf != '':
    outputdict[section_name]['filename_surf'] = filename_surf

  return outputdict

# --------------------------------------------------------------------------------------------------
