#!/bin/bash
#SBATCH --account=m2294
#SBATCH --qos=regular
#SBATCH --constraint=haswell
#SBATCH --exclusive
#SBATCH --time=02:00:00
#SBATCH --mail-type=ALL

cores=$(( $(echo $SLURM_JOB_CPUS_PER_NODE | cut -d'(' -f 1) / 2 ))

export OMP_SCHEDULE=static,1

function launch {
    OMP_NUM_THREADS=$cores OMP_PLACES=cores srun -n $1 -N $1 --ntasks-per-node=1 --cpus-per-task=$(( cores * 2 )) --cpu_bind none ../../mpi_openmp${VARIANT:+_}$VARIANT/forall "${@:2}"
}

function repeat {
    local -n result=$1
    local n=$2
    result=()
    for i in $(seq 1 $n); do
        result+=("${@:3}")
        if (( i < n )); then
            result+=("-and")
        fi
    done
}

function sweep {
    for s in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21; do
        for rep in 0 1 2 3 4; do
            if [[ $rep -le $s ]]; then
                local args
                repeat args $3 -kernel compute_bound -iter $(( 1 << (26-s) )) -type $4 -radix $5 -steps ${STEPS:-1000} -width $(( $2 * cores ))
                $1 $2 "${args[@]}"
            fi
        done
    done
}

for n in $SLURM_JOB_NUM_NODES; do
    for g in ${NGRAPHS:-1}; do
        for t in ${PATTERN:-stencil_1d}; do
            for r in ${RADIX:-5}; do
                sweep launch $n $g $t $r > mpi_openmp${VARIANT:+_}${VARIANT}_ngraphs_${g}_type_${t}_radix_${r}_nodes_${n}.log
            done
        done
    done
done
