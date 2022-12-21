#!/bin/bash

name='test'
logpath=/home/chandro/junk
max_jobs=64

Nbody_sim=n512_fid_G4


if [ $Nbody_sim == n512_fid_G4 ]
then
    #iz_list=(128 95) # only z = 0
    iz_list=(128 95)
    
else if [ $Nbody_sim == UNIT100 ]
     then
	 #iz_list=(128) # only z = 0
	 iz_list=(128 95)

     else [ $Nbody_sim == UNIT ]
	  #iz_list=(128) # only z = 0
	  iz_list=(95)
     fi
fi
  
for model in {"gp19.vimal.nopart",}
do
    echo 'Model: ' $model

    for iz in "${iz_list[@]}"
    do
	echo ${iz}
	script=run_galform_vio_simplified.csh
	jobname=$Nbody_sim.$model
	logdirectory=${logpath}/fnl_sam/test/${Nbody_sim}
	\mkdir -p ${logdirectory:h}
	logname=${logdirectory}/${model}.%A.%a.log
	job_file=${logdirectory}/${model}.job
    
	tasks=64
	i=1
	int1=$( expr $i - 1)
	j_i=$( expr $int1 \* $tasks) 
	int2=$( expr $i \* $tasks)
	j_f=$( expr $int2 - 1) 
	
	cat > $job_file <<EOF
#!/bin/bash
# 
#SBATCH --ntasks=${tasks}
#SBATCH --cpus-per-task=1
#SBATCH -J ${jobname}
#SBATCH -o ${logname}
#SBATCH --nodelist=miclap
#SBATCH -A 64cores
#SBATCH -t 4-00:00:00   
#
#
for ivol in {$j_i..$j_f}
do
    echo Subvolume: \$ivol
    srun -n1 -c1 -N1 --exclusive ./${script} ${model} ${Nbody_sim} ${iz} \$ivol &
#
done
wait
#
EOF

	sbatch $job_file
	rm $job_file

    done
done
echo 'Finished'
