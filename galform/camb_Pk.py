import camb as cb
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec
import mpl_style
plt.style.use(mpl_style.style1)
#from camb import get_matter_power_interpolator
#from camb import results

# code to generate CAMB power matter power spectrum
# of UNIT or Gadget4 simulations to run SAMs (galform and shark) over this cosmology
# manually we introduce the sigma8 value we want for the power spectrum

cosmo = 'fnl_sam_high'

if cosmo == 'UNIT':
    string = 'UNIT'
    omega0 = 0.3089
    lambda0 = 0.6911
    h0 = 0.6774
    TCMB = 2.7255 # planck 2015
    ns = 0.9667
    sigma8 = 0.8147
    logkmin = -5
    logkmax = 3
    nk = 1001
    Obh2 = 0.02230 # planck 2015
    Omh2 = omega0*h0**2
    # Set Cosmology for CAMB (default As=2e-09, used for the normalisation)
    params = cb.set_params(ns=ns, H0=h0*100, ombh2=Obh2, omch2=(Omh2-Obh2), TCMB=TCMB, WantTransfer=True)

elif cosmo == 'fnl_sam_fid':
    string = 'fnl_sam_fid'
    omega0 = 0.3089
    lambda0 = 0.6911
    h0 = 0.6774
    TCMB = 2.7255 # planck 2015
    ns = 1
    sigma8 = 0.8159
    logkmin = -5
    logkmax = 3
    nk = 1001
    Obh2 = 0.0483*h0**2 # planck 2015
    Omh2 = omega0*h0**2
    # Set Cosmology for CAMB (default As=2e-09, used for the normalisation)
    params = cb.set_params(ns=ns, H0=h0*100, ombh2=Obh2, omch2=(Omh2-Obh2), TCMB=TCMB, WantTransfer=True)

elif cosmo == 'fnl_sam_high':
    string = 'fnl_sam_high'
    omega0 = 0.3089
    lambda0 = 0.6911
    h0 = 0.6774
    TCMB = 2.7255 # planck 2015
    ns = 1
    sigma8 = 0.83615
    logkmin = -5
    logkmax = 3
    nk = 1001
    Obh2 = 0.0483*h0**2 # planck 2015
    Omh2 = omega0*h0**2
    # Set Cosmology for CAMB (default As=2e-09, used for the normalisation)
    params = cb.set_params(ns=ns, H0=h0*100, ombh2=Obh2, omch2=(Omh2-Obh2), TCMB=TCMB, WantTransfer=True)

elif cosmo == 'fnl_sam_low':
    string = 'fnl_sam_low'
    omega0 = 0.3089
    lambda0 = 0.6911
    h0 = 0.6774
    TCMB = 2.7255 # planck 2015
    ns = 1
    sigma8 = 0.79534
    logkmin = -5
    logkmax = 3
    nk = 1001
    Obh2 = 0.0483*h0**2 # planck 2015
    Omh2 = omega0*h0**2
    # Set Cosmology for CAMB (default As=2e-09, used for the normalisation)
    params = cb.set_params(ns=ns, H0=h0*100, ombh2=Obh2, omch2=(Omh2-Obh2), TCMB=TCMB, WantTransfer=True)

kout = 10**(np.linspace(logkmin,logkmax,nk))

# Get the power spectrum at z=0 to obtain sigma8
pars = params.copy()
pars.set_matter_power(redshifts=[0.], kmax=10**logkmax)
pars.NonLinear = cb.model.NonLinear_none #Same sigma8 if NonLinear_both
results = cb.get_results(pars)
kh, z, pk = results.get_matter_power_spectrum(minkh=10**logkmin, maxkh=10**logkmax,npoints = nk)
# calculate sigma from linear power spectrum
sigma8_lin = np.array(results.get_sigma8_0())
print('Sigma8: ',sigma8) # final normalization
print('Sigma8_lin: ',sigma8_lin) # final normalization
snorm = (sigma8/sigma8_lin)**2 # normalization factor
# Linear matter power spectrum interpolator
PKlin = cb.get_matter_power_interpolator(params,kmax=10**logkmax,nonlinear=False,hubble_units=True)
# Interpolator including non-linear correction from halo model
PKNL = cb.get_matter_power_interpolator(params,kmax=10**logkmax,nonlinear=True,hubble_units=True)
#print(params)

z = 0.
Pout_lin = PKlin.P(z,kout)
#Pout_NL = PKNL.P(z,kout)
for i in range(nk):
    print(kout[i],Pout_lin[i],Pout_lin[i]*snorm)#,Pout_NL[i],Pout_NL[i]*snorm)

# save data (linear power spectrum is the important one)
outfil = '/home/chandro/CAMB/pk_'+cosmo+'_norm.dat'
tofile = zip(kout,Pout_lin*snorm)
with open(outfil, 'w') as outf: # written mode (not appended)
    outf.write('# k [h/Mpc],  P(k) [(h/Mpc)³]\n')
    np.savetxt(outf,list(tofile))#,fmt=('%.5f'))
    outf.closed

# Initialize the parameters for the figures
#fig = plt.figure(figsize=(7.8,10.8))
#gs = gridspec.GridSpec(5,1)
#gs.update(wspace=0., hspace=0.)
#xmin = -5 ; xmax = 3 # CAMB limits I think
#ymin = -7.5 ; ymax = 5
#yminb = 0.8 ; ymaxb = 1.2
#xtit = '$log_{10} ( k*(Mpc/h) ) $'
#ytit = '$log_{10} ( P(k)*(Mpc/h)³ )$'
#ytitb = 'Ratio $\\frac{P(k)[CAMB]}{P(k)[Galform]}$'
## Bias
#axb = plt.subplot(gs[-2:,:])
#axb.set_autoscale_on(False) ; axb.minorticks_on()
#axb.set_xlim(xmin,xmax) ; axb.set_ylim(yminb,ymaxb)
#axb.set_xlabel(xtit) ; axb.set_ylabel(ytitb)
## Plot 2PCF r-space
#ax = plt.subplot(gs[:-2,:],sharex=axb)
#ax.set_ylabel(ytit)
#ax.set_autoscale_on(False) ; ax.minorticks_on()
#ax.set_ylim(ymin,ymax)
#ax.set_xlim(xmin,xmax)
#ax.plot([],[],' ')
#plt.setp(ax.get_xticklabels(), visible=False)
#
#ax.plot(np.log10(k),np.log10(Pk),'-r',label='Galform',markersize=8)
#ax.plot(np.log10(k),np.log10(Pout_lin*snorm),'-b',label='CAMB',markersize=8)
#
#axb.plot(np.log10(k),Pout_lin*snorm/Pk,'-g',label='CAMB/Galform',markersize=8)
#axb.axhline(y=1, color='k', linestyle='-')
#
## Legends
#label0 = cosmo
#label = 'Galform'
#label1 = 'CAMB'
#leg = ax.legend([label0,label,label1], loc=3)
#labelb1 = 'CAMB/Galform'
#legb = axb.legend([labelb1])
#leg.draw_frame(False)
#legb.draw_frame(False)
#

fig = plt.figure(figsize=(7.8,10.8))
plt.plot(np.log10(kout),np.log10(Pout_lin*snorm),'.r',label='UNIT',markersize=8)
plt.xlabel('$log_{10} ( k*(Mpc/h) ) $')
plt.ylabel('$log_{10} ( P(k)*(Mpc/h)³ )$')
plt.xlim(logkmin,logkmax)
plt.ylim(-7.5,5)

# Save figure
fig.savefig('/home/chandro/CAMB/Pk_'+cosmo)
