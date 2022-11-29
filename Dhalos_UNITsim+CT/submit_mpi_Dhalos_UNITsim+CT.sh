#!/bin/bash

#SBATCH -A 16cores
#SBATCH --job-name=1.128_vol_John_longfof_10_rfactor2_m+t+b
#SBATCH --output=/home/chandro/junk/out_%x.txt
#SBATCH --error=/home/chandro/junk/error_%x.txt
#SBATCH --ntasks=126
#SBATCH --nodes=3
#SBATCH --cpus-per-task=1
#SBATCH --tasks-per-node=42
#SBATCH --time=5-00:00:00
#SBATCH --nodelist=miclap,taurus,brutus
#SBATCH --mem=0

mpirun -npernode 42 ../../build/build_trees UNITsim+CT.txt
