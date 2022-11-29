DHALOS

I have to upload the code to github. It is essential to run Galform and Shark SAMs over merger trees since it gives the appropriate format. It can be run in parallel. The code is in: INTRODUCE PATH

There are different parts of the code to be run:
- Find_Descendants: create own Dhalos merger trees given halos-subhalos and particle files.
To run the Find_Descendants executable:  mpirun -np 8(number of Gadget4 output files) ./path/to/build/find_descendants parameter_file
- Build_Trees: given some input merger trees, the code modifies them.
To run the Build_Trees executable:  mpirun -np 8(number of Gadget4 output files) ./path/to/build/build_trees parameter_file
- Trace particles: for type 2 galaxies (orphans), it generates some particle catalogues with only the most bound particles of these orphan galaxies so that the SAM takes as position and velocity the one from the most bound particle and not interpolating.
To run the Trace_Particles executable:  mpirun -np 8(number of Gadget4 output files) ./path/to/build/trace_particles parameter_file

All these executables can be run through the Slurm queueing system. One example is given here:
- submit_mpi_UNITsim+CT.sh: code to finally run the whole UNIT simulation parallelized with 3 nodes communication. In this case you only run Build_Trees and through different nodes. mpirun -npernode 42 ./path/to/build/build_trees parameter_file

Parameter files:
- UNITsim+CT.txt: parameter file for the whole UNIT simulation with ConsistentTrees merger trees. In this case you only run Build_Trees. Data generated in /data8/vgonzalez/SAMs/trees/
- G4_HDF5_HBT_multiple+D.txt: parameter file to run over Gadget4 data generating own Dhalo merger trees. In this case you run first Find_Descendants, then Build_Trees and optionally Trace_Particles.
- G4_HDF5_HBT_multiple+S.txt: parameter file to run over Gadget4 data generating own Dhalo merger trees. In this case you only run Build_Trees and optionally Trace_Particles.

When using Trace_Particles, run Gadget4 with the SUBFIND_ORPHAN_TREATMENT activated to have catalogues with only the most bound particles of the orphan galaxies instead of catalogues with all the simulated particles (way of saving memory). Anyways Gadget4 always produces as output the catalogues with all the simulated particles. Set the "flag update_tree_files" to T to modify positions and velocities of interpolated halos, but make sure you have backup copy of the merger trees in case anything goes wrong.

New parameters added in the code:
- rhalf_consistenttrees_aprox (Build_Trees): whether or not an approximation for the half mass is used. Specific to the UNIT simulation and its consistent trees merger trees.
- snap0 (Build_Trees): whether or not the snap=0 is considered. Specific to the UNIT simulations and its consistent trees merger trees.
- n_files_ids (Find_Descendants): number of files where IDs are stored when constructing the merger tree directly with DHalos from Subfind data. Specific to the different formats that work with Subfind ("LGADGET2","LGADGET3","PGADGET3","COCO","GADGET4_HDF5","EAGLE"). It corresponds to the flag NumFilesPerSnapshot when running Gadget4.


-----------------------------------------------------------------------------------------------------------------

GALFORM

Semi-analytical model. The code is in /home/chandro/galform

To run the code we need a reference parameter file (.ref file) where the different parameter values are defined.
- UNIT.ref: example.

Later, these params can be modified using the codes to run Galform and to send it to slurm queues. Run only 1 simple model or more (not emulator): you need to provide a model (I have usually used gp19.vimal as reference and then I may have changed some values) and a simulation that has to be predefined.
- run_galform_vio_simplified.csh: you have the different models and simulations defined, as well as the output properties you can choose.
- qsub_galform_vio_simplified.csh: you choose the model and simulation and it is sent to a Slurm queue. (each subvolume is a job)
- test_par.sh: 1 model parallelized (1 job, 64 subvolumes per job, 1 subvolume per cpu)

Run 1 or more models (specific for the training models of the emulator):
- run_galform_vio_simplified_em_tfm_eff.csh: it saves each model run in a directory whose name indicates the values of the parameters varied.
- test_par_mult_em.sh: it reads the parameters of the latin hypercube file for 1 model at a time (4 jobs, 16 subvolumes per job, 1 subvolume per cpu)
- test_par_mult_em_eff.sh: it reads the parameters of the latin hypercube file for 2 models at the same time (1 job, 128 subvolumes per job, 1 subvolume per cpu) ./qsub_galform_vio_simplified.csh


-----------------------------------------------------------------------------------------------------------------

GALFORM

Semi-analytical model. The code is in /home/chandro/shark

SHARK

You can find more info in the website https://shark-sam.readthedocs.io/en/latest/

To run it we need to provide the free parameter values, the path to the Dhalos output and a file indicating the redshift-snapshot correspondence.

Not parallelized: 1 subvolume: ./shark parameter_file "simulation_batches = nº of subvolume" All subvolumes: ./shark parameter_file -t nº of threads "simulation_batches = 0-maximum_subvolume" (this way doesn't produce the output distributed in subvolumes)

Parallelized: I suppose you can apply the same strategy as the one in Galform (sending different subolumes to different Slurm queues) ./shark-submit parameter_file "simulation_batches=0-maximum_subvolume" doesn't work. sbatch: error: Unable to open file hpc/shark-run I have implemented a new "shark-run" file that send 1 subvolume per job. What it remains is to implement the same parallelization carried out in Galform (send more than 1 model for emulator training and make the code the more efficient).

For example I haven't worked varying the different parameters, but it is described how to do it in https://shark-sam.readthedocs.io/en/latest/optim.html