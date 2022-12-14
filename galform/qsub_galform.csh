#! /bin/tcsh -f
# submit GALFORM N-body tree runs to BSUB batch queue on COSMA

set name    = UNIT200_calibration_plots
set logpath = /home/chandro/junk
set max_jobs = 64

# label for N-body simulation (halo merger trees & cosmological parameters)
set Nbody_sim = n512_fid_Dhalo
#set Nbody_sim = MillGas
#set Nbody_sim = MillGas62.5
#set Nbody_sim = EagleDM
#set Nbody_sim = EagleDM67
#set Nbody_sim = EagleDM101
#set Nbody_sim   = L800
#set Nbody_sim = DoveCDM
#set Nbody_sim = DoveCDM.lr
#set Nbody_sim = DoveWDM.clean

# lists of snapshots & subvolumes to run
if( $Nbody_sim == Mill1 ) then
# snapshotss
    set iz_list = (63)
    #set iz_list = (41 32 27)
# subvolumes
    #set ivol_list = (424 231 101)
    set ivol_list = (0)

else  if( $Nbody_sim == Mill2 ) then
# snapshots  - iz(Mill2) = iz(Mill1) + 4  at z<15
    set iz_list = (67)
# subvolumes
    set ivol_list = (0)   # standard

else if( $Nbody_sim == MillGas ) then
# snapshots  - iz(MillGas) = iz(Mill1) - 2  at z<15
    #set iz_list = (16 19 21 23 25 28 30 34 39 42 46 52 57 61)   # standard
    #set iz_list = (16 21 22 23 24 25 28 29 30 32 33 34 35 37 38 39 40 42 44 46 50 53 56 61)   # standard + AGN + ELGs
    #set iz_list = (61 44 42 40 37 34) #z=0, 0.6, 0.75, 0.9, 1.18, 1.5
    #set iz_list = (39 41 61) #z=1.0, 0.83, 0.
    set iz_list = (34 44) 
    #set iz_list = (61 60 59 58 57 46 30) #AGNs 
    #set iz_list = (61) # z =  0
# subvolumes
    #set nvol = 1-3   # standard
    #set nvol = 1-1
    set nvol = 1-64

else if( $Nbody_sim == L800 ) then
# snapshots
    set iz_list = (271) # z = 0
    #set iz_list = (271 199 190 181 167) #z=0, 0.6, 0.75, 0.9, 1.18
# subvolumes
    set nvol = 1-1
    #set nvol = 1-3
    #set nvol = 3-64

else if( $Nbody_sim == EagleDM ) then
    set iz_list = (34 43 56 65 74 86 99 115 134 145 158 175 190 200)   # standard
    #set iz_list = (158 175 190 200)
    #set iz_list = (74 99  134 200) # z = 3, 2, 1, 0
    #set iz_list = (200 152 145 137 127) #z=0, 0.6, 0.75, 0.9, 1.18
    #set iz_list = (99 158 200) # z = 2.0, 0.5, 0
    #set iz_list = (200) # z = 0

    # subvolumes
    set nvol =  1-128  # Eagle 1-128

else if( $Nbody_sim == EagleDM67 ) then   
    #set iz_list = (67 64 59 53 49 45 39 34 29 25 22 19 15 12) # standard
    set iz_list = (67 45 34 25) # z = 0, 1, 2, 3
    #set iz_list = (67) # z = 0

    # subvolumes
    set nvol =  1-128  


else if( $Nbody_sim == EagleDM101 ) then
    set iz_list = (101 95 88 80 73 67 58 50 44 38 33 29 22 18) # standard
    set iz_list = (101 67 50 38) # z = 0, 1, 2, 3
    #set iz_list = (101) # z = 0

    # subvolumes
    set nvol =  1-128  

else if( $Nbody_sim == nifty62.5 ) then
    #set iz_list = (16 19 21 23 25 28 30 34 39 42 46 52 57 61)   # standard
    #set iz_list = (61) # z = 0
    set izmin = 1
    set izmax = 128
    set iz_list = (78 97 128)
    #@ i = $izmin
    #while ($i <= $izmax)
    #	set iz_list = ($iz_list $i)
    #	@ i = $i + 1
    #end

    # subvolumes
    set nvol = 1-64 # because it is ivol-1
    #set ivol_list = (0)   # standard
    #set ivolmin = 1
    #set ivolmax = 64
    #set ivol_list = ()
    #@ i = $ivolmin
    #while ($i <= $ivolmax)
    #	set ivol_list = ($ivol_list $i)
    #	@ i = $i + 1
    #end

else if( $Nbody_sim == MillGas62.5 ) then
    #set iz_list = (16 19 21 23 25 28 30 34 39 42 46 52 57 61)   # standard
    set iz_list = (61) # z = 0
    #set izmin = 1
    #set izmax = 61
    #set iz_list = ()
    #@ i = $izmin
    #while ($i <= $izmax)
    #	set iz_list = ($iz_list $i)
    #	@ i = $i + 1
    #end

    # subvolumes
    set nvol = 1-1

else if( $Nbody_sim == DoveCDM ) then
    #set iz_list = (16 19 21 23 25 28 30 34 39 42 46 52 57 61)   # standard
    set iz_list = (159) # z = 0
    #set izmin = 1
    #set izmax = 159
    #set iz_list = ()
    #@ i = $izmin
    #while ($i <= $izmax)
    #	set iz_list = ($iz_list $i)
    #	@ i = $i + 1
    #end

    # subvolumes
    set nvol = 1-64

else if( $Nbody_sim == DoveCDM.lr ) then
    #set iz_list = (16 19 21 23 25 28 30 34 39 42 46 52 57 61)   # standard
    set iz_list = (79) # z = 0
    #set izmin = 1
    #set izmax = 79
    #set iz_list = ()
    #@ i = $izmin
    #while ($i <= $izmax)
    #	set iz_list = ($iz_list $i)
    #	@ i = $i + 1
    #end

    # subvolumes
    set nvol = 1-64

else if( $Nbody_sim == DoveWDM.clean ) then
    #set iz_list = (16 19 21 23 25 28 30 34 39 42 46 52 57 61)   # standard
    set iz_list = (79) # z = 0
    #set izmin = 1
    #set izmax = 79
    #set iz_list = ()
    #@ i = $izmin
    #while ($i <= $izmax)
    #	set iz_list = ($iz_list $i)
    #	@ i = $i + 1
    #end

    # subvolumes
    set nvol = 1-64

else if( $Nbody_sim == UNIT100 ) then

    set iz_list = (128 95) # z = 0
    # subvolumes
    set nvol = 1-64

else if( $Nbody_sim == UNIT200 ) then

    set iz_list = (128 95) # only z = 0
    # subvolumes
    set nvol = 1-64

else if( $Nbody_sim == UNIT ) then

    set iz_list = (128 95) # only z = 0
    # subvolumes
    set nvol = 1-64

else if( $Nbody_sim == n512_fid_Dhalo ) then

    set iz_list = (128) # only z = 0
    # subvolumes
    set nvol = 1-64

endif

#set iz_list = (200) #z=0 EagleDM
#set iz_list = (115 145  158 175 190 34 43 56 65 86)
#set iz_list = (61) 
#set nvol = 1-1 #52-60

set Testing = false

echo 'Redshifts: ' $iz_list
echo 'Volumes: ' $nvol

# Send only 1 model
foreach model (gp19.vimal.nopart) #gp19.font gp19.starvation)
    echo 'Model: ' $model
    # Loop for different redshift
    foreach iz ( $iz_list)
	# run script
	set script = run_galform_vio_simplified.csh
	set jobname = $Nbody_sim.$model
	set logdirectory = ${logpath}/fnl_sam/test/${Nbody_sim}/
	\mkdir -p ${logdirectory:h}
	set logname = ${logdirectory}/${model}.%A.%a.log


	if ("$Testing" == "true") then
        # Construct a batch script and submit it to SLURM as an array job -
        # the script consists of the Slurm header below followed by the
	# contents of ${script}. 
        cat << EOF - ${script} | sbatch --array=${nvol}%${max_jobs} 
#!/bin/tcsh -ef 
# 
#SBATCH --ntasks 16   
#SBATCH -J ${jobname} 
#SBATCH -o ${logname}
#SBATCH --nodelist=taurus
#SBATCH -A 16cores
#SBATCH -t 3:00:00   
# 
  
# Set parameters 
set model     = ${model}  
set Nbody_sim = ${Nbody_sim} 
set iz        = ${iz}  
@ ivol        = \${SLURM_ARRAY_TASK_ID} - 1  

# Galform run script follows
EOF

	else
        # Construct a batch script and submit it to SLURM as an array job -
        # the script consists of the Slurm header below followed by the
	# contents of ${script}. 
        cat << EOF - ${script} | sbatch --array=${nvol}%${max_jobs} 
#!/bin/tcsh -ef 
# 
#SBATCH --ntasks 1
#SBATCH -J ${jobname} 
#SBATCH -o ${logname}
#SBATCH --nodelist=miclap 
#SBATCH -A 16cores
#SBATCH -t 1-00:00:00   
# 
  
# Set parameters 
set model     = ${model}  
set Nbody_sim = ${Nbody_sim} 
set iz        = ${iz}  
@ ivol        = \${SLURM_ARRAY_TASK_ID} - 1  

# Galform run script follows
EOF
	endif
	##Kind of interactive	   
	#./${script} $model $Nbody_sim $iz 6

	# Cosma queue: -q cosma -W 01:30
    end
end

#gp17.spin.ramt0.01.stabledisk0.75.ac085 gp18.font
#gp17.spin.noagnfb.stb gp17.spin.noagnfb gp17.spin.stb gp17.noagnfb.stb gp17.noagnfb gp17.stb
#gp17.spin.tidal gp17.spin.aram0 gp17.spin.aram0.5  gp17.spin.aram1 gp17.spin.aram1.5
#gp17.spin.ramt0 gp17.spin.ramt0.5 gp17.spin.ramt1.0
#gp17.spin.acce0.1
# gp17.spin.ramt0.01.fgasburst0.4  gp17.spin.ramt0.01.btburst4 gp17.spin.ramt0.01.stabledisk0.75 gp17.spin.ramt0.01.ah3.4e01 gp17.spin.ramt0.01.nu074
#gp17.spin.ramt0.01.griffin
#gp17.spin.ramt0.01.carnage gp17.spin.ramt0.01.stabledisk0.75.e01 gp17.spin.ramt0.01.stabledisk0.75.e01.ac08
#gp17.spin.ramt0.01.stabledisk0.65 gp17.spin.ramt0.01.e004 gp17.spin.ramt0.01.ac0.2 gp17.spin.ramt0.01.stabledisk0.75.e01.ac085 gp17.spin.ramt0.01.e01.ac06 gp17.spin.ramt0.01.e01.fburst01
#gp17.spin.ramt0.01.ac07 gp17.spin.ramt0.01.ac08 gp17.spin.ramt0.01.ac085 gp17.spin.ramt0.01.stabledisk0.75.ac085 gp17.spin.ramt0.01.stabledisk0.75.e01.ac087
#gp17.spin.ramt0.01.griffinBH gp17.spin.ramt0.01.griffinBH.stb075
#gp17.spin.ramt0.01
