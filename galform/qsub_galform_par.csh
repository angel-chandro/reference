#!/bin/bash

name='test'
logpath=/home/chandro/junk
max_jobs=64

Nbody_sim=UNIT100 # indicate the simulation


if [ $Nbody_sim == UNIT100 ]
then
    #iz_list=(128) # only z = 0
    iz_list=(128 95)
    
else [ $Nbody_sim == UNIT200 ]
    #iz_list=(128) # only z = 0
    iz_list=(128 95)
     
fi

# In this case we send only 1 model, but you cand send more than 1
for model in {"gp19.vimal",}
do
    echo 'Model: ' $model

    for iz in "${iz_list[@]}"
    do
	echo ${iz}
	script=run_galform_vio_simplified.csh
	jobname=$Nbody_sim.$model
	logname=${logpath}/${Nbody_sim}/neta_simplified/${model}.%A.%a.log
	#\mkdir -p ${logname:h}
	job_file=${logpath}/${Nbody_sim}/neta_simplified/${model}.job

	# uses 64 cpus, each of them 1 subvolume
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
#SBATCH -t 2:00:00   
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
