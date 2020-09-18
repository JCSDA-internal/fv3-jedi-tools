#import matplotlib
#matplotlib.use('Agg')
import numpy as np
from netCDF4 import Dataset
import sys
import os
import shtns
#import matplotlib.pyplot as plt

class Spharmt(object):
    """
    wrapper class for commonly used spectral transform operations in
    atmospheric models.  Provides an interface to shtns compatible
    with pyspharm (pyspharm.googlecode.com).
    """
    def __init__(self,nlons,nlats,ntrunc,rsphere=6.3712e6,gridtype='gaussian'):
        self._shtns = shtns.sht(ntrunc, ntrunc, 1, \
                                norm=shtns.sht_orthonormal+shtns.SHT_NO_CS_PHASE)
        if gridtype == 'gaussian':
            #self._shtns.set_grid(nlats,nlons,shtns.sht_gauss_fly|shtns.SHT_PHI_CONTIGUOUS,1.e-10)
            self._shtns.set_grid(nlats,nlons,shtns.sht_quick_init|shtns.SHT_PHI_CONTIGUOUS,1.e-10)
        elif gridtype == 'regular':
            self._shtns.set_grid(nlats,nlons,shtns.sht_reg_dct|shtns.SHT_PHI_CONTIGUOUS,1.e-10)
        self.lats = np.arcsin(self._shtns.cos_theta)
        self.lons = (2.*np.pi/nlons)*np.arange(nlons)
        self.nlons = nlons
        self.nlats = nlats
        self.ntrunc = ntrunc
        self.nlm = self._shtns.nlm
        self.degree = self._shtns.l
        self.lap = -self.degree*(self.degree+1.0).astype(np.complex)
        self.invlap = np.zeros(self.lap.shape, self.lap.dtype)
        self.invlap[1:] = 1./self.lap[1:]
        self.rsphere = rsphere
        self.lap = self.lap/rsphere**2
        self.invlap = self.invlap*rsphere**2
    def grdtospec(self,data):
        """compute spectral coefficients from gridded data"""
        return self._shtns.analys(data)
    def spectogrd(self,dataspec):
        """compute gridded data from spectral coefficients"""
        return self._shtns.synth(dataspec)
    def getuv(self,vrtspec,divspec):
        """compute wind vector from spectral coeffs of vorticity and divergence"""
        return self._shtns.synth((self.invlap/self.rsphere)*vrtspec, (self.invlap/self.rsphere)*divspec)
    def getvrtdivspec(self,u,v):
        """compute spectral coeffs of vorticity and divergence from wind vector"""
        vrtspec, divspec = self._shtns.analys(u, v)
        return self.lap*self.rsphere*vrtspec, self.lap*self.rsphere*divspec
    def getpsichi(self,u,v):
        psispec, chispec = self._shtns.analys(u, v)
        return self.rsphere*self.spectogrd(psispec), self.rsphere*self.spectogrd(chispec)
        #vrtspec, divspec = self.getvrtdivspec(u, v)
        #psispec = self.invlap*vrtspec; chispec = self.invlap*divspec
        #return self.spectogrd(psispec), self.spectogrd(chispec)
    def getgrad(self,divspec):
    	"""compute gradient vector from spectral coeffs"""
    	vrtspec = np.zeros(divspec.shape, dtype=np.complex)
    	u,v = self._shtns.synth(vrtspec,divspec)
    	return u/rsphere, v/rsphere

filename = sys.argv[1]
nc = Dataset(filename,'a')
u = nc['ugrd'][:].squeeze().astype(np.float)
v = nc['vgrd'][:].squeeze().astype(np.float)
psi = nc.createVariable('psigrd',np.float32, ('time', 'pfull', 'grid_yt', 'grid_xt'))
chi = nc.createVariable('chigrd',np.float32, ('time', 'pfull', 'grid_yt', 'grid_xt'))
nlevs,nlats,nlons = u.shape
re = 6.3712e6 # radius of earth
gaugrid = Spharmt(nlons,nlats,nlats//2)
for nlev in range(nlevs):
    psig, chig = gaugrid.getpsichi(u[nlev],v[nlev])
    psi[0,nlev,...]=psig
    chi[0,nlev,...]=chig
    if nlev == 55:
        plt.imshow(chi)
        plt.colorbar()
        plt.savefig('chi.png')
        raise SystemExit
nc.close()
