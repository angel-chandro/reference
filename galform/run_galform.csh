#!/bin/tcsh -ef

# run galform-2.7.0 for specified model & single output redshift, 
# using N-body trees from specified simulation
# run on a single snapshot and single subvolume

# USAGE: 
# run interactively: run_galform_Nbody_dustmodels.csh model Nbody_sim iz ivol
# run in BSUB batch queue: 
# qsub run_galform_Nbody_dustmodels.csh -v model=$model, Nbody_sim=$Nbody_sim, iz=$iz, ivol=$ivol

# model = Galform model name (Galform parameters)
# Nbody_sim = N-body simulation name (halo merger trees & cosmological parameters)
# iz = snapshot number
# ivol = subvolume number

# set variable Nbody_sim to choose which N-body simulation running Galform onniffirg
# script then sets up filenames for merger trees, snapshot redshifts and subvolumes
# also forces cosmological and power spectrum parameters to be consistent with N-body sim
# Galform output files written in master directory depending on simulation name

# this version computes dust emission. does GALFORM runs for computing LFs 
# at different z and sub-mm number counts, and for standard plots

# NB this script uses the scripts 
# ./replace_variable.csh, ./replace_vector.csh & ./delete_variable.csh
# to modify the GALFORM input parameters file

unlimit stacksize
unlimit datasize

# Go to the directory containing Galform executables
set work_directory = /home/chandro/galform/
cd $work_directory
echo 'Working at:' $work_directory

set src_dir = $work_directory
set build_dir = $work_directory/build
set stellar_pop_dir = /home2/vgonzalez/buds/Galform/Data/stellar_pop/
# stellar_pop path

# Report time and host we're running on 
echo running $0 $*
date
echo HOST= $HOST

# Only check for command line args if not already set
if ( ! ( $?model ) ) then
    echo 'number of arguments=' $#argv
    if( $#argv == 3) then
	set model = $1
	set Nbody_sim = $2
	set iz = $3
    else if( $#argv == 4) then
	set model = $1
	set Nbody_sim = $2
	set iz = $3
	set ivol = $4
    else
	echo ERROR - USAGE: run_galform.csh model Nbody_sim iz 
	exit 1
    endif
endif 
  
# if running in BSUB batch queue, these parameters passed into script using -v
echo model= $model
echo Nbody_sim= $Nbody_sim
echo iz= $iz
echo ivol= $ivol

# flags to turn on/off different parts of script
set compile     = false
# run
set galform     = true
set neta        = false

# for standard plots
set lum_fun     = false
set samp_z0     = false

set cosmicsed       = false

# for other plots 
set lum_fun_burst = false
set samp2_z0      = false
set sedfit        = false   # For GAMA LFs and Mass derivation 
set agn           = false   # For SMBH/AGN related plots  
set sed_agn       = false   # For SMBH/AGN + galaxy absolute magnitudes 
set samp_mah      = false   # For making MAH & NFW plots 
set study_stellar_mass_function = false # For making stellar mass function plots. 
set dust_props    = false

set elgs        = false
set K_Bj        = false
set elliott     = true # it generates the output for the Elliott et al. 2021 calibration plots
 
set keep_inputs = false #if true doesn't delete galform_input_file (necessary for  re-running galform with same input file to output sfhs) 
# main directory which will contain subdirectories for each model
set models_dir = /home/chandro/Galform_Out/simulations/elliott/$Nbody_sim
mkdir -p $models_dir

# additional parameters for sample_gals & lum_fun
set upsilon2 = 1     # secondary M/L rescaling factor for brown dwarfs
#set ISEED2 = -81037  # random seed for galaxy inclinations
set ISEED2 = -81027  # random seed for galaxy inclinations

############################################################################
# alias awk on Solaris to be the modern version, not the ancient version
if( $OSTYPE == SunOS || $OSTYPE == solaris ) then
    alias awk nawk  # on Solaris
endif

# check for existence of GNU make, and use that if it exists
if( -X gmake ) then
    alias make gmake
endif

############################################################################
# set N-body file names and parameter values according to which simulation  being used
# also set parameters for cosmology and power spectrum so that they coincide
# with those used in N-body sim

if( $Nbody_sim == Mill1 ) then
# Millennium-1 simulation
# snapshots in range iz = 7-63
# subvolumes in range ivol = 0-511

# files with N-body data
    set Nbody_trees_dir = /cosma5/data/durham/Galform/Merger_Trees/Millennium/new
    set snapshot_file = $Nbody_trees_dir/redshift_list
    set aquarius_tree_file  = $Nbody_trees_dir/treedir_063/tree_063
    set aquarius_particle_file = $Nbody_trees_dir/particle_lists/particle_list_063
# volume for each subvolume read from volumes.txt
    #set volume_file = $Nbody_trees_dir/file_info/volumes.txt
    set volume = 0
## simulation parameters
    #set lbox = 500.0
    #set mpart = 8.606567e8
# cosmological parameters
    set omega0 = 0.25
    set lambda0 = 0.75
    set omegab = 0.045
    set h0 = 0.73
# power spectrum
    set sigma8 = 0.9
    set PKfile = Power_Spec/pk_Mill.dat
# snapshot number for z=0
    set iz0 = 63
    set iz1 = 41
    set iz2 = 32
    set iz3 = 27

else if( $Nbody_sim == Mill2 ) then
# Millennium-2 simulation
# snapshots in range iz = 0-67
# subvolumes in range ivol = 0-63

# files with N-body data
    set Nbody_trees_dir = /cosma5/data/durham/Galform/Merger_Trees/Millennium2/new
    set snapshot_file = $Nbody_trees_dir/redshift_list
    set aquarius_tree_file     = $Nbody_trees_dir/treedir_067/tree_067
    set aquarius_particle_file = $Nbody_trees_dir/particle_lists/particle_list_067
# each subvolume has equal volume - no volumes.txt file
    set volume_file = 0
    set volume = 15625.0
# simulation parameters
    #set lbox = 100.0
   #set mpart = 6.885254e6
# cosmological parameters
    set omega0 = 0.25
    set lambda0 = 0.75
    set omegab = 0.045
    set h0 = 0.73
# power spectrum
    set sigma8 = 0.9
    set PKfile = Power_Spec/pk_Mill.dat
# snapshot number for z=0
    set iz0 = 67
    #set iz1 = 45
    #set iz2 = 36
    #set iz3 = 31

else if( $Nbody_sim == MillGas ) then
# MillGas simulation
# snapshots in range iz = 0-61
# subvolumes in range ivol = 0-63

# files with N-body data
    set Nbody_trees_dir = /cosma5/data/jch/Galform/Merger_Trees/MillGas/dm/500/new
    set snapshot_file = $Nbody_trees_dir/redshift_list
    set aquarius_tree_file = $Nbody_trees_dir/treedir_061/tree_061
    set aquarius_particle_file = $Nbody_trees_dir/particle_lists/particle_list_061
# each subvolume has equal volume - no volumes.txt file
    set volume_file = 0
    set volume = 1953125.0
# cosmological parameters
    #set lbox = 500.0
    #set mpart = 9.363946e8
    set omega0 = 0.272
    set lambda0 = 0.728
    set omegab = 0.0455
    set h0 = 0.704
# power spectrum
    set sigma8 = 0.810
    set PKfile = Power_Spec/pk_MillGas_norm.dat
# snapshot number for z=0
    set iz0 = 61
    #set iz1 = 39
    #set iz2 = 30
    #set iz3 = 25


else if( $Nbody_sim == DoveCDM ) then
# DOVE CDM simulation
# snapshots in range iz = 0-159
# subvolumes in range ivol = 0-63

# files with N-body data
    set Nbody_trees_dir = /cosma5/data/jch/Galform/Merger_Trees/Dove/CDM/trees
    set snapshot_file = $Nbody_trees_dir/redshift_list 
    set aquarius_tree_file = $Nbody_trees_dir/treedir_159/tree_159 
    set aquarius_particle_file = $Nbody_trees_dir/particle_lists/particle_list_159
# each subvolume has equal volume - no volumes.txt file
    set volume_file = 0
    set volume = 5451.776000000002
# cosmological parameters
    set lbox = 70.4
    set mpart = 6195595.0
    set omega0 = 0.272
    set lambda0 = 0.728
    set omegab = 0.0455
    set h0 = 0.704
# power spectrum
    set sigma8 = 0.810
    set PKfile = Data/Power_Spec/pk_MillGas_norm.dat
# snapshot number for z=0
    set iz0 = 159

else if( $Nbody_sim == DoveWDM.clean ) then
# DOVE WDM simulation
# snapshots in range iz = 0-79
# subvolumes in range ivol = 0-63

# files with N-body data
    set Nbody_trees_dir = /cosma5/data/durham/dph3apc/dove/wdm/trees_cleaned 
    set snapshot_file = $Nbody_trees_dir/dovewdmclean_redshift_list
    set aquarius_tree_file = $Nbody_trees_dir/treedir_079/tree_079 
    set aquarius_particle_file = $Nbody_trees_dir/particle_lists/particle_list_079
# each subvolume has equal volume - no volumes.txt file
    set volume_file = 0
    set volume = 5451.776000000002
# cosmological parameters
    set lbox = 70.4
    set mpart = 6195595.0
    set omega0 = 0.272
    set lambda0 = 0.728
    set omegab = 0.0455
    set h0 = 0.704
# power spectrum
    set sigma8 = 0.810
    set PKfile = Power_Spec/pk_WDMDove.dat
    #set wdm = true
    #set itrans = 10.
    #set Mwdm = 
    #set FiltFac_beta = 1.0
# snapshot number for z=0
    set iz0 = 79


else if( $Nbody_sim == DoveCDM.lr ) then
# DOVE CDM simulation with lower resolution
# snapshots in range iz = 0-79
# subvolumes in range ivol = 0-63

# files with N-body data
    set Nbody_trees_dir = /cosma5/data/durham/dph3apc/dove/cdm/trees_as_wdm
    set snapshot_file = $Nbody_trees_dir/dovecdmlr_redshift_list
    set aquarius_tree_file = $Nbody_trees_dir/treedir_079/tree_079 
    set aquarius_particle_file = $Nbody_trees_dir/particle_lists/particle_list_079
# each subvolume has equal volume - no volumes.txt file
    set volume_file = 0
    set volume = 5451.776000000002
# cosmological parameters
    set lbox = 70.4
    set mpart = 6195595.0
    set omega0 = 0.272
    set lambda0 = 0.728
    set omegab = 0.0455
    set h0 = 0.704
# power spectrum
    set sigma8 = 0.810
    set PKfile = Data/Power_Spec/pk_MillGas_norm.dat
# snapshot number for z=0
    set iz0 = 79


else if( $Nbody_sim == L800 ) then
# L800 simulation
# snapshots in range iz = xxx
# subvolumes in range ivol = 0-1024

# files with N-body data
    set Nbody_trees_dir = /cosma5/data/jch/L800/Runs/Trees/initial
    set snapshot_file = /cosma5/data/jch/L800/Runs/Trees/redshift_list.txt
    set aquarius_tree_file  = $Nbody_trees_dir/treedir_269/tree_269
    set aquarius_particle_file = $Nbody_trees_dir/particle_lists/particle_list_269
# volume for each subvolume read from volumes.txt
    #set volume_file = $Nbody_trees_dir/file_info/volumes.txt
    set volume = 155626.1
## simulation parameters
    set lbox = 542.16
    set mpart = 1.061E+08
# cosmological parameters
    set omega0 = 0.307
    set lambda0 = 0.693
    set omegab = 0.0482519
    set h0 = 0.6777
# power spectrum
    set sigma8 = 0.8288   
    set PKfile = Power_Spec/pk_Planck_norm.dat     
# snapshot number for z=0
    set iz0 = 271
    set iz1 = 176
    set iz2 = 142
    set iz3 = 120



else if( $Nbody_sim == EagleDM ) then #WRONG PATHS
# EAGLE DM-only simulation
# snapshots in range iz = 0-200
# subvolumes in range ivol = 0-127

# files with N-body data
    set Nbody_trees_dir = /cosma5/data/durham/jch/Eagle/Merger_Trees/DMONLY/L0100N1504
    set snapshot_file = $Nbody_trees_dir/eagle_redshift_list
    set aquarius_tree_file = $Nbody_trees_dir/trees/treedir_200/tree_200
    set aquarius_particle_file = $Nbody_trees_dir/trees/particle_lists/particle_list_200
# each subvolume has equal volume - no volumes.txt file
    set volume_file = 0
    set volume = 2431.65796432
# cosmological parameters
    #set lbox = 67.77
    #set mpart = 9.363946e8
    set omega0 = 0.307
    set lambda0 = 0.693
    set omegab = 0.0482519
    set h0 = 0.6777
# power spectrum
    set sigma8 = 0.8288	
    set PKfile = Power_Spec/pk_Planck_norm.dat
# snapshot number for z=0
    set iz0 = 200
    #set iz1 = 134
    #set iz2 = 99
    #set iz3 = 74


else if( $Nbody_sim == EagleDM67 ) then
# EAGLE DM-only simulation with 67 snapshots
# subvolumes in range ivol = 0-127

# files with N-body data
    set Nbody_trees_dir = /cosma5/data/durham/jch/Eagle/Merger_Trees/DMONLY/L0100N1504/trees_snapnums62
    set snapshot_file = $Nbody_trees_dir/redshift_list
    set aquarius_tree_file = $Nbody_trees_dir/treedir_067/tree_067
    set aquarius_particle_file = $Nbody_trees_dir/particle_lists/particle_list_067
# each subvolume has equal volume - no volumes.txt file
    set volume_file = 0
    set volume = 2431.65796432
# cosmological parameters
    #set lbox = 67.77
    #set mpart = 9.363946e8
    set omega0 = 0.307
    set lambda0 = 0.693
    set omegab = 0.0482519
    set h0 = 0.6777
# power spectrum
    set sigma8 = 0.8288	
    set PKfile = Power_Spec/pk_Planck_norm.dat
# snapshot number for z=0
    set iz0 = 67
    #set iz1 = 45
    #set iz2 = 34
    #set iz3 = 25


else if( $Nbody_sim == EagleDM101 ) then
# EAGLE DM-only simulation with 67 snapshots
# subvolumes in range ivol = 0-127

# files with N-body data
    set Nbody_trees_dir = /cosma5/data/durham/jch/Eagle/Merger_Trees/DMONLY/L0100N1504/trees_snapnums100
    set snapshot_file = $Nbody_trees_dir/redshift_list
    set aquarius_tree_file = $Nbody_trees_dir/treedir_101/tree_101
    set aquarius_particle_file = $Nbody_trees_dir/particle_lists/particle_list_101
# each subvolume has equal volume - no volumes.txt file
    set volume_file = 0
    set volume = 2431.65796432
# cosmological parameters
    #set lbox = 67.77
    #set mpart = 9.363946e8
    set omega0 = 0.307
    set lambda0 = 0.693
    set omegab = 0.0482519
    set h0 = 0.6777
# power spectrum
    set sigma8 = 0.8288	
    set PKfile = Power_Spec/pk_Planck_norm.dat
# snapshot number for z=0
    set iz0 = 101
    #set iz1 = 68
    #set iz2 = 50
    #set iz3 = 38

    
else if( $Nbody_sim == nifty62.5 ) then   #Merger trees are on tape
# AHF 62.5 Mpc/h run for the nifty comparison
# snapshots in range iz = 0-61
# subvolumes in range ivol = 0-63

# files with N-body data
    set Nbody_trees_dir = /home/chandro/output/Dhalos_UNIT_1Gpc_4096_fixedAmp_001/
    set snapshot_file = $Nbody_trees_dir/redshift_list_shark.txt
    set aquarius_tree_file = $Nbody_trees_dir/ConsistentTrees/treedir_001_128_nosort_subvolume_cat/tree_test_128
    # each subvolume has equal volume - no volumes.txt file
    set volume_file = 0 # no file here!
    set volume = 15625
# cosmological parameters
    set omega0 = 0.3089
    set lambda0 = 0.6911
    set omegab = 0.0486
    set h0 = 0.6774
# power spectrum
    set sigma8 = 0.8147
    set PKfile = ../../CAMB/pk_UNIT_norm.dat
# snapshot number for z=0
    set iz0 = 128
    #set iz1 = 39
    #set iz2 = 30
    #set iz3 = 25

else if( $Nbody_sim == UNIT100 ) then
# UNIT DM-only simulation
# snapshots in range iz = 1-128
# subvolumes in range ivol = 0-63

# files with N-body data
    set Nbody_trees_dir = /home/chandro/output/Dhalos_UNIT_1Gpc_4096_fixedAmp_001/
    set snapshot_file = $Nbody_trees_dir/redshift_list_shark.txt
    set aquarius_tree_file = $Nbody_trees_dir/ConsistentTrees/treedir_001_128_nosort_subvolume100_cat/tree_test_128
    # each subvolume has equal volume - no volumes.txt file
    set volume_file = 0 # no file here!
    set volume = 15625
# cosmological parameters
    set omega0 = 0.3089
    set lambda0 = 0.6911
    set omegab = 0.0486
    set h0 = 0.6774
# power spectrum
    set sigma8 = 0.8147
    set PKfile = ../../CAMB/pk_UNIT_norm.dat
# snapshot number for z=0
    set iz0 = 128
    set iz1 = 95
    #set iz2 = 30
    #set iz3 = 25

else if( $Nbody_sim == UNIT200 ) then
# UNIT DM-only simulation
# snapshots in range iz = 1-128
# subvolumes in range ivol = 0-63

# files with N-body data
    set Nbody_trees_dir = /home/chandro/output/Dhalos_UNIT_1Gpc_4096_fixedAmp_001/
    set snapshot_file = $Nbody_trees_dir/redshift_list_shark.txt
    set aquarius_tree_file = $Nbody_trees_dir/ConsistentTrees/treedir_001_128_subvolume200_nocat/tree_test_128
    # each subvolume has equal volume - no volumes.txt file
    set volume_file = 0 # no file here!
    set volume = 125000
# cosmological parameters
    set omega0 = 0.3089
    set lambda0 = 0.6911
    set omegab = 0.0486
    set h0 = 0.6774
# power spectrum
    set sigma8 = 0.8147
    set PKfile = ../../CAMB/pk_UNIT_norm.dat
# snapshot number for z=0
    set iz0 = 128
    #set iz1 = 39
    #set iz2 = 30
    #set iz3 = 25

else if( $Nbody_sim == UNIT ) then
# UNIT DM-only simulation
# snapshots in range iz = 1-128
# subvolumes in range ivol = 0-63

# files with N-body data
    set Nbody_trees_dir = /data8/vgonzalez/SAMs/trees/ # path to Dhalos trees
    set snapshot_file = /home/chandro/dhalo-trees/Parameters/UNITsim+CT/redshift_list.txt # snapshot-redshift list again
    set aquarius_tree_file = $Nbody_trees_dir/tree_128 # Dhalos trees
    # each subvolume has equal volume - no volumes.txt file
    set volume_file = 0 # no file here!
    set volume = 15625000 # subvolume = (1000)**3/64
# cosmological parameters
    set omega0 = 0.3089
    set lambda0 = 0.6911
    set omegab = 0.0486
    set h0 = 0.6774
# power spectrum
    set sigma8 = 0.8147
    set PKfile = ../../CAMB/pk_UNIT_norm.dat
# snapshot number for z=0
    # output redshift
    set iz0 = 128 # z=0
    set iz1 = 95 # z=1.1
    #set iz2 = 30
    #set iz3 = 25

else if( $Nbody_sim == Gadget4_DHBT ) then
# Gadget4 DM-only simulation
# snapshots in range iz = 0-8
# subvolumes in range ivol = 0-15

# files with N-body data
    set Nbody_trees_dir = /home/chandro/dhalo-trees_rhalf+snap_testSUBFIND/Parameters/UNITsim+SUBFIND_GHDF5+D_multiple_HBT/trees/
    set snapshot_file = /home/chandro/gadget4/examples/DM-L50-N128/redshift_list_moresnaps.txt
    set aquarius_tree_file = $Nbody_trees_dir/tree_008
    set aquarius_particle_file = $Nbody_trees_dir/particle_lists/particle_list_008
    # each subvolume has equal volume - no volumes.txt file
    set volume_file = 0 # no file here!
    set volume = 7812.5
# cosmological parameters
    set omega0 = 0.308
    set lambda0 = 0.692
    set omegab = 0.0482
    set h0 = 0.678
# power spectrum
    set sigma8 = 0.9
    set PKfile = ../../CAMB/pk_Gadget4_norm.dat
# snapshot number for z=0
    set iz0 = 8


else if( $Nbody_sim == Gadget4_DHBT_nonupdate ) then
# Gadget4 DM-only simulation
# snapshots in range iz = 0-8
# subvolumes in range ivol = 0-15

# files with N-body data
    set Nbody_trees_dir = /home/chandro/dhalo-trees_rhalf+snap_testSUBFIND/Parameters/UNITsim+SUBFIND_GHDF5+D_multiple_HBT/trees_nonupdate/
    set snapshot_file = /home/chandro/gadget4/examples/DM-L50-N128/redshift_list_moresnaps.txt
    set aquarius_tree_file = $Nbody_trees_dir/tree_008
    set aquarius_particle_file = $Nbody_trees_dir/particle_lists/particle_list_008
    # each subvolume has equal volume - no volumes.txt file
    set volume_file = 0 # no file here!
    set volume = 7812.5
# cosmological parameters
    set omega0 = 0.308
    set lambda0 = 0.692
    set omegab = 0.0482
    set h0 = 0.678
# power spectrum
    set sigma8 = 0.9
    set PKfile = ../../CAMB/pk_Gadget4_norm.dat
# snapshot number for z=0
    set iz0 = 8

    
else if( $Nbody_sim == Gadget4_SHBT ) then
# Gadget4 DM-only simulation
# snapshots in range iz = 0-8
# subvolumes in range ivol = 0-15

# files with N-body data
    set Nbody_trees_dir = /home/chandro/dhalo-trees_rhalf+snap_testSUBFIND/Parameters/UNITsim+SUBFIND_GHDF5+S_multiple_HBT/trees/
    set snapshot_file = /home/chandro/gadget4/examples/DM-L50-N128/redshift_list_moresnaps.txt
    set aquarius_tree_file = $Nbody_trees_dir/tree_008
    set aquarius_particle_file = $Nbody_trees_dir/particle_lists/particle_list_008
    # each subvolume has equal volume - no volumes.txt file
    set volume_file = 0 # no file here!
    set volume = 7812.5
# cosmological parameters
    set omega0 = 0.308
    set lambda0 = 0.692
    set omegab = 0.0482
    set h0 = 0.678
# power spectrum
    set sigma8 = 0.9
    set PKfile = ../../CAMB/pk_Gadget4_norm.dat
# snapshot number for z=0
    set iz0 = 8

    
else if( $Nbody_sim == Gadget4_SHBT_nonupdate ) then
# UNIT DM-only simulation
# snapshots in range iz = 1-128
# subvolumes in range ivol = 0-63

# files with N-body data
    set Nbody_trees_dir = /home/chandro/dhalo-trees_rhalf+snap_testSUBFIND/Parameters/UNITsim+SUBFIND_GHDF5+S_multiple_HBT/trees_nonupdate/
    set snapshot_file = /home/chandro/gadget4/examples/DM-L50-N128/redshift_list_moresnaps.txt
    set aquarius_tree_file = $Nbody_trees_dir/tree_008
    set aquarius_particle_file = $Nbody_trees_dir/particle_lists/particle_list_008
    # each subvolume has equal volume - no volumes.txt file
    set volume_file = 0 # no file here!
    set volume = 7812.5
# cosmological parameters
    set omega0 = 0.308
    set lambda0 = 0.692
    set omegab = 0.0482
    set h0 = 0.678
# power spectrum
    set sigma8 = 0.9
    set PKfile = ../../CAMB/pk_Gadget4_norm.dat
# snapshot number for z=0
    set iz0 = 8

else if( $Nbody_sim == MillGas62.5 ) then
# MillGas 62.5 Mpc/h run 
# snapshots in range iz = 0-61
# subvolumes in range ivol = 1

# files with N-body data
    set Nbody_trees_dir = /cosma5/data/durham/jch/MillGas/data/dm/62.5/trees/
    set snapshot_file = /cosma5/data/durham/Galform/Merger_Trees/MillGas/dm/500/new/redshift_list
    set aquarius_tree_file = $Nbody_trees_dir/treedir_061/tree_061
    set aquarius_particle_file = $Nbody_trees_dir/particle_lists/particle_list_061 
# each subvolume has equal volume - no volumes.txt file
    set volume_file = 0
    set volume = 244140.625
# cosmological parameters
    set omega0 = 0.272
    set lambda0 = 0.728
    set omegab = 0.0455
    set h0 = 0.704
# power spectrum
    set sigma8 = 0.810
    set PKfile = Power_Spec/pk_MillGas_norm.dat
# snapshot number for z=0
    set iz0 = 61
    #set iz1 = 39
    #set iz2 = 30
    #set iz3 = 25

endif

############################################################################
# create subdirectories for output files

# create string giving redshift with fewer digits, for use in file & directory names
# use fixed format with 3 digits after decimal point, to match format used for eta dust files

# directory for this model
set model_dir = $models_dir/$model
mkdir -p $model_dir

# extract the redshift corresponding to N-body snapshot number iz
set z = `awk -v iz=$iz '$1==iz {print $2}' $snapshot_file`
# check that snapshot number corresponds to a redshift in the file
if ($z == '') then
    echo no redshift for snapshot $iz in file $snapshot_file
    exit
endif
echo running snapshot iz= $iz,   redshift z= $z

set zname = `echo $z | awk '{printf( "%6.3f",$1)}'`
echo zname= $zname

# directory for this model at this redshift in this subvolume
set output_dir = $model_dir/iz${iz}/ivol${ivol}
mkdir -p $output_dir

# write a one line file with redshift for that snapshot
echo iz= $iz  z= $zname >! $model_dir/iz${iz}/zsnap.dat


# *********************************************************
# COMPILE PROGRAMS
# *********************************************************

if( $compile == true ) then
    # Compile using cmake
    mkdir -p ${build_dir}
    cd ${build_dir}
    cmake ${src_dir} -DCMAKE_BUILD_TYPE=Release
    make galform2 neta_ave_disk neta_ave_burst sample_gals

    # make .sm file for this machine
    #cd ${src_dir}
    #./SM_Scripts/Make_SM_Environment_File.pl
endif

# store & report name of executables
set GALFORM2_EXE       = ${build_dir}/galform2
set NETA_AVE_DISK_EXE  = ${build_dir}/neta_ave_disk
set NETA_AVE_BURST_EXE = ${build_dir}/neta_ave_burst
set SAMPLE_GALS_EXE    = ${build_dir}/sample_gals
echo ""
echo " using executables:"
echo "   GALFORM2_EXE = ${GALFORM2_EXE}"
echo "   NETA_AVE_DISK_EXE = ${NETA_AVE_DISK_EXE}"
echo "   NETA_AVE_BURST_EXE = ${NETA_AVE_BURST_EXE}"
echo "   SAMPLE_GALS_EXE = ${SAMPLE_GALS_EXE}"
echo ""

############################################################################
# construct GALFORM input parameters file for this model, at this redshift

# GALFORM input parameters filename used for this run
\mkdir -p ./params
set galform_inputs_file = ./params/${Nbody_sim}_${model}_iz${iz}_ivol${ivol}.input.temp
echo creating GALFORM input parameters file $galform_inputs_file

# modify parameters of base model/run
if( $model == gp19) then
    # GALFORM input parameters file for base model/run
    set base_inputs_file = /home/chandro/Galform_Out/run_codes/UNIT_subvol200.ref
    # make copy of base input parameters file
    cp $base_inputs_file $galform_inputs_file
    # set default values of dust parameters for post-processing
    source /home/chandro/galform/dustpars_Baugh05.csh

else if( $model == gp19.vimal ) then
    # GALFORM input parameters file for base model/run
    set base_inputs_file = /home/chandro/Galform_Out/run_codes/UNIT.ref # ref file
    # make copy of base input parameters file
    cp $base_inputs_file $galform_inputs_file
    # set default values of dust parameters for post-processing
    source /home/chandro/galform/dustpars_Baugh05.csh

    ./replace_variable.csh $galform_inputs_file aquarius_nbody_merging  .true.
    ./replace_variable.csh $galform_inputs_file aquarius_nbody_merging_scheme  1
    ./replace_variable.csh $galform_inputs_file aquarius_nbody_merging_interior_mass .true.
    ./replace_variable.csh $galform_inputs_file emlines  .false.


else if( $model == gp19.vimal.em) then
    # GALFORM input parameters file for base model/run
    set base_inputs_file = /home/chandro/Galform_Out/run_codes/UNIT_subvol200.ref
    # make copy of base input parameters file
    cp $base_inputs_file $galform_inputs_file
    # set default values of dust parameters for post-processing
    source /home/chandro/galform/dustpars_Baugh05.csh

    echo Here
    echo $var1
    echo $var2
    echo There
    
    ./replace_variable.csh $galform_inputs_file aquarius_nbody_merging  .true.
    ./replace_variable.csh $galform_inputs_file aquarius_nbody_merging_scheme  1
    ./replace_variable.csh $galform_inputs_file aquarius_nbody_merging_interior_mass .true.
    ./replace_variable.csh $galform_inputs_file alpha_cool  $var1
    ./replace_variable.csh $galform_inputs_file alphahot  $var2

else if( $model == gp19.vimal.low_diskinst) then
    # GALFORM input parameters file for base model/run
    set base_inputs_file = /home/chandro/Galform_Out/run_codes/UNIT_subvol200.ref
    # make copy of base input parameters file
    cp $base_inputs_file $galform_inputs_file
    # set default values of dust parameters for post-processing
    source /home/chandro/galform/dustpars_Baugh05.csh

    ./replace_variable.csh $galform_inputs_file aquarius_nbody_merging  .true.
    ./replace_variable.csh $galform_inputs_file aquarius_nbody_merging_scheme  1
    ./replace_variable.csh $galform_inputs_file aquarius_nbody_merging_interior_mass .true.
    ./replace_variable.csh $galform_inputs_file stabledisk 0.61
    ./replace_variable.csh $galform_inputs_file emlines  .false.

else if( $model == gp19.vimal.up_diskinst) then
    # GALFORM input parameters file for base model/run
    set base_inputs_file = /home/chandro/Galform_Out/run_codes/UNIT_subvol200.ref
    # make copy of base input parameters file
    cp $base_inputs_file $galform_inputs_file
    # set default values of dust parameters for post-processing
    source /home/chandro/galform/dustpars_Baugh05.csh

    ./replace_variable.csh $galform_inputs_file aquarius_nbody_merging  .true.
    ./replace_variable.csh $galform_inputs_file aquarius_nbody_merging_scheme  1
    ./replace_variable.csh $galform_inputs_file aquarius_nbody_merging_interior_mass .true.
    ./replace_variable.csh $galform_inputs_file stabledisk 1.1
    ./replace_variable.csh $galform_inputs_file emlines  .false.

else if( $model == gp19.vimal.low_acool) then
    # GALFORM input parameters file for base model/run
    set base_inputs_file = /home/chandro/Galform_Out/run_codes/UNIT_subvol200.ref
    # make copy of base input parameters file
    cp $base_inputs_file $galform_inputs_file
    # set default values of dust parameters for post-processing
    source /home/chandro/galform/dustpars_Baugh05.csh

    ./replace_variable.csh $galform_inputs_file aquarius_nbody_merging  .true.
    ./replace_variable.csh $galform_inputs_file aquarius_nbody_merging_scheme  1
    ./replace_variable.csh $galform_inputs_file aquarius_nbody_merging_interior_mass .true.
    ./replace_variable.csh $galform_inputs_file alpha_cool 0.2
    ./replace_variable.csh $galform_inputs_file emlines  .false.

else if( $model == gp19.vimal.up_acool) then
    # GALFORM input parameters file for base model/run
    set base_inputs_file = /home/chandro/Galform_Out/run_codes/UNIT_subvol200.ref
    # make copy of base input parameters file
    cp $base_inputs_file $galform_inputs_file
    # set default values of dust parameters for post-processing
    source /home/chandro/galform/dustpars_Baugh05.csh

    ./replace_variable.csh $galform_inputs_file aquarius_nbody_merging  .true.
    ./replace_variable.csh $galform_inputs_file aquarius_nbody_merging_scheme  1
    ./replace_variable.csh $galform_inputs_file aquarius_nbody_merging_interior_mass .true.
    ./replace_variable.csh $galform_inputs_file alpha_cool 1.2
    ./replace_variable.csh $galform_inputs_file emlines  .false.

else if( $model == gp14.grp) then
    # GALFORM input parameters file for base model/run
    set base_inputs_file = Gonzalez13_Nbody_MillGas.input.ref
    # make copy of base input parameters file
    cp $base_inputs_file $galform_inputs_file
    # set default values of dust parameters for post-processing
    source dustpars_Baugh05.csh

    ./replace_variable.csh $galform_inputs_file starvation .false.
    ./replace_variable.csh $galform_inputs_file RamPressure_Strip  .true.
    ./replace_variable.csh $galform_inputs_file RamPressure_Transfer_Fraction 0.1
    ./replace_variable.csh $galform_inputs_file Reheat_Min_Fraction 0.1

else if( $model == gp14.grp.anders) then
    # GALFORM input parameters file for base model/run
    set base_inputs_file = Gonzalez13_Nbody_MillGas.input.ref
    # make copy of base input parameters file
    cp $base_inputs_file $galform_inputs_file
    # set default values of dust parameters for post-processing
    source dustpars_Baugh05.csh

    ./replace_variable.csh $galform_inputs_file emlinefile Data/emlines_anders_fritze_2003.data 

    ./replace_variable.csh $galform_inputs_file starvation .false.
    ./replace_variable.csh $galform_inputs_file RamPressure_Strip  .true.
    ./replace_variable.csh $galform_inputs_file RamPressure_Transfer_Fraction 0.1
    ./replace_variable.csh $galform_inputs_file Reheat_Min_Fraction 0.1

else if( $model == lc14) then
    # GALFORM input parameters file for base model/run
    set base_inputs_file = Lacey14_Nbody_MillGas.input.ref
    # make copy of base input parameters file
    cp $base_inputs_file $galform_inputs_file
    # set default values of dust parameters for post-processing
    source dustpars_Lacey14.csh

    ./replace_variable.csh $galform_inputs_file tree_type AQUARIUS

else if( $model == lc16.newmg) then
    # GALFORM input parameters file for base model/run
    set base_inputs_file = Lacey16_newmg_Nbody_L800.input.ref
    # make copy of base input parameters file
    cp $base_inputs_file $galform_inputs_file
    # set default values of dust parameters for post-processing
    source dustpars_Lacey14.csh 

#######################
else if( $model == gp17) then #gp15newmg
    # GALFORM input parameters file for base model/run
    set base_inputs_file = Gonzalez18_Nbody_MillGas.input.ref
    # make copy of base input parameters file
    cp $base_inputs_file $galform_inputs_file
    # set default values of dust parameters for post-processing
    source dustpars_Baugh05.csh

else if( $model == gp17.spin) then #gp15newmg
    # GALFORM input parameters file for base model/run
    set base_inputs_file = Gonzalez18_Nbody_MillGas.input.ref
    # make copy of base input parameters file
    cp $base_inputs_file $galform_inputs_file
    # set default values of dust parameters for post-processing
    source dustpars_Baugh05.csh

    ./replace_variable.csh $galform_inputs_file SMBH_accretion_spinup 2
    ./replace_variable.csh $galform_inputs_file SMBH_Mseed 10.


else if( $model == gp17.spin.acce0.1) then #gp15newmg
    # GALFORM input parameters file for base model/run
    set base_inputs_file = Gonzalez18_Nbody_MillGas.input.ref
    # make copy of base input parameters file
    cp $base_inputs_file $galform_inputs_file
    # set default values of dust parameters for post-processing
    source dustpars_Baugh05.csh

    ./replace_variable.csh $galform_inputs_file SMBH_accretion_spinup 2
    ./replace_variable.csh $galform_inputs_file SMBH_Mseed 10.
    ./replace_variable.csh $galform_inputs_file SMBH_accretion_efficiency 0.1

else if( $model == gp17.spin.aram0) then #gp15newmg
    # GALFORM input parameters file for base model/run
    set base_inputs_file = Gonzalez18_Nbody_MillGas.input.ref
    # make copy of base input parameters file
    cp $base_inputs_file $galform_inputs_file
    # set default values of dust parameters for post-processing
    source dustpars_Baugh05.csh

    ./replace_variable.csh $galform_inputs_file SMBH_accretion_spinup 2
    ./replace_variable.csh $galform_inputs_file SMBH_Mseed 10.
    ./replace_variable.csh $galform_inputs_file alpha_RamPressure 0.

else if( $model == gp17.spin.aram0.5) then #gp15newmg
    # GALFORM input parameters file for base model/run
    set base_inputs_file = Gonzalez18_Nbody_MillGas.input.ref
    # make copy of base input parameters file
    cp $base_inputs_file $galform_inputs_file
    # set default values of dust parameters for post-processing
    source dustpars_Baugh05.csh

    ./replace_variable.csh $galform_inputs_file SMBH_accretion_spinup 2
    ./replace_variable.csh $galform_inputs_file SMBH_Mseed 10.
    ./replace_variable.csh $galform_inputs_file alpha_RamPressure 0.5


else if( $model == gp17.spin.aram1) then 
    # GALFORM input parameters file for base model/run
    set base_inputs_file = Gonzalez18_Nbody_MillGas.input.ref
    # make copy of base input parameters file
    cp $base_inputs_file $galform_inputs_file
    # set default values of dust parameters for post-processing
    source dustpars_Baugh05.csh

    ./replace_variable.csh $galform_inputs_file SMBH_accretion_spinup 2
    ./replace_variable.csh $galform_inputs_file SMBH_Mseed 10.
    ./replace_variable.csh $galform_inputs_file alpha_RamPressure 1


else if( $model == gp17.spin.aram1.5) then 
    # GALFORM input parameters file for base model/run
    set base_inputs_file = Gonzalez18_Nbody_MillGas.input.ref
    # make copy of base input parameters file
    cp $base_inputs_file $galform_inputs_file
    # set default values of dust parameters for post-processing
    source dustpars_Baugh05.csh

    ./replace_variable.csh $galform_inputs_file SMBH_accretion_spinup 2
    ./replace_variable.csh $galform_inputs_file SMBH_Mseed 10.
    ./replace_variable.csh $galform_inputs_file alpha_RamPressure 1.5

else if( $model == gp17.spin.tidal) then #gp15newmg
    # GALFORM input parameters file for base model/run
    set base_inputs_file = Gonzalez18_Nbody_MillGas.input.ref
    # make copy of base input parameters file
    cp $base_inputs_file $galform_inputs_file
    # set default values of dust parameters for post-processing
    source dustpars_Baugh05.csh

    ./replace_variable.csh $galform_inputs_file SMBH_accretion_spinup 2
    ./replace_variable.csh $galform_inputs_file SMBH_Mseed 10.
    ./replace_variable.csh $galform_inputs_file Tidal_Strip .true.
    ./replace_variable.csh $galform_inputs_file Galaxy_Tidal_Strip .true.


else if( $model == gp17.spin.ramt0) then 
    # GALFORM input parameters file for base model/run
    set base_inputs_file = Gonzalez18_Nbody_MillGas.input.ref
    # make copy of base input parameters file
    cp $base_inputs_file $galform_inputs_file
    # set default values of dust parameters for post-processing
    source dustpars_Baugh05.csh

    ./replace_variable.csh $galform_inputs_file SMBH_accretion_spinup 2
    ./replace_variable.csh $galform_inputs_file SMBH_Mseed 10.
    ./replace_variable.csh $galform_inputs_file RamPressure_Transfer_Fraction 0.0

else if( $model == gp17.spin.ramt0.01.btburst4) then 
    # GALFORM input parameters file for base model/run
    set base_inputs_file = Gonzalez18_Nbody_MillGas.input.ref
    # make copy of base input parameters file
    cp $base_inputs_file $galform_inputs_file
    # set default values of dust parameters for post-processing
    source dustpars_Baugh05.csh

    ./replace_variable.csh $galform_inputs_file SMBH_accretion_spinup 2
    ./replace_variable.csh $galform_inputs_file SMBH_Mseed 10.
    ./replace_variable.csh $galform_inputs_file RamPressure_Transfer_Fraction 0.01
    ./replace_variable.csh $galform_inputs_file btburst 4

else if( $model == gp17.spin.ramt0.01.stabledisk0.75.ac085) then 
    # GALFORM input parameters file for base model/run
    set base_inputs_file = Gonzalez18_Nbody_MillGas.input.ref
    # make copy of base input parameters file
    cp $base_inputs_file $galform_inputs_file
    # set default values of dust parameters for post-processing
    source dustpars_Baugh05.csh

    ./replace_variable.csh $galform_inputs_file SMBH_accretion_spinup 2
    ./replace_variable.csh $galform_inputs_file SMBH_Mseed 10.
    ./replace_variable.csh $galform_inputs_file RamPressure_Transfer_Fraction 0.01
    ./replace_variable.csh $galform_inputs_file stabledisk 0.75
    ./replace_variable.csh $galform_inputs_file alpha_cool 0.85

else if( $model == gp17.spin.ramt0.01.stabledisk0.75.e01.ac085) then 
    # GALFORM input parameters file for base model/run
    set base_inputs_file = Gonzalez18_Nbody_MillGas.input.ref
    # make copy of base input parameters file
    cp $base_inputs_file $galform_inputs_file
    # set default values of dust parameters for post-processing
    source dustpars_Baugh05.csh

    ./replace_variable.csh $galform_inputs_file SMBH_accretion_spinup 2
    ./replace_variable.csh $galform_inputs_file SMBH_Mseed 10.
    ./replace_variable.csh $galform_inputs_file RamPressure_Transfer_Fraction 0.01
    ./replace_variable.csh $galform_inputs_file stabledisk 0.75
    ./replace_variable.csh $galform_inputs_file epsilon_SMBH_Eddington 0.01
    ./replace_variable.csh $galform_inputs_file alpha_cool 0.85

else if( $model == gp17.spin.ramt0.01.stabledisk0.75.e01.ac087) then 
    # GALFORM input parameters file for base model/run
    set base_inputs_file = Gonzalez18_Nbody_MillGas.input.ref
    # make copy of base input parameters file
    cp $base_inputs_file $galform_inputs_file
    # set default values of dust parameters for post-processing
    source dustpars_Baugh05.csh

    ./replace_variable.csh $galform_inputs_file SMBH_accretion_spinup 2
    ./replace_variable.csh $galform_inputs_file SMBH_Mseed 10.
    ./replace_variable.csh $galform_inputs_file RamPressure_Transfer_Fraction 0.01
    ./replace_variable.csh $galform_inputs_file stabledisk 0.75
    ./replace_variable.csh $galform_inputs_file epsilon_SMBH_Eddington 0.01
    ./replace_variable.csh $galform_inputs_file alpha_cool 0.87


else if( $model == gp17.spin.ramt0.01.e01.ac06) then 
    # GALFORM input parameters file for base model/run
    set base_inputs_file = Gonzalez18_Nbody_MillGas.input.ref
    # make copy of base input parameters file
    cp $base_inputs_file $galform_inputs_file
    # set default values of dust parameters for post-processing
    source dustpars_Baugh05.csh

    ./replace_variable.csh $galform_inputs_file SMBH_accretion_spinup 2
    ./replace_variable.csh $galform_inputs_file SMBH_Mseed 10.
    ./replace_variable.csh $galform_inputs_file RamPressure_Transfer_Fraction 0.01
    ./replace_variable.csh $galform_inputs_file epsilon_SMBH_Eddington 0.01
    ./replace_variable.csh $galform_inputs_file alpha_cool 0.6


else if( $model == gp17.spin.ramt0.01.e01.fburst01) then 
    # GALFORM input parameters file for base model/run
    set base_inputs_file = Gonzalez18_Nbody_MillGas.input.ref
    # make copy of base input parameters file
    cp $base_inputs_file $galform_inputs_file
    # set default values of dust parameters for post-processing
    source dustpars_Baugh05.csh

    ./replace_variable.csh $galform_inputs_file SMBH_accretion_spinup 2
    ./replace_variable.csh $galform_inputs_file SMBH_Mseed 10.
    ./replace_variable.csh $galform_inputs_file RamPressure_Transfer_Fraction 0.01
    ./replace_variable.csh $galform_inputs_file epsilon_SMBH_Eddington 0.01
    ./replace_variable.csh $galform_inputs_file fburst 0.01

else if( $model == gp18) then 
    # GALFORM input parameters file for base model/run
    set base_inputs_file = Gonzalez18_Nbody_MillGas.input.ref
    # make copy of base input parameters file
    cp $base_inputs_file $galform_inputs_file
    # set default values of dust parameters for post-processing
    source dustpars_Baugh05.csh

else if( $model == gp18.minfrac0) then 
    # GALFORM input parameters file for base model/run
    set base_inputs_file = Gonzalez18_Nbody_MillGas.input.ref
    # make copy of base input parameters file
    cp $base_inputs_file $galform_inputs_file
    # set default values of dust parameters for post-processing
    source dustpars_Baugh05.csh

else if( $model == gp18.e0p01.nominfrac.nodst) then 
    # GALFORM input parameters file for base model/run
    set base_inputs_file = Gonzalez18_Nbody_MillGas.input.ref
    # make copy of base input parameters file
    cp $base_inputs_file $galform_inputs_file
    # set default values of dust parameters for post-processing
    source dustpars_Baugh05.csh

    ./replace_variable.csh $galform_inputs_file RamPressure_Transfer_Fraction 0.01
    ./replace_variable.csh $galform_inputs_file stabledisk 0.

else if( $model == gp18.e0.nominfrac.nodst) then 
    # GALFORM input parameters file for base model/run
    set base_inputs_file = Gonzalez18_Nbody_MillGas.input.ref
    # make copy of base input parameters file
    cp $base_inputs_file $galform_inputs_file
    # set default values of dust parameters for post-processing
    source dustpars_Baugh05.csh

    ./replace_variable.csh $galform_inputs_file RamPressure_Transfer_Fraction 0.
    ./replace_variable.csh $galform_inputs_file stabledisk 0.

else if( $model == gp19.starvation) then 
    # GALFORM input parameters file for base model/run
    set base_inputs_file = Gonzalez19_Nbody_MillGas.input.ref
    # make copy of base input parameters file
    cp $base_inputs_file $galform_inputs_file
    # set default values of dust parameters for post-processing
    source dustpars_Baugh05.csh

    ./replace_variable.csh $galform_inputs_file starvation .true.
    ./delete_variable.csh $galform_inputs_file RamPressure_Strip
    ./delete_variable.csh $galform_inputs_file RamPressure_Transfer_Fraction
    ./delete_variable.csh $galform_inputs_file Reheat_Min_Fraction

else if( $model == gp19.font) then 
    # GALFORM input parameters file for base model/run
    set base_inputs_file = Gonzalez19_Nbody_MillGas.input.ref
    # make copy of base input parameters file
    cp $base_inputs_file $galform_inputs_file
    # set default values of dust parameters for post-processing
    source dustpars_Baugh05.csh

    ./replace_variable.csh $galform_inputs_file RamPressure_Transfer_Fraction 0.1

else if( $model == gp17.spin.ramt0.01.griffinBH) then 
    # GALFORM input parameters file for base model/run
    set base_inputs_file = Gonzalez18_Nbody_MillGas.input.ref
    # make copy of base input parameters file
    cp $base_inputs_file $galform_inputs_file
    # set default values of dust parameters for post-processing
    source dustpars_Baugh05.csh

    ./replace_variable.csh $galform_inputs_file SMBH_accretion_spinup 2
    ./replace_variable.csh $galform_inputs_file SMBH_Mseed 10.
    ./replace_variable.csh $galform_inputs_file RamPressure_Transfer_Fraction 0.01
    ./replace_variable.csh $galform_inputs_file epsilon_SMBH_Eddington 0.01
    ./replace_variable.csh $galform_inputs_file SMBH_Heating_Efficiency 0.02
    ./replace_variable.csh $galform_inputs_file alpha_cool 0.8

else if( $model == gp17.spin.ramt0.01.griffinBH.stb075) then 
    # GALFORM input parameters file for base model/run
    set base_inputs_file = Gonzalez18_Nbody_MillGas.input.ref
    # make copy of base input parameters file
    cp $base_inputs_file $galform_inputs_file
    # set default values of dust parameters for post-processing
    source dustpars_Baugh05.csh

    ./replace_variable.csh $galform_inputs_file SMBH_accretion_spinup 2
    ./replace_variable.csh $galform_inputs_file SMBH_Mseed 10.
    ./replace_variable.csh $galform_inputs_file RamPressure_Transfer_Fraction 0.01
    ./replace_variable.csh $galform_inputs_file epsilon_SMBH_Eddington 0.01
    ./replace_variable.csh $galform_inputs_file SMBH_Heating_Efficiency 0.02
    ./replace_variable.csh $galform_inputs_file alpha_cool 0.8
    ./replace_variable.csh $galform_inputs_file stabledisk 0.75

else if( $model == gp17.spin.ramt0.01.griffinBH) then 
    # GALFORM input parameters file for base model/run
    set base_inputs_file = Gonzalez18_Nbody_MillGas.input.ref
    # make copy of base input parameters file
    cp $base_inputs_file $galform_inputs_file
    # set default values of dust parameters for post-processing
    source dustpars_Baugh05.csh

    ./replace_variable.csh $galform_inputs_file SMBH_accretion_spinup 2
    ./replace_variable.csh $galform_inputs_file SMBH_Mseed 10.
    ./replace_variable.csh $galform_inputs_file RamPressure_Transfer_Fraction 0.01
    ./replace_variable.csh $galform_inputs_file epsilon_SMBH_Eddington 0.01
    ./replace_variable.csh $galform_inputs_file SMBH_Heating_Efficiency 0.02
    ./replace_variable.csh $galform_inputs_file alpha_cool 0.8


else if( $model == gp17.spin.ramt0.01.griffin) then 
    # GALFORM input parameters file for base model/run
    set base_inputs_file = Gonzalez18_Nbody_MillGas.input.ref
    # make copy of base input parameters file
    cp $base_inputs_file $galform_inputs_file
    # set default values of dust parameters for post-processing
    source dustpars_Baugh05.csh

    ./replace_variable.csh $galform_inputs_file SMBH_accretion_spinup 2
    ./replace_variable.csh $galform_inputs_file SMBH_Mseed 10.
    ./replace_variable.csh $galform_inputs_file RamPressure_Transfer_Fraction 0.01
    ./replace_variable.csh $galform_inputs_file alpha_reheat 1.0
    ./replace_variable.csh $galform_inputs_file alphahot 3.4
    ./replace_variable.csh $galform_inputs_file nu_sf 0.74
    ./replace_variable.csh $galform_inputs_file vhotdisk 320
    ./replace_variable.csh $galform_inputs_file vhotburst 320
    ./replace_variable.csh $galform_inputs_file epsilon_SMBH_Eddington 0.01
    ./replace_variable.csh $galform_inputs_file SMBH_Heating_Efficiency 0.02
    ./replace_variable.csh $galform_inputs_file alpha_cool 0.8
    ./replace_variable.csh $galform_inputs_file tau0mrg 1.0
    ./replace_variable.csh $galform_inputs_file fburst  0.05
    ./replace_variable.csh $galform_inputs_file stabledisk 0.9
    ./replace_variable.csh $galform_inputs_file fdyn 20
    ./replace_variable.csh $galform_inputs_file tau_star_min_burst 0.1


else if( $model == gp17.spin.ramt0.01.ac085) then 
    # GALFORM input parameters file for base model/run
    set base_inputs_file = Gonzalez18_Nbody_MillGas.input.ref
    # make copy of base input parameters file
    cp $base_inputs_file $galform_inputs_file
    # set default values of dust parameters for post-processing
    source dustpars_Baugh05.csh

    ./replace_variable.csh $galform_inputs_file SMBH_accretion_spinup 2
    ./replace_variable.csh $galform_inputs_file SMBH_Mseed 10.
    ./replace_variable.csh $galform_inputs_file RamPressure_Transfer_Fraction 0.01
    ./replace_variable.csh $galform_inputs_file alpha_cool 0.85

else if( $model == gp17.spin.ramt0.01.ac07) then 
    # GALFORM input parameters file for base model/run
    set base_inputs_file = Gonzalez18_Nbody_MillGas.input.ref
    # make copy of base input parameters file
    cp $base_inputs_file $galform_inputs_file
    # set default values of dust parameters for post-processing
    source dustpars_Baugh05.csh

    ./replace_variable.csh $galform_inputs_file SMBH_accretion_spinup 2
    ./replace_variable.csh $galform_inputs_file SMBH_Mseed 10.
    ./replace_variable.csh $galform_inputs_file RamPressure_Transfer_Fraction 0.01
    ./replace_variable.csh $galform_inputs_file alpha_cool 0.7


else if( $model == gp17.spin.ramt0.01.ac08) then 
    # GALFORM input parameters file for base model/run
    set base_inputs_file = Gonzalez18_Nbody_MillGas.input.ref
    # make copy of base input parameters file
    cp $base_inputs_file $galform_inputs_file
    # set default values of dust parameters for post-processing
    source dustpars_Baugh05.csh

    ./replace_variable.csh $galform_inputs_file SMBH_accretion_spinup 2
    ./replace_variable.csh $galform_inputs_file SMBH_Mseed 10.
    ./replace_variable.csh $galform_inputs_file RamPressure_Transfer_Fraction 0.01
    ./replace_variable.csh $galform_inputs_file alpha_cool 0.8

else if( $model == gp17.noagnfb) then 
    # GALFORM input parameters file for base model/run
    set base_inputs_file = Gonzalez18_Nbody_MillGas.input.ref
    # make copy of base input parameters file
    cp $base_inputs_file $galform_inputs_file
    # set default values of dust parameters for post-processing
    source dustpars_Baugh05.csh

    ./replace_variable.csh $galform_inputs_file epsilon_SMBH_Eddington 0

else if( $model == gp17.spin.noagnfb) then 
    # GALFORM input parameters file for base model/run
    set base_inputs_file = Gonzalez18_Nbody_MillGas.input.ref
    # make copy of base input parameters file
    cp $base_inputs_file $galform_inputs_file
    # set default values of dust parameters for post-processing
    source dustpars_Baugh05.csh

    ./replace_variable.csh $galform_inputs_file SMBH_accretion_spinup 2
    ./replace_variable.csh $galform_inputs_file SMBH_Mseed 10.

    ./replace_variable.csh $galform_inputs_file epsilon_SMBH_Eddington 0

else if( $model == gp17.stb) then 
    # GALFORM input parameters file for base model/run
    set base_inputs_file = Gonzalez18_Nbody_MillGas.input.ref
    # make copy of base input parameters file
    cp $base_inputs_file $galform_inputs_file
    # set default values of dust parameters for post-processing
    source dustpars_Baugh05.csh

    ./replace_variable.csh $galform_inputs_file stabledisk 0

else if( $model == gp17.spin.stb) then 
    # GALFORM input parameters file for base model/run
    set base_inputs_file = Gonzalez18_Nbody_MillGas.input.ref
    # make copy of base input parameters file
    cp $base_inputs_file $galform_inputs_file
    # set default values of dust parameters for post-processing
    source dustpars_Baugh05.csh

    ./replace_variable.csh $galform_inputs_file SMBH_accretion_spinup 2
    ./replace_variable.csh $galform_inputs_file SMBH_Mseed 10.

    ./replace_variable.csh $galform_inputs_file stabledisk 0


else if( $model == gp17.noagnfb.stb) then 
    # GALFORM input parameters file for base model/run
    set base_inputs_file = Gonzalez18_Nbody_MillGas.input.ref
    # make copy of base input parameters file
    cp $base_inputs_file $galform_inputs_file
    # set default values of dust parameters for post-processing
    source dustpars_Baugh05.csh

    ./replace_variable.csh $galform_inputs_file epsilon_SMBH_Eddington 0

    ./replace_variable.csh $galform_inputs_file stabledisk 0

else if( $model == gp17.spin.noagnfb.stb) then 
    # GALFORM input parameters file for base model/run
    set base_inputs_file = Gonzalez18_Nbody_MillGas.input.ref
    # make copy of base input parameters file
    cp $base_inputs_file $galform_inputs_file
    # set default values of dust parameters for post-processing
    source dustpars_Baugh05.csh

    ./replace_variable.csh $galform_inputs_file SMBH_accretion_spinup 2
    ./replace_variable.csh $galform_inputs_file SMBH_Mseed 10.

    ./replace_variable.csh $galform_inputs_file epsilon_SMBH_Eddington 0

    ./replace_variable.csh $galform_inputs_file stabledisk 0

else if( $model == gp15newmg.anders) then
    # GALFORM input parameters file for base model/run
    set base_inputs_file = Gonzalez15_newmg_Nbody_MillGas.input.ref
    # make copy of base input parameters file
    cp $base_inputs_file $galform_inputs_file
    # set default values of dust parameters for post-processing
    source dustpars_Baugh05.csh

    ./replace_variable.csh $galform_inputs_file emlinefile Data/emlines_anders_fritze_2003.data 


else if( $model == gp15newmg.cmb) then
    # GALFORM input parameters file for base model/run
    set base_inputs_file = Gonzalez15_newmg_Nbody_MillGas.input.ref
    # make copy of base input parameters file
    cp $base_inputs_file $galform_inputs_file
    # set default values of dust parameters for post-processing
    source dustpars_Baugh05.csh

    ./replace_variable.csh $galform_inputs_file alpha_cool 0.61
    ./replace_variable.csh $galform_inputs_file vhotdisk 380
    ./replace_variable.csh $galform_inputs_file vhotburst 380

else if( $model == gp15newmg.mgalmin0) then
    # GALFORM input parameters file for base model/run
    set base_inputs_file = Gonzalez18_newmg_Nbody_MillGas.input.ref
    # make copy of base input parameters file
    cp $base_inputs_file $galform_inputs_file
    # set default values of dust parameters for post-processing
    source dustpars_Baugh05.csh

    ./replace_variable.csh $galform_inputs_file mgalmin 0.0

else if( $model == gp15newmg.iseed51027) then
    # GALFORM input parameters file for base model/run
    set base_inputs_file = Gonzalez15_newmg_Nbody_MillGas.input.ref
    # make copy of base input parameters file
    cp $base_inputs_file $galform_inputs_file
    # set default values of dust parameters for post-processing
    source dustpars_Baugh05.csh

    set ISEED2 = -51027
    ./replace_variable.csh $galform_inputs_file ISEED -234987

else if( $model == gp15newmg.r577) then
    # GALFORM input parameters file for base model/run
    set base_inputs_file = Gonzalez15_newmg_Nbody_MillGas.input.ref
    # make copy of base input parameters file
    cp $base_inputs_file $galform_inputs_file
    # set default values of dust parameters for post-processing
    source dustpars_Baugh05.csh

    ./delete_variable.csh $galform_inputs_file SMBH_spinup
    ./delete_variable.csh $galform_inputs_file SMBH_Mseed


else if( $model == gp15newmg.r509) then
    # GALFORM input parameters file for base model/run
    set base_inputs_file = Gonzalez15_newmg_Nbody_MillGas.input.ref
    # make copy of base input parameters file
    cp $base_inputs_file $galform_inputs_file
    # set default values of dust parameters for post-processing
    source dustpars_Baugh05.csh

    ./delete_variable.csh $galform_inputs_file SMBH_spinup
    ./delete_variable.csh $galform_inputs_file SMBH_Mseed
    ./delete_variable.csh $galform_inputs_file Outputs_Per_Pass

else if( $model == gp15newmg.spin) then
    # GALFORM input parameters file for base model/run
    set base_inputs_file = Gonzalez15_newmg_Nbody_MillGas.input.ref
    # make copy of base input parameters file
    cp $base_inputs_file $galform_inputs_file
    # set default values of dust parameters for post-processing
    source dustpars_Baugh05.csh

    ./replace_variable.csh $galform_inputs_file SMBH_spinup 1
    ./replace_variable.csh $galform_inputs_file SMBH_Mseed 10.

else if( $model == gp15newmg.test) then
    # GALFORM input parameters file for base model/run
    set base_inputs_file = Gonzalez15_newmg_Nbody_MillGas.input.ref
    # make copy of base input parameters file
    cp $base_inputs_file $galform_inputs_file
    # set default values of dust parameters for post-processing
    source dustpars_Baugh05.csh


else if( $model == gp15newmg.ac095 ) then
    # GALFORM input parameters file for base model/run
    set base_inputs_file = Gonzalez15_newmg_Nbody_MillGas.input.ref
    # make copy of base input parameters file
    cp $base_inputs_file $galform_inputs_file
    # set default values of dust parameters for post-processing
    source dustpars_Baugh05.csh

    ./replace_variable.csh $galform_inputs_file alpha_cool 0.95

else if( $model == gp15newmg.stb07 ) then
    # GALFORM input parameters file for base model/run
    set base_inputs_file = Gonzalez15_newmg_Nbody_MillGas.input.ref
    # make copy of base input parameters file
    cp $base_inputs_file $galform_inputs_file
    # set default values of dust parameters for post-processing
    source dustpars_Baugh05.csh

    ./replace_variable.csh $galform_inputs_file stabledisk 0.7


else if( $model == gp15newmg.stb075 ) then
    # GALFORM input parameters file for base model/run
    set base_inputs_file = Gonzalez15_newmg_Nbody_MillGas.input.ref
    # make copy of base input parameters file
    cp $base_inputs_file $galform_inputs_file
    # set default values of dust parameters for post-processing
    source dustpars_Baugh05.csh

    ./replace_variable.csh $galform_inputs_file stabledisk 0.75


else if( $model == gp15.newmg.vh370.ac09.ftq4.fsmbh01) then
    # GALFORM input parameters file for base model/run
    set base_inputs_file = Gonzalez15_newmg_Nbody_L800.input.ref
    # make copy of base input parameters file
    cp $base_inputs_file $galform_inputs_file
    # set default values of dust parameters for post-processing
    source dustpars_Baugh05.csh

    ./replace_variable.csh $galform_inputs_file alpha_cool 0.9
    ./replace_variable.csh $galform_inputs_file vhotdisk 370.
    ./replace_variable.csh $galform_inputs_file vhotburst 370.
    ./replace_variable.csh $galform_inputs_file SMBH_ftq 4.
    ./replace_variable.csh $galform_inputs_file F_SMBH 0.01


else if( $model == gp15.newmg.ac052) then
    # GALFORM input parameters file for base model/run
    set base_inputs_file = Gonzalez15_newmg_Nbody_L800.input.ref
    # make copy of base input parameters file
    cp $base_inputs_file $galform_inputs_file
    # set default values of dust parameters for post-processing
    source dustpars_Baugh05.csh

    ./replace_variable.csh $galform_inputs_file alpha_cool 0.52
#####################################

else if( $model == gp14.mhalo10) then
    # GALFORM input parameters file for base model/run
    set base_inputs_file = Gonzalez13_Nbody_MillGas.input.ref
    # make copy of base input parameters file
    cp $base_inputs_file $galform_inputs_file
    # set default values of dust parameters for post-processing
    source dustpars_Baugh05.csh

    ./replace_variable.csh $galform_inputs_file min_halo_mass 1.87000E+10
    
else
   echo ERROR IN SCRIPT: model $model not recognized!
   exit 1
endif

###########################################################################
# Pass location of stellar_pop dir to the input file, if set above
if ( $?stellar_pop_dir ) then
    ./replace_variable.csh $galform_inputs_file stellar_pop_dir ${stellar_pop_dir}
endif

############################################################################ 
#### re-set ISEED for 'problematic' snapshots
#### -> luminosity convergence in solve_star_formation for burst
############################################################################
if ( $model == lc16.newmg && $Nbody_sim == L800 ) then
    if ( $iz == 207 ) then
        set ISEED = -356982
        ./replace_variable.csh $galform_inputs_file ISEED $ISEED
    endif 
endif

####################################################################
# parameters for luminosities 

# choose photometric bands to output
# see file Data/filters/filters_XXX.dat for details of filters
# include bands B0-C4 for computing dust emission
# include NLyc (rest-frame) for calculating emission lines
# include SM (stellar mass after recycling) for computing mass-weighted age & metallicity

#Reduce bands for ssp test-------------------------------------
# band          A2  UA  V age_V Z_V Bj J  H  K  UJ  UH  UK  Lbol NLyc  SM   age_SM B0  B1  B2  B3  B4  B5  B6  B7  B8  B9  C0  C1  C2  C3  C4
set idband =  (170 200 52   52  52   6 47 48 49 298 299 300 1001 1002  1005 1005 185 186 187 188 189 190 191 192 193 194 195 196 197 198 199)
# select whether rest-frame (0), observer-frame (1), lum-weighted age (2), 
# lum-weighted metallicity (3), lum-weighted Vc (4)
set iselect = (0   0   0    2    3   0  0  0  0   0   0   0   0    0    0    2    0   0   0   0   0   0   0   0   0   0   0   0   0   0   0 )
#End reduce bands for ssp test---------------------------------

if ($samp_z0 == 'true' || $lum_fun == 'true' || $sedfit == 'true') then
    if ( $elgs == 'true') then
	echo 'Setting bands adequate for standard plots and ELG tests'
	# band         1500A 2800A  U   B  V  R  I  J  H  K   bJ  u   g   r   i   z    uz  gz  rz iz  zz   age_V Z_V  Lbol NLyc  SM   age_SM  B0  B1  B2  B3  B4  B5  B6  B7  B8  B9  C0  C1 C2  C3  C4   iA  zA  SL  SM  S5  S8 GN GF u   g   r   i   z    uz  gz  rz iz  zz SL SM S5 S8 Du Dg Dr Di Dz DY cu cg cr ci cz m1 m2 m3 BK IK RK ZK W1 W2 
	set idband =  (200   201    127 51 52 53 54 47 48 49  6   202 203 204 205 206  212 213 214 215 216  52    52   1001 1002  1005 1005 351 351 351   185 186 187 188 189 190 191 192 193 194 195 196 197 198 199  232 233 164 165 166 167 294 295 297 294 295 297 200   201    127 51 52 53 54 47 48 49  6   202 203 204 205 206  212 213 214 215 216 164 165 166 167 419 350 351 352 353 354 428 429 430 431 432 433 434 435 436 437 438 439 413 414)
	# select whether rest-frame (0), observer-frame (1), lum-weighted age (2),
	# lum-weighted metallicity (3), lum-weighted Vc (4)
	set iselect = (0     0      0   0  0  0  0  0  0  0   0   0   0   0   0   0    0   0   0  0   0    2     3    0    0     0    2   0 2  3    0   0   0   0   0   0   0   0   0   0   0   0  0   0   0    1   1   1   1   1   1 0  0  0  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1 1  1  1  1  1 0  0  0  0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 )

    else 
	echo 'Setting bands adequate for standard plots'
	# band         1500A 2800A  U   B  V  R  I  J  H  K   bJ  u   g   r   i   z    uz  gz  rz iz  zz   age_V Z_V  Lbol NLyc  SM   age_SM  B0  B1  B2  B3  B4  B5  B6  B7  B8  B9  C0  C1 C2  C3  C4   iA  zA  SL  SM  S5  S8 GN GF u   g   r   i   z    uz  gz  rz iz  zz SL SM S5 S8
	set idband =  (200   201    127 51 52 53 54 47 48 49  6   202 203 204 205 206  212 213 214 215 216  52    52   1001 1002  1005 1005    185 186 187 188 189 190 191 192 193 194 195 196 197 198 199  232 233 164 165 166 167 294 295 297 294 295 297 200   201    127 51 52 53 54 47 48 49  6   202 203 204 205 206  212 213 214 215 216 164 165 166 167 )
	# select whether rest-frame (0), observer-frame (1), lum-weighted age (2),
	# lum-weighted metallicity (3), lum-weighted Vc (4)
	set iselect = (0     0      0   0  0  0  0  0  0  0   0   0   0   0   0   0    0   0   0  0   0    2     3    0    0     0    2       0   0   0   0   0   0   0   0   0   0   0   0  0   0   0    1   1   1   1   1   1 0  0  0  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1 1  1  1  1  1 0  0  0  0 )
    endif
else if ( $elgs == 'true' ) then
	echo 'Setting bands adequate for ELG project using VVDS and DEEP2 data'
	# band     V    age_V Z_V  Lbol NLyc SM age_SM 1500A 2800A  U  GN GF u   g   r   i   z  Du Dg Dr Di Dz DY cu cg cr ci cz m1 m2 m3 BK IK RK  ZK age_Dr Z_Dr
	set idband =  (52  52    52   1001 1002 1005 1005 200   201    127  49  6   202 203 204 205 206 419 350 351 352 353 354 428 429 430 431 432 433 434 435 436 437 438 439 351 351 351)
	# select whether rest-frame (0), observer-frame (1), lum-weighted age (2),
	# lum-weighted metallicity (3), lum-weighted Vc (4)
	set iselect = (0   2     3    0    0 0  2  0     0      0    0  0  1   1   1   1   1  1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 2 3)
	
else if ( $elliott == 'true' ) then
	if ( $iz == 128 ) then # z=0 all Elliott calibration plots
	    echo 'Setting bands adequate'
	    # band         K    B   I  bJ  r    K    B   I  bJ  r    V   Z_V
	    set idband =  (49  51  54  6  204  49  51  54    6  204  52   52)
	    # select whether rest-frame (0), observer-frame (1), lum-weighted age (2),
	    # lum-weighted metallicity (3), lum-weighted Vc (4)
	    set iselect = (0   0   0     0   0   1   1   1    1   1   0   3)
	else if ( $iz == 95 ) then # z=1.1 only K LF
	    echo 'Setting bands adequate'
	    # band         K   K
	    set idband =  (49 49)
	    # select whether rest-frame (0), observer-frame (1), lum-weighted age (2),
	    # lum-weighted metallicity (3), lum-weighted Vc (4)
	    set iselect = (0  1)

else if ( $K_Bj == 'true' ) then
	echo 'Setting bands adequate'
        # band         K   bJ  K  bJ 
	set idband =  (49  6  49  6 )
	# select whether rest-frame (0), observer-frame (1), lum-weighted age (2),
	# lum-weighted metallicity (3), lum-weighted Vc (4)
	set iselect = (0   0   1   1 )

endif


# count no of bands
set nband = `echo $idband | wc -w`
# modify input file for chosen bands
./replace_vector.csh $galform_inputs_file idband $idband
./replace_vector.csh $galform_inputs_file iselect $iselect

## HII region emission lines
#
## turn on emission lines calcn
#./replace_variable.csh $galform_inputs_file emlines .true.
## choose which emission lines to calculate
#set lines = (Lyalpha Halpha Hbeta OII3727 OIII5007 NII6583 SII6716 )
## count number of lines
#set nline = `echo $lines | wc -w`
#./replace_variable.csh $galform_inputs_file nline $nline
#./replace_vector.csh $galform_inputs_file lines $lines

#################################################################
# parameters specific to Nbody run

# turn on ivolume argument to galform2.exe
./replace_variable.csh $galform_inputs_file append_ivolume .true.
## filenames for N-body run
./replace_variable.csh $galform_inputs_file aquarius_tree_file $aquarius_tree_file


if($Nbody_sim != UNIT100 && $Nbody_sim != UNIT200 && $Nbody_sim != UNIT) then
    ./replace_variable.csh $galform_inputs_file aquarius_particle_file $aquarius_particle_file
else
    ./delete_variable.csh $galform_inputs_file aquarius_particle_file # if you don't have particle files
endif

## subvolumes
#if( $volume_file == 0 ) then
#    ./delete_variable.csh $galform_inputs_file volume_file
#else
#    ./replace_variable.csh $galform_inputs_file volume_file $volume_file
#endif
./replace_variable.csh $galform_inputs_file volume $volume
## simulation parameters
#./replace_variable.csh $galform_inputs_file lbox $lbox
#./replace_variable.csh $galform_inputs_file mpart $mpart
# cosmology
./replace_variable.csh $galform_inputs_file omega0 $omega0
./replace_variable.csh $galform_inputs_file lambda0 $lambda0
./replace_variable.csh $galform_inputs_file omegab $omegab
./replace_variable.csh $galform_inputs_file h0 $h0
# power spectrum
./replace_variable.csh $galform_inputs_file sigma8 $sigma8
./replace_variable.csh $galform_inputs_file itrans -1
./replace_variable.csh $galform_inputs_file PKfile $PKfile

# modify parameters specific to this redshift
./replace_vector.csh $galform_inputs_file zout $z

############################################################################
# RUN GALFORM  using input parameters file constructed above

if( $galform == true ) then
    echo '******************************************************************'
    echo running GALFORM
    $GALFORM2_EXE $output_dir $galform_inputs_file  -ivolume=$ivol

    # Abort if global file was not produced or exit status was non-zero
    if (( $status != 0 ) || ! ( -e ${output_dir}/global )) then
        echo
        echo Galform run failed, aborting script
        echo
        exit
    endif

endif

############################################################################
############################################################################
# CREATE ETA FILES  for extinction by dust clouds

if( $neta == true ) then
    echo '******************************************************************'
    echo running NETA_AVE

# write a file in output directory with values of dust parameters used in 
# post-processing
    set dustparfile = $output_dir/dustpars
    echo dustfile = $dustfile      >! $dustparfile
    echo emdustfile = $emdustfile  >> $dustparfile
    echo rfacburst = $rfacburst    >> $dustparfile
    echo fcloud = $fcloud          >> $dustparfile
    echo tesc_disk = $tesc_disk    >> $dustparfile
    echo tesc_burst = $tesc_burst  >> $dustparfile
    echo upsilon2 = $upsilon2      >> $dustparfile
    echo lambda_break_disk = $lambda_break_disk    >> $dustparfile
    echo beta2_disk = $beta2_disk      >> $dustparfile
    echo lambda_break_burst = $lambda_break_burst  >> $dustparfile
    echo beta2_burst = $beta2_burst    >> $dustparfile

# calc eta_disk file
    $NETA_AVE_DISK_EXE <<EOF
    $output_dir
    $tesc_disk
    1
EOF
#
# calc eta_burst file
    $NETA_AVE_BURST_EXE <<EOF
    $output_dir
    $tesc_burst
    1
EOF

endif

#############################################################################
# SAMPLE GALS PROPERTIES 
if ( $dust_props == 'true' ) then

    echo 'run SAMPLE_GALS to output dust properties in hdf5'
    echo 'removing existing file samp_dust.hdf5'
    /bin/rm -f $output_dir/samp_dust.hdf5

    set dust_props = (Ldust Ldust_clouds Ldust_diff Tdust_clouds Tdust_diff)
    @ ii = 0
    set th_bands = ()
    while ($ii < 15)
        set th_bands = ($th_bands mag_TH${ii}_r_tot  mag_TH${ii}_r_tot_ext)
        @ ii ++
    end

    set SDSS_bands = ()
    foreach band (u g r i z)
        set SDSS_bands = ($SDSS_bands mag_SDSS-${band}_o_tot_ext mag_SDSS-${band}_o_tot)
    end

    set NIRCam_bands = ()
    foreach band (1 2 3 4 5 6 7 8)
        set NIRCam_bands = ($NIRCam_bands mag_N${band}_o_tot mag_N${band}_o_tot_ext)
    end

    set IRAC_bands = ()
    foreach band (3.6 4.5 5.8 8.0)
        set IRAC_bands = ($IRAC_bands mag_IRAC-${band}_o_tot_ext)
    end

    $SAMPLE_GALS_EXE odir $output_dir iseed $ISEED2 \
	file $output_dir/samp_dust.hdf5 format hdf5  redshift $z \
    mag_sys AB  volume 0  upsilon $upsilon2 \
    dust $dustfile $emdustfile $rfacburst $fcloud $tesc_disk $tesc_burst \
    dust_SED $lambda_break_disk $beta2_disk $lambda_break_burst $beta2_burst \
    props $dust_props $th_bands $SDSS_bands $NIRCam_bands Ld_850_o BoT \
	jm jtree ident mstars_tot age_SM_tot
    echo 'completed dust properties'

endif 

# CALCULATE LUMINOSITY FUNCTIONS
if ( $lum_fun == 'true' ) then 
    echo '******************************************************************'
    echo running LUM_FUN

# output AB magnitudes
    set lffile = $output_dir/gal

    $SAMPLE_GALS_EXE  odir $output_dir  iseed $ISEED2  file $lffile redshift $z \
    mag_sys AB  volume 0  upsilon $upsilon2 \
    dust $dustfile $emdustfile $rfacburst $fcloud $tesc_disk $tesc_burst \
    dust_SED $lambda_break_disk $beta2_disk $lambda_break_burst $beta2_burst \
    dustem 24r 24o 60r 60o 100r 100o 160r 160o 250r 250o 350r 350o 500r 500o 850r 850o 870r 870o \
    lum_fun

# output optical LFs in Vega mags also
    set lffile = $output_dir/gal.Vega

    $SAMPLE_GALS_EXE  odir $output_dir  iseed $ISEED2  file $lffile  redshift $z \
    mag_sys vega  volume 0  upsilon $upsilon2 \
    dust $dustfile $emdustfile $rfacburst $fcloud $tesc_disk $tesc_burst \
    lum_fun

endif

#############################################################################
## LFs for bursting galaxies

if ( $lum_fun_burst == true ) then 
    echo '******************************************************************'
    echo running LUM_FUN_burst

# output AB magnitudes

# LF of quiescent galaxies
    set lffile = $output_dir/quiescent

    $SAMPLE_GALS_EXE  odir $output_dir  iseed $ISEED2 file $lffile  redshift $z \
    mag_sys AB  volume 0  upsilon $upsilon2 \
    dust $dustfile $emdustfile $rfacburst $fcloud $tesc_disk $tesc_burst \
    dust_SED $lambda_break_disk $beta2_disk $lambda_break_burst $beta2_burst \
    dustem 24r 24o 60r 60o 100r 100o 160r 160o 250r 250o 350r 350o 500r 500o 850r 850o 870r 870o \
    lum_fun \
    burstsel 0 0 0 

# LF of bursting galaxies
    set lffile = $output_dir/burst

    $SAMPLE_GALS_EXE  odir $output_dir  iseed $ISEED2 file $lffile  redshift $z \
    mag_sys AB  volume 0  upsilon $upsilon2 \
    dust $dustfile $emdustfile $rfacburst $fcloud $tesc_disk $tesc_burst \
    dust_SED $lambda_break_disk $beta2_disk $lambda_break_burst $beta2_burst \
    dustem 24r 24o 60r 60o 100r 100o 160r 160o 250r 250o 350r 350o 500r 500o 850r 850o 870r 870o \
    lum_fun \
    burstsel 1 0 0 

# output optical LFs in Vega mags also
# quiescent
    set lffile = $output_dir/quiescent.Vega

    $SAMPLE_GALS_EXE  odir $output_dir  iseed $ISEED2  file $lffile  redshift $z \
    mag_sys vega  volume 0  upsilon $upsilon2 \
    dust $dustfile $emdustfile $rfacburst $fcloud $tesc_disk $tesc_burst \
    lum_fun \
    burstsel 0 0 0

# burst
    set lffile = $output_dir/burst.Vega

    $SAMPLE_GALS_EXE  odir $output_dir  iseed $ISEED2  file $lffile  redshift $z \
    mag_sys vega  volume 0  upsilon $upsilon2 \
    dust $dustfile $emdustfile $rfacburst $fcloud $tesc_disk $tesc_burst \
    lum_fun \
    burstsel 1 0 0

endif


############################################################################
############################################################################
# EXTRACT SAMPLES of galaxies

if ( $samp_z0 == 'true' && $iz == $iz0) then 
# compute samples at z=0 for making standard plots
    echo '******************************************************************'
    echo running SAMPLE_GALS for z=0

# Tully-Fisher catalog (used by OLD plotting macros)
    echo creating file TF.cat
    set file = $output_dir/TF.cat
    set vol = 0  # output all galaxies 

    $SAMPLE_GALS_EXE  odir $output_dir  iseed $ISEED2  file $file  redshift 0 \
    mag_sys vega  volume 0  upsilon $upsilon2 \
    dust $dustfile $emdustfile $rfacburst $fcloud $tesc_disk $tesc_burst \
    range B/T_I_r_ext 0.02 0.24 \
    props  weight mag_I_r_tot_ext0 vdisk vhalo B/T_I_r_ext mcold mstars_disk is_central

# another Tully-Fisher catalog without selection on (B/T)_I
# (used by new plotting macros)
    echo creating file TF2.cat
    set file = $output_dir/TF2.cat
    set vol = 0  # output all galaxies 

    $SAMPLE_GALS_EXE  odir $output_dir  iseed $ISEED2  file $file  redshift 0 \
    mag_sys vega  volume 0  upsilon $upsilon2 \
    dust $dustfile $emdustfile $rfacburst $fcloud $tesc_disk $tesc_burst \
    range mag_I_r_tot_ext0 -100.0 -12.0 \
    props  weight mag_I_r_tot_ext0 vdisk vhalo B/T_B_r_ext mcold mstars_disk is_central


# Morphological mix
    echo creating file morph.cat
    set file = $output_dir/morph.cat
    set vol = 0  # output all galaxies 

    $SAMPLE_GALS_EXE  odir $output_dir  iseed $ISEED2  file $file  redshift 0 \
    mag_sys vega  volume 0  upsilon $upsilon2 \
    dust $dustfile $emdustfile $rfacburst $fcloud $tesc_disk $tesc_burst \
    range mag_B_r_tot_ext -100.0 -14.0 \
    props weight mag_B_r_tot_ext B/T_B_r_ext 

# Cold gas contents
    echo creating file gas_frac.cat
    set file = $output_dir/gas_frac.cat
    set vol = 0  # output all galaxies 

    $SAMPLE_GALS_EXE  odir $output_dir  iseed $ISEED2  file $file  redshift 0 \
    mag_sys vega  volume 0  upsilon $upsilon2 \
    dust $dustfile $emdustfile $rfacburst $fcloud $tesc_disk $tesc_burst \
    range mag_B_r_tot -100 -14 \
    props weight mag_B_r_tot_ext mag_B_r_tot_ext0 B/T_B_r_ext mag_V_r_tot_ext mag_UKIRT-K_r_tot_ext \
    mcold mstars_tot metals_cold metals_disk metals_bulge met_V_total \
    age_SM_total age_V_total

# Cold gas masses
    echo creating file gas.cat
    set file = $output_dir/gas.cat
    set vol = 0  # output all galaxies 

    $SAMPLE_GALS_EXE  odir $output_dir  iseed $ISEED2  file $file  redshift 0 \
    mag_sys vega  volume 0  upsilon $upsilon2 \
    dust $dustfile $emdustfile $rfacburst $fcloud $tesc_disk $tesc_burst \
    range mcold 1e7 1e14 \
    props weight mcold mstars_tot B/T \
    mag_B_r_tot_ext mag_B_r_tot_ext0 B/T_B_r_ext mag_V_r_tot_ext mag_UKIRT-K_r_tot_ext mag_UKIRT-K_r_tot_ext0 


# Galaxy mass catalogue
    echo creating file mass.cat
    set file = $output_dir/mass.cat
    set vol = 0  # output all galaxies

    $SAMPLE_GALS_EXE  odir $output_dir  iseed $ISEED2  file $file  redshift 0 \
    mag_sys vega  volume 0  upsilon $upsilon2 \
    dust $dustfile $emdustfile $rfacburst $fcloud $tesc_disk $tesc_burst \
    range is_central 0.5 1.5 \
    props weight mphalo vhalo mstars_tot mcold


# HI masses to create HI MF
    echo creating file mHI.cat
    set file = $output_dir/mHI.cat
    set vol = 0  # output all galaxies

    $SAMPLE_GALS_EXE odir $output_dir  iseed $ISEED2  file $file  redshift 0 \
    mag_sys AB  volume 0  upsilon $upsilon2 \
    range mcold 1e6 1e14 \
    props weight mcold mcold_mol


# Disk size distributions
    echo creating file size.cat
    set file = $output_dir/size.cat
    set vol = 0  # output all galaxies

    $SAMPLE_GALS_EXE  odir $output_dir  iseed $ISEED2  file $file  redshift 0 \
    mag_sys vega  volume 0  upsilon $upsilon2 \
    dust $dustfile $emdustfile $rfacburst $fcloud $tesc_disk $tesc_burst \
    range mag_I_r_tot -100 -18 \
    props weight mag_I_r_tot mag_I_r_tot_ext0 rdisk B/T_B_r B/T_B_r_ext B/T_I_r B/T_I_r_ext

# galaxy sizes & colours in SDSS
    echo creating file size_SDSS.cat
    set file = $output_dir/size_SDSS.cat
    set vol = 0  # output all galaxies

    $SAMPLE_GALS_EXE  odir $output_dir  iseed $ISEED2  file $file  redshift 0 \
    mag_sys AB  volume 0  upsilon $upsilon2 \
    dust $dustfile $emdustfile $rfacburst $fcloud $tesc_disk $tesc_burst \
    range mag_SDSS-r_r_tot -100 -15 \
    props weight mag_SDSS-r_r_tot mag_SDSS-r_r_tot_ext B/T_SDSS-r_r B/T_SDSS-r_r_ext \
    rcomb rdisk rbulge \
    mag_SDSS-u_r_tot mag_SDSS-u_r_tot_ext mag_SDSS-g_r_tot mag_SDSS-g_r_tot_ext \
    mag_SDSS-i_r_tot mag_SDSS-i_r_tot_ext mag_SDSS-z_r_tot mag_SDSS-z_r_tot_ext


# SMBH masses
    echo creating file SMBH.cat
    set file = $output_dir/SMBH.cat
    set vol = 0  # output all galaxies

    $SAMPLE_GALS_EXE  odir $output_dir  iseed $ISEED2  file $file  redshift 0 \
    mag_sys vega  volume 0  upsilon $upsilon2 \
    dust $dustfile $emdustfile $rfacburst $fcloud $tesc_disk $tesc_burst \
    range mstars_tot 1e8 1e30 \
    props weight  M_SMBH SMBH_Mdot_stb mstars_tot B/T mstars_bulge vbulge mhhalo vhhalo \
    mag_B_r_tot B/T_B_r mag_B_r_bulge mag_B_r_tot_ext B/T_B_r_ext mag_B_r_bulge_ext \
    mag_UKIRT-K_r_tot B/T_UKIRT-K_r mag_UKIRT-K_r_bulge mag_UKIRT-K_r_tot_ext \
    B/T_UKIRT-K_r_ext mag_UKIRT-K_r_bulge_ext \
    SMBH_tacc_stb SMBH_Mdot_hh


# gas metallicities
    echo creating file Zgas.cat
    set file = $output_dir/Zgas.cat
    set vol = 0  # output all galaxies

    $SAMPLE_GALS_EXE  odir $output_dir  iseed $ISEED2  file $file  redshift 0 \
    mag_sys AB  volume 0  upsilon $upsilon2 \
    dust $dustfile $emdustfile $rfacburst $fcloud $tesc_disk $tesc_burst \
    range mstars_tot 1e8 1e14 \
    props weight zcold zstar_tot mstars_tot B/T mcold mstardot vdisk vbulge vhalo \
    mag_SDSSz0.2-z_r_tot mag_SDSSz0.2-z_r_tot_ext B/T_SDSS-r_r B/T_SDSS-r_r_ext \
    mag_SDSSz0.1-g_r_tot_ext mag_SDSSz0.1-r_r_tot_ext \
    EW_tot_Hbeta EW_tot_Hbeta_ext


# stellar metallicities & ages
    echo creating file Zstar.cat
    set file = $output_dir/Zstar.cat
    set vol = 0  # output all galaxies

    $SAMPLE_GALS_EXE  odir $output_dir  iseed $ISEED2  file $file  redshift 0 \
    mag_sys vega  volume 0  upsilon $upsilon2 \
    dust $dustfile $emdustfile $rfacburst $fcloud $tesc_disk $tesc_burst \
    range mstars_tot 1e8 1e14 \
    props weight zcold zstar_tot mstars_tot B/T mcold mstardot vdisk vbulge vhalo mhhalo \
    met_V_total age_SM_total age_V_total \
    mag_R_r_tot mag_R_r_tot_ext B/T_R_r B/T_R_r_ext B/T_B_r B/T_B_r_ext \
    EW_tot_Halpha EW_tot_Halpha_ext \
    rdisk rbulge 

endif

############################################################################
# EXTRACT MAH AND NFW PROPERTIES

if ( $samp_mah == 'true' ) then 
# compute samples at a set of redshifts for making MAH & NFW plots
    echo '******************************************************************'
    echo running SAMPLE_GALS for z=$z

# MAH and NFW  concentration parameter for z=0
    echo creating file mah-z$z.cat
    set file = $output_dir/mah-z$z.cat
    set vol = 0  # output all galaxies

    $SAMPLE_GALS_EXE  odir $output_dir  iseed $ISEED2  file $file  redshift $z \
    mag_sys vega  volume 0  upsilon $upsilon2 \
    dust $dustfile $emdustfile $rfacburst $fcloud $tesc_disk $tesc_burst \
    range mstars_tot 1e8 1e30 \
    props mhalo mphalo mhhalo mchalo anfw aform mhot mcold mstars_tot is_central

    # link files for easy plotting
    mkdir -p $model_dir/plots
    if ( ! ( -e $model_dir/plots/mah-z$z.cat ) ) then
	ln -s $file $model_dir/plots/mah-z$z.cat
    endif

endif

############################################################################

if ( $samp2_z0 == 'true' && $iz == $iz0 ) then 
# compute samples at z=0 for making non-standard plots
    echo '******************************************************************'
    echo running SAMPLE_GALS for z=0
#
# galaxy sizes in SDSS
    echo creating file size2_SDSS.cat
    set file = $output_dir/size2_SDSS.cat
    set vol = 0  # output all galaxies

    $SAMPLE_GALS_EXE  odir $output_dir  iseed $ISEED2  file $file  redshift 0 \
    mag_sys AB  volume 0  upsilon $upsilon2 \
    dust $dustfile $emdustfile $rfacburst $fcloud $tesc_disk $tesc_burst \
    range mag_SDSS-r_r_tot -100 -15 \
    props weight mag_SDSS-r_r_tot mag_SDSS-r_r_tot_ext B/T_SDSS-r_r B/T_SDSS-r_r_ext rcomb rdisk rbulge \
    is_central mhhalo vhhalo mhalo vhalo spin JDM Jdisk \
    mstars_disk mcold mstars_bulge vdisk vbulge
endif

############################################################################

if ( $sedfit == 'true') then 
# compute samples at z=0 for making standard plots
    echo '******************************************************************'
    echo running SAMPLE_GALS for SED fitting and GAMA plots

    set file = $output_dir/tosedfit.hdf5
    if (-e $file) then
	rm -f $file
    endif
    set vol = 0  # output all galaxies 

    $SAMPLE_GALS_EXE  odir $output_dir  iseed $ISEED2   format hdf5 file $file  redshift $z \
    mag_sys AB  volume 0  upsilon $upsilon2 \
    dust $dustfile $emdustfile $rfacburst $fcloud $tesc_disk $tesc_burst \
    range mstars_tot 1e3 1e14 \
    props  weight type mstars_tot mchalo mhhalo mstardot  mstardot_burst \
	age_V_total met_V_total age_SM_total \
	mag_GALEX-FUV_o_tot_ext mag_GALEX-NUV_o_tot_ext \
	mag_TH1500_o_tot_ext mag_TH2800_o_tot_ext \
	mag_U_o_tot_ext mag_B_o_tot_ext mag_V_o_tot_ext \
	mag_R_o_tot_ext mag_I_o_tot_ext mag_UKIRT-J_o_tot_ext \
	mag_UKIRT-H_o_tot_ext mag_UKIRT-K_o_tot_ext mag_Bj_o_tot_ext \
	mag_UKIDSS-Y_o_tot_ext mag_SDSS-u_o_tot_ext mag_SDSS-g_o_tot_ext \
	mag_SDSS-r_o_tot_ext mag_SDSS-i_o_tot_ext mag_SDSS-z_o_tot_ext \
	mag_SDSSz0.1-u_o_tot_ext mag_SDSSz0.1-g_o_tot_ext \
	mag_SDSSz0.1-r_o_tot_ext mag_SDSSz0.1-i_o_tot_ext \
	mag_SDSSz0.2-z_o_tot_ext mag_ACS-i775_o_tot_ext \
	mag_ACS-z850_o_tot_ext mag_IRAC-3.6_o_tot_ext \
	mag_IRAC-4.5_o_tot_ext mag_IRAC-5.8_o_tot_ext \
	mag_IRAC-8.0_o_tot_ext mag_GALEX-FUV_o_tot mag_GALEX-NUV_o_tot \
	mag_TH1500_o_tot mag_TH2800_o_tot mag_U_o_tot mag_B_o_tot \
	mag_V_o_tot mag_R_o_tot mag_I_o_tot mag_UKIRT-J_o_tot \
	mag_UKIRT-H_o_tot mag_UKIRT-K_o_tot mag_Bj_o_tot \
	mag_UKIDSS-Y_o_tot mag_SDSS-u_o_tot mag_SDSS-g_o_tot \
	mag_SDSS-r_o_tot mag_SDSS-i_o_tot mag_SDSS-z_o_tot \
	mag_SDSSz0.1-u_o_tot mag_SDSSz0.1-g_o_tot mag_SDSSz0.1-r_o_tot \
	mag_SDSSz0.1-i_o_tot mag_SDSSz0.2-z_o_tot mag_ACS-i775_o_tot \
	mag_ACS-z850_o_tot mag_IRAC-3.6_o_tot mag_IRAC-4.5_o_tot \
	mag_IRAC-5.8_o_tot mag_IRAC-8.0_o_tot mag_GALEX-FUV_r_tot_ext \
	mag_GALEX-NUV_r_tot_ext mag_TH1500_r_tot_ext \
	mag_TH2800_r_tot_ext mag_U_r_tot_ext mag_B_r_tot_ext \
	mag_V_r_tot_ext mag_R_r_tot_ext mag_I_r_tot_ext \
	mag_UKIRT-J_r_tot_ext mag_UKIRT-H_r_tot_ext \
	mag_UKIRT-K_r_tot_ext mag_Bj_r_tot_ext mag_UKIDSS-Y_r_tot_ext \
	mag_SDSS-u_r_tot_ext mag_SDSS-g_r_tot_ext mag_SDSS-r_r_tot_ext \
	mag_SDSS-i_r_tot_ext mag_SDSS-z_r_tot_ext \
	mag_SDSSz0.1-u_r_tot_ext mag_SDSSz0.1-g_r_tot_ext \
	mag_SDSSz0.1-r_r_tot_ext mag_SDSSz0.1-i_r_tot_ext \
	mag_SDSSz0.2-z_r_tot_ext mag_IRAC-3.6_r_tot_ext \
	mag_IRAC-4.5_r_tot_ext mag_IRAC-5.8_r_tot_ext \
	mag_IRAC-8.0_r_tot_ext mag_GALEX-FUV_r_tot mag_GALEX-NUV_r_tot \
	mag_TH1500_r_tot mag_TH2800_r_tot mag_U_r_tot mag_B_r_tot \
	mag_V_r_tot mag_R_r_tot mag_I_r_tot mag_UKIRT-J_r_tot \
	mag_UKIRT-H_r_tot mag_UKIRT-K_r_tot mag_Bj_r_tot \
	mag_UKIDSS-Y_r_tot mag_SDSS-u_r_tot mag_SDSS-g_r_tot \
	mag_SDSS-r_r_tot mag_SDSS-i_r_tot mag_SDSS-z_r_tot \
	mag_SDSSz0.1-u_r_tot mag_SDSSz0.1-g_r_tot mag_SDSSz0.1-r_r_tot \
	mag_SDSSz0.1-i_r_tot mag_SDSSz0.2-z_r_tot mag_IRAC-3.6_r_tot \
	mag_IRAC-4.5_r_tot mag_IRAC-5.8_r_tot mag_IRAC-8.0_r_tot \
	L_tot_OII3727_ext L_tot_OII3727 L_tot_Halpha_ext L_tot_Halpha \
	L_tot_OIII5007_ext L_tot_OIII5007 L_tot_Hbeta_ext L_tot_Hbeta \
	L_tot_NII6583_ext L_tot_NII6583  L_tot_SII6716_ext L_tot_SII6716
	# L_tot_Lyalpha_ext L_tot_Lyalpha L_tot_Hgamma_ext L_tot_Hgamma \

endif

if ( $K_Bj == 'true' ) then 
# compute samples at z=0 for making standard plots
    echo '******************************************************************'
    echo running SAMPLE_GALS for SED fitting and GAMA plots

    set file = $output_dir/tosedfit.hdf5
    if (-e $file) then
	rm -f $file
    endif
    set vol = 0  # output all galaxies 

    $SAMPLE_GALS_EXE  odir $output_dir  iseed $ISEED2   format hdf5 file $file  redshift $z \
    mag_sys AB  volume 0  upsilon $upsilon2 \
    dust $dustfile $emdustfile $rfacburst $fcloud $tesc_disk $tesc_burst \
    range mstars_tot 1e3 1e14 \
    props  weight type mstars_tot mchalo mhhalo mstardot  mstardot_burst \
	mag_UKIRT-K_o_tot_ext mag_Bj_o_tot_ext \
	mag_UKIRT-K_o_tot mag_Bj_o_tot \
	mag_UKIRT-K_r_tot_ext mag_Bj_r_tot_ext \
	mag_UKIRT-K_r_tot mag_Bj_r_tot \

endif


if ( $elliott == 'true' ) then 
# compute samples at z=0 for making LFs (K, bJ and r)
    echo '******************************************************************'
    echo running INSERT_GAL_PROPS, post-processing

    # B/T properties (following dustpars_Baugh05.csh)
    ./build/insert_gal_props.exe $output_dir/galaxies.hdf5 iseed=$ISEED2 z=$z dust dust_MW_hz1.0.dat $emdustfile \
	$rfacburst $fcloud $tesc_disk $tesc_burst BoverTSD_r BoverTB_r BoverTI_r \
	BoverTSD_r_ext BoverTB_r_ext BoverTI_r_ext \
	magIr_tot_ext0 magBr_tot_ext magBr_tot_ext0 magUKr_tot_ext0 magIr_tot \
	magUKr_tot_ext magBjr_tot_ext magSDr_tot_ext \
	magUKr_tot magBjr_tot magSDr_tot BoverT metV_tot
	
	
## galaxy sizes & colours in SDSS (early and late type galaxy sizes)
#    echo creating file size_SDSS.cat
#    set file = $output_dir/size_SDSS.cat
#    set vol = 0  # output all galaxies
#
#    $SAMPLE_GALS_EXE  odir $output_dir  iseed $ISEED2  file $file  redshift 0 \
#    mag_sys AB  volume 0  upsilon $upsilon2 \
#    dust $dustfile $emdustfile $rfacburst $fcloud $tesc_disk $tesc_burst \
##    range mag_SDSS-r_r_tot -100 -15 \
#    props weight mag_SDSS-r_r_tot mag_SDSS-r_r_tot_ext B/T_SDSS-r_r B/T_SDSS-r_r_ext \
#    rcomb rdisk rbulge \
#
## HI masses to create HI MF
#    echo creating file mHI.cat
#    set file = $output_dir/mHI.cat
#    set vol = 0  # output all galaxies
#
#    $SAMPLE_GALS_EXE odir $output_dir  iseed $ISEED2  file $file  redshift 0 \
#    mag_sys AB  volume 0  upsilon $upsilon2 \
##    range mcold 1e6 1e14 \
#    props weight mcold mcold_mol
#
## another Tully-Fisher catalog without selection on (B/T)_I
## (used by new plotting macros)
#    echo creating file TF.cat
#    set file = $output_dir/TF.cat
#    set vol = 0  # output all galaxies 
#
#    $SAMPLE_GALS_EXE  odir $output_dir  iseed $ISEED2  file $file  redshift 0 \
#    mag_sys AB  volume 0  upsilon $upsilon2 \
#    dust $dustfile $emdustfile $rfacburst $fcloud $tesc_disk $tesc_burst \
##    range mag_I_r_tot_ext0 -100.0 -12.0 \
#    props  weight mag_I_r_tot_ext0 vdisk vhalo B/T_B_r_ext mcold mstars_disk is_central mstars_tot
#
## SMBH masses
#    echo creating file SMBH.cat
#    set file = $output_dir/SMBH.cat
#    set vol = 0  # output all galaxies
#
#    $SAMPLE_GALS_EXE  odir $output_dir  iseed $ISEED2  file $file  redshift 0 \
#    mag_sys AB  volume 0  upsilon $upsilon2 \
#    dust $dustfile $emdustfile $rfacburst $fcloud $tesc_disk $tesc_burst \
##    range mstars_tot 1e8 1e30 \
#    props weight  M_SMBH mstars_tot B/T mstars_bulge vbulge mhhalo vhhalo \
#    B/T_SDSS-r_r B/T_SDSS-r_r_ext
#    
## stellar metallicities & ages
#    echo creating file Zstar.cat
#    set file = $output_dir/Zstar.cat
#    set vol = 0  # output all galaxies
#
#    $SAMPLE_GALS_EXE  odir $output_dir  iseed $ISEED2  file $file  redshift 0 \
#    mag_sys AB  volume 0  upsilon $upsilon2 \
#    dust $dustfile $emdustfile $rfacburst $fcloud $tesc_disk $tesc_burst \
##    range mstars_tot 1e8 1e14 \
#    props weight zstar_tot mstars_tot B/T mcold mstardot vdisk vbulge vhalo mhhalo \
#    B/T_SDSS-r_r B/T_SDSS-r_r_ext mchalo
#
        
endif


############################################################################

if ( $cosmicsed == 'true') then 
# compute samples at z=0 for making standard plots
    echo '******************************************************************'
    echo running SAMPLE_GALS for SED fitting and GAMA plots
#
## Stellar and halo masses
#    echo creating file smass.cat
    set file = $output_dir/cosmicsed.cat
    if (-e $file) then
	rm -f $file
    endif
    set vol = 0  # output all galaxies 

    #$SAMPLE_GALS_EXE  odir $output_dir  iseed $ISEED2   format hdf5 file $file  redshift $z \

    $SAMPLE_GALS_EXE  odir $output_dir  iseed $ISEED2  file $file  redshift $z \
    mag_sys AB  volume 0  upsilon $upsilon2 \
    dust $dustfile $emdustfile $rfacburst $fcloud $tesc_disk $tesc_burst \
    range mstars_tot 1e3 1e14 \
    props  weight type mstars_tot mchalo mhhalo mstardot  mstardot_burst \
	age_V_total met_V_total age_SM_total \
    mag_GALEX-FUV_r_tot_ext mag_GALEX-NUV_r_tot_ext mag_TH1500_r_tot_ext \
    mag_TH2800_r_tot_ext mag_U_r_tot_ext mag_B_r_tot_ext mag_V_r_tot_ext mag_R_r_tot_ext mag_I_r_tot_ext \
    mag_UKIRT-J_r_tot_ext mag_UKIRT-H_r_tot_ext mag_UKIRT-K_r_tot_ext mag_Bj_r_tot_ext mag_UKIDS-Y_r_tot_ext \
    mag_SDSS-u_r_tot_ext mag_SDSS-g_r_tot_ext mag_SDSS-r_r_tot_ext mag_SDSS-i_r_tot_ext mag_SDSS-z_r_tot_ext \
    mag_IRAC-3.6_r_tot_ext mag_IRAC-4.5_r_tot_ext mag_IRAC-5.8_r_tot_ext \
    mag_IRAC-8.0_r_tot_ext mag_GALEX-FUV_r_tot mag_GALEX-NUV_r_tot mag_TH1500_r_tot mag_TH2800_r_tot \
    mag_U_r_tot mag_B_r_tot mag_V_r_tot mag_R_r_tot mag_I_r_tot mag_UKIRT-J_r_tot mag_UKIRT-H_r_tot \
    mag_UKIRT-K_r_tot mag_Bj_r_tot mag_UKIDSS-Y_r_tot mag_SDSS-u_r_tot mag_SDSS-g_r_tot mag_SDSS-r_r_tot \
    mag_SDSS-i_r_tot mag_SDSS-z_r_tot \
    mag_IRAC-3.6_r_tot mag_IRAC-4.5_r_tot mag_IRAC-5.8_r_tot \
    mag_IRAC-8.0_r_tot 

endif

############################################################################

if ( $elgs == 'true') then 
# compute samples at z=0 for making standard plots
    echo '******************************************************************'
    echo running SAMPLE_GALS for ELG project
#
## Stellar and halo masses
#    echo creating file smass.cat
    set file = $output_dir/elgs.hdf5
    if (-e $file) then
	rm -f $file
    endif
    set vol = 0  # output all galaxies 

    $SAMPLE_GALS_EXE  odir $output_dir  iseed $ISEED2   format hdf5 file $file  redshift $z \
    mag_sys AB  volume 0  upsilon $upsilon2 \
    dust $dustfile $emdustfile $rfacburst $fcloud $tesc_disk $tesc_burst \
    props  weight type mstars_tot mchalo mhhalo mstardot mstardot_burst \
	age_V_total met_V_total age_DES-r_total met_DES-r_total age_SM_total BoT \
	mag_SDSS-u_o_tot_ext mag_SDSS-g_o_tot_ext mag_SDSS-r_o_tot_ext \
	mag_SDSS-i_o_tot_ext mag_SDSS-z_o_tot_ext \
	mag_SDSS-u_o_tot mag_SDSS-g_o_tot mag_SDSS-r_o_tot \
	mag_SDSS-i_o_tot mag_SDSS-z_o_tot \
	mag_DES-u_o_tot_ext mag_DES-g_o_tot_ext mag_DES-r_o_tot_ext \
	mag_DES-i_o_tot_ext mag_DES-z_o_tot_ext mag_DES-Y_o_tot_ext\
	mag_DES-u_o_tot mag_DES-g_o_tot mag_DES-r_o_tot \
	mag_DES-i_o_tot mag_DES-z_o_tot mag_DES-Y_o_tot\
	mag_MegaCam-u_o_tot_ext mag_MegaCam-g_o_tot_ext mag_MegaCam-r_o_tot_ext \
	mag_MegaCam-i_o_tot_ext mag_MegaCam-z_o_tot_ext \
	mag_MegaCam-u_o_tot mag_MegaCam-g_o_tot mag_MegaCam-r_o_tot \
	mag_MegaCam-i_o_tot mag_MegaCam-z_o_tot \
	mag_MegaCam-g-atmos_o_tot_ext mag_MegaCam-r-atmos_o_tot_ext mag_MegaCam-i-atmos_o_tot_ext \
	mag_MegaCam-g-atmos_o_tot mag_MegaCam-r-atmos_o_tot mag_MegaCam-i-atmos_o_tot \
	mag_DEIMOS-B_o_tot_ext mag_DEIMOS-I_o_tot_ext \
	mag_DEIMOS-R_o_tot_ext mag_DEIMOS-Z_o_tot_ext \
	mag_DEIMOS-B_o_tot mag_DEIMOS-I_o_tot  \
	mag_DEIMOS-R_o_tot mag_DEIMOS-Z_o_tot \
	L_tot_OII3727_ext L_tot_OII3727 L_tot_Halpha_ext L_tot_Halpha \
	L_tot_OIII5007_ext L_tot_OIII5007 L_tot_Hbeta_ext L_tot_Hbeta 
endif


if ( $agn == 'true') then 
# compute samples at z=0 for making standard plots
    echo '******************************************************************'
    echo running SAMPLE_GALS for AGN properties
    source agnpars_Griffin17.csh
#
## Stellar and halo masses
#    echo creating file smass.cat
    set file = $output_dir/agn.hdf5
    if (-e $file) then
	rm -f $file
    endif
    set vol = 0  # output all galaxies 

    $SAMPLE_GALS_EXE  odir $output_dir  iseed $ISEED2   format hdf5 file $file  redshift $z \
    mag_sys AB  volume 0  upsilon $upsilon2 \
    dust $dustfile $emdustfile $rfacburst $fcloud $tesc_disk $tesc_burst \
    agn $alpha_adaf $nEdd $LRnorm_adaf $LRnorm_td $beta_adaf $delta_adaf \
    props  weight type mstars_tot burst_mode \
	M_SMBH SMBH_tacc_stb SMBH_Mdot_stb SMBH_Mdot_hh \
	Lbol_AGN Ljet_AGN LR_AGN LHXR_AGN LSXR_AGN nuLB_AGN \
	Lbol_AGN_last_stb LR_AGN_last_stb LHXR_AGN_last_stb \
	LSXR_AGN_last_stb nuLB_AGN_last_stb Lbol_AGN_hh \
	LR_AGN_hh LHXR_AGN_hh LSXR_AGN_hh nuLB_AGN_hh f_vis_Aird \
	LSX_AGN_o LHX_AGN_o LSX_AGN_r LHX_AGN_r

    echo 'Output: ' $file
endif


# Output AGN absolute magnitudes and galaxy absolute magnitudes in bands specified in galaxies.hdf5 to compare the relative contributions.
if ( $sed_agn == 'true') then 
    echo '******************************************************************'
    echo Calculating AGN Luminosities from SED
    source agnpars_Griffin17.csh    

    set file = $output_dir/agn2.hdf5
    if (-e $file) then
	rm -f $file
    endif
    set vol = 0  # output all galaxies 
    
    # Find "run-information file" and read in first column
    set run_info_file = $output_dir/run-information
    set run_first_line = `awk '{print $1}' $run_info_file`

    # Read the filter names by going from "bandname" to "bandid"
    set i = 0
    while ($i <= $#run_first_line)
	if( $run_first_line[$i] == bandname ) then 
	    set start_name = $i
	endif
    	if( $run_first_line[$i] == bandid ) then 
	    set end_name = $i
	endif
    @ i = $i + 1
    end

    @ start_name = $start_name + 1
    @ end_name = $end_name - 1
    
    set filter_names = ($run_first_line[$start_name-$end_name])

    set -f filter_names_non_repeat = ($filter_names:q)
    set k = 1
    set mag_o_names = ()
    set mag_r_names = ()
    set mag_o_ext_names = ()
    set mag_r_ext_names = ()
    set AGN_names_o = ()
    set AGN_names_r = ()

    while ($k <= $#filter_names_non_repeat)
	if ($filter_names_non_repeat[$k] == BL || $filter_names_non_repeat[$k] == LC || $filter_names_non_repeat[$k] == SM || $filter_names_non_repeat[$k] == TH0 || $filter_names_non_repeat[$k] == TH1 || $filter_names_non_repeat[$k] == TH2 || $filter_names_non_repeat[$k] == TH3 || $filter_names_non_repeat[$k] == TH4 || $filter_names_non_repeat[$k] == TH5 || $filter_names_non_repeat[$k] == TH6 || $filter_names_non_repeat[$k] == TH7 || $filter_names_non_repeat[$k] == TH7 || $filter_names_non_repeat[$k] == TH8 || $filter_names_non_repeat[$k] == TH9 || $filter_names_non_repeat[$k] == TH10 || $filter_names_non_repeat[$k] == TH11 || $filter_names_non_repeat[$k] == TH12 || $filter_names_non_repeat[$k] == TH13 || $filter_names_non_repeat[$k] == TH14) then
	else    
	    set mag_o_names = ($mag_o_names mag_$filter_names_non_repeat[$k]_o_tot)
	    set mag_o_ext_names = ($mag_o_ext_names mag_$filter_names_non_repeat[$k]_o_tot_ext)
	    set AGN_names_o = ($AGN_names_o AGN_mag_o_$filter_names_non_repeat[$k])
	    set AGN_names_r = ($AGN_names_r AGN_mag_r_$filter_names_non_repeat[$k])
	    if ($filter_names_non_repeat[$k] == ACS-i775 || $filter_names_non_repeat[$k] == ACS-z850) then
		echo Cannot output ACS-i775_r - but can output others...
	    else
		set mag_r_names = ($mag_r_names mag_$filter_names_non_repeat[$k]_r_tot)
		set mag_r_ext_names = ($mag_r_ext_names mag_$filter_names_non_repeat[$k]_r_tot_ext)
	    endif
	endif    
    @ k = $k + 1
    end

    $SAMPLE_GALS_EXE  odir $output_dir  iseed $ISEED2   format hdf5 file $file  redshift $z \
    mag_sys AB  volume 0  upsilon $upsilon2 \
    dust $dustfile $emdustfile $rfacburst $fcloud $tesc_disk $tesc_burst \
    agn $alpha_adaf $nEdd $LRnorm_adaf $LRnorm_td $beta_adaf $delta_adaf \
    range mstars_tot 1e3 1e16 \
    props Lbol_integrated Lbol_AGN LSX_AGN_o LSX_AGN_r LHX_AGN_o LHX_AGN_r \
    $mag_o_names $mag_r_names $mag_o_ext_names $mag_r_ext_names $AGN_names_o $AGN_names_r
 
    

    echo 'Output: ' $file


endif

if ( $study_stellar_mass_function == true ) then

    echo creating smass.cat
    # SF analysis catalogue
    set file = $output_dir/smass.cat
    set vol = 0  # output all galaxies
   
    $SAMPLE_GALS_EXE  odir $output_dir  iseed $ISEED2  file $file  redshift $z \
\
    mag_sys AB  volume 0  upsilon $upsilon2 \
    dust $dustfile $emdustfile $rfacburst $fcloud $tesc_disk $tesc_burst \
    props weight mstars_tot mstars_allburst

endif

echo 'The end'

if ( $keep_inputs != true ) then
    rm -f $galform_inputs_file
endif

exit
