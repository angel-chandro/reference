#!/bin/bash

name='test'
logpath=/home/chandro/junk
max_jobs=64

Nbody_sim=n512_fid_Dhalo


if [ $Nbody_sim == UNIT100 ]
then
    iz_list=(128) # z = 0
    
else [ $Nbody_sim == n512_fid_Dhalo ]
    iz_list=(128) # z = 0, 1.1

fi

for model in {"gp19.vimal.nopart",}
do
    echo 'Model: ' $model

    for iz in "${iz_list[@]}"
    do
	
	script=run_galform_vio_simplified.csh
	jobname=$Nbody_sim.$model
    
	#for i in {0..3}
	i=0
	#do
	logpath2=${logpath}/fnl_sam/test/${Nbody_sim}/
	\mkdir -p ${logpath2:h}
	logname=${logpath2}/${model}.${i}.%A.%a.log
	job_file=${logpath2}/${model}.${i}.job

	#i=0
	tasks=128
	j_i=$( expr $i \* $tasks) # values  0,16,32,48
	int1=$( expr $i + 1)
	int2=$( expr $int1 \* $tasks)
	j_f=$( expr $int2 - 1) # values 15,31,47,63
	j_i=0
	j_f=127
	cat > $job_file <<EOF
#!/bin/bash 
# 
#SBATCH --ntasks=${tasks}
#SBATCH --cpus-per-task=1
#SBATCH -J ${jobname}
#SBATCH -o ${logname}
#SBATCH --nodelist=miclap
#SBATCH -A 128cores
#SBATCH -t 12:00:00   
#
#
for ivol in {$j_i..$j_f}
do  
    echo Ivol \$ivol
    if [ \$ivol -lt 64 ]
    then
	srun -n1 -c1 -N1 --exclusive ./${script} ${model} ${Nbody_sim} 128 \$ivol &
    else
	ivol2=\$( expr \$ivol - 64)
	srun -n1 -c1 -N1 --exclusive ./${script} ${model} ${Nbody_sim} 95 \$ivol2 &
    fi
done
wait

EOF
	sbatch $job_file
	rm $job_file
	#done
	
    done
    
done
echo 'Finished'
