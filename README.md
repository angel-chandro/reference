DHALOS

I have to upload the code to github. It is essential to run Galform and Shark SAMs over merger trees since it gives the appropriate format. It can be run in parallel. The standard code is in: /home/chandro/dhalo-trees_rhalf+snap_nfids_nftab.


There are different parts of the code to be run:
- Find_Descendants: create own Dhalos merger trees given halos-subhalos and particle files.
To run the Find_Descendants executable:  mpirun -np 8(number of Gadget4 output files) ./path/to/build/find_descendants parameter_file
- Build_Trees: given some input merger trees, the code modifies them.
To run the Build_Trees executable:  mpirun -np 1 ./path/to/build/build_trees parameter_file (MPIRUN NOT IMPLEMENTED FOR GADGET4 MERGER TREES)
- Trace_Particles: for type 2 galaxies (orphans), it generates some particle catalogues with only the most bound particles of these orphan galaxies so that the SAM takes as position and velocity the one from the most bound particle and making use of an analytical expression.
To run the Trace_Particles executable:  mpirun -np 8(number of Gadget4 output files) ./path/to/build/trace_particles parameter_file

All these executables can be run through the Slurm queueing system. One example is given here:
- submit_mpi_UNITsim+CT.sh: code to finally run the whole UNIT simulation parallelized with 3 nodes communication (sbatch submit_mpi_UNITsim+CT.sh). In this case you only run Build_Trees and through different nodes. mpirun -npernode 42 ./path/to/build/build_trees parameter_file (MPIRUN USED AS FOR CONSISTENTTREES MERGER TREES IS IMPLEMENTED)

Parameter files:
- UNITsim+CT.txt and UNITsim+CT.cfg: parameter files for the whole UNIT simulation with ConsistentTrees merger trees. In this case you only run Build_Trees. Data generated in /data8/vgonzalez/SAMs/trees/
- Gadget4_DhaloMT.txt: parameter file to run over Gadget4 data generating own Dhalo merger trees. In this case you run first Find_Descendants, then Build_Trees and optionally Trace_Particles.
- Gadget4_G4MT.txt: parameter file to run over Gadget4 data generating own Dhalo merger trees. In this case you only run Build_Trees and optionally Trace_Particles.

When using Trace_Particles, run Gadget4 with the SUBFIND_ORPHAN_TREATMENT activated to have catalogues with only the most bound particles of the orphan galaxies instead of catalogues with all the simulated particles (way of saving memory). Anyways Gadget4 always produces as output the catalogues with all the simulated particles. Set the "flag update_tree_files" to T to modify positions and velocities of interpolated halos, but make sure you have backup copy of the merger trees in case anything goes wrong.

New parameters added in the code:
- rhalf_consistenttrees_aprox (Build_Trees): whether or not an approximation for the half mass is used. Specific to the UNIT simulation and its consistent trees merger trees.
- snap0 (Build_Trees): whether or not the snap=0 is considered. Specific to the UNIT simulations and its consistent trees merger trees.
- n_files_ids (Find_Descendants): number of files where particle data is stored when constructing the merger tree directly with DHalos from Gadget data. Specific to the different formats that work with Subfind ("LGADGET2","LGADGET3","PGADGET3","COCO","GADGET4_HDF5","EAGLE"). It corresponds to the flag NumFilesPerSnapshot when running Gadget4.
- n_files_tab (Find_Descendants and Build_Trees): number of files where halo-subhalos are stored when constructing the merger tree directly with DHalos from Gadget data. Specific to the different formats that work with Subfind ("LGADGET2","LGADGET3","PGADGET3","COCO","GADGET4_HDF5","EAGLE"). It corresponds to the flag NumFilesPerSnapshot when running Gadget4.
- Gadget4 descendants (Gadget4 merger trees in the Build_Trees/gadget4_descendants.f90 code) for more than 1 file implemented.

-----------------------------------------------------------------------------------------------------------------

GALFORM

Semi-analytical model. The code is in /home/chandro/galform

To run the code we need a reference parameter file (.ref file) where the different parameter values are defined.
- UNIT.ref: example of the UNIT simulation based on the gp19 model. Variations: the path aquarius_tree_file,
trace_particles = true or false and the path aquarius_particle_file, cosmology and power spectrum parameters, simulation volumes.
Another important thing is to have the power spectrum of the cosmology employed. To generate I have used CAMB:
- camb_Pk.py: given the cosmology and power spectrum parameters it generates the Pk for the .ref file (PKfile parameter).

Later, all these paramerters can be still modified using the codes to run and send Galform to slurm queues (the Slurm configuration can be modified as you wish).
Run only 1 simple model or more (not emulator): to run Galform you need to provide a model, an Nbody simulation, a redshift and a subvolume.
- run_galform.csh: here although the .ref file is used as a reference, you can define some parameter values again overwriting them. In such a way, there is a wide variety of different models and simulations defined, as well as the output properties you can choose. Flags: set only "galform" (to run galform) and "elliott" (to produce the desired output) to true, while "models_dir" to indicate the output path and "./delete_variable.csh $galform_inputs_file aquarius_particle_file" in case there are no particle files. It generates the same number of subvolumes as the input Dhalos merger trees are distributed in. (I have usually used gp19.vimal as reference and then I may have changed some values)
To delete a parameter: ./delete_variable.csh $galform_inputs_file parameter_name
To change a parameter value: ./replace_variable.csh $galform_inputs_file parameter_name new_parameter_value
- qsub_galform.csh: you choose a model and a simulation and it is sent to a Slurm queue (1 slurm job, 1 subvolume per job, 16 cpus per subvolume). (./qsub_galform.csh)
- qsub_galform_par.sh: send 1 or more models parallelized (1 slurm job, 64 subvolumes per job, 1 cpu per subvolume). More efficient: 1 redshift/model at a time. (./qsub_galform_par.sh)
- qsub_galform_par_eff.sh: send 1 or more models parallelized (1 slurm job, 128 subvolumes per job, 1 cpu per subvolume). Even more efficient: 2 redshifts/models at the same time. (./qsub_galform_par_eff.sh)

Run 1 or more models (specific for the training models of the emulator):
- run_galform_em.csh: there is a wide variety of different models and simulations defined, as well as the output properties you can choose. Flags: set only "galform" (to run galform) and "elliott" (to produce the desired output) to true, while "models_dir" to indicate the output path and "./delete_variable.csh $galform_inputs_file aquarius_particle_file" in case there are no particle files. It generates the same number of subvolumes as the input Dhalos merger trees are distributed in. The difference respect to "run_galform.csh" is that Galform uses the model "gp19.vimal.em.project" in which each Galform run has a different set of free parameters (those we are going to study their variation), so the input free parameters take the value of the corresponding Latin Hypercube position and each model itself is stored in a different directory whose name indicate the parameter values.
- qsub_galform_par_em.sh: it reads the parameters of the latin hypercube from a file (each line corresponds to the ten parameter values) for 1 redshift/model at a time (4 jobs, 16 subvolumes per job, 1 cpu per subvolume). (./qsub_galform_par_em.sh)
- qsub_galform_par_em_eff.sh: it reads the parameters of the latin hypercube from a file (each line corresponds to the ten parameter values) for 2 redshifts/models at the same time (1 job, 128 subvolumes per job, 1 cpu per subvolume). (./qsub_galform_par_em_eff.sh)


-----------------------------------------------------------------------------------------------------------------

SHARK

Semi-analytical model. The code is in /home/chandro/shark

To run it we need to provide the free parameter values, the path to the Dhalos output and a file indicating the redshift-snapshot correspondence.

Not parallelized: this way doesn't produce the output distributed in subvolumes, but all the subvolumes together
- 1 subvolume: ./shark parameter_file "simulation_batches = nº of subvolume"
- All subvolumes: ./shark parameter_file -t "nº of threads" "simulation_batches = 0-maximum_subvolume"

Parallelized: I suppose you can apply the same strategy as the one in Galform (sending different subvolumes to different Slurm queues)
./shark-submit parameter_file "simulation_batches=0-maximum_subvolume" doesn't work, appearing the following error "sbatch: error: Unable to open file hpc/shark-run".
Therefore, I have implemented a new "shark-run" file that send 1 subvolume per job, this way the output is distributed over the different subvolumes and it is easier to parallelise.
- shark-run: new shark-run to launch 1 subvolume per job.
What it remains is to implement the same parallelization carried out in Galform (send more than 1 model for emulator training and make the code as efficient as possible).

You can find more info in the website https://shark-sam.readthedocs.io/en/latest/
For example I haven't worked varying the different parameters, but it is described how to do it in https://shark-sam.readthedocs.io/en/latest/optim.html

