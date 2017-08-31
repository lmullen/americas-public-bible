#!/bin/bash
#SBATCH --job-name=convert-batches
#SBATCH --output="argo-out/logs/argo_%A-%a.out"
#SBATCH --mail-type=ALL
#SBATCH --mail-user=lmullen@gmu.edu
#SBATCH --partition=all-HiPri
#SBATCH --export=NONE

#SBATCH --array=1-1498
#SBATCH --ntasks=24

## Load modules since we are not exporting our environment
module load R/3.4.1

## Get the file name associated with that line of the list of files
BATCH_LIST=./bin/chronam-batch-list.txt
BATCH=$(sed -n "${SLURM_ARRAY_TASK_ID}p" $BATCH_LIST)
OUTPUT=argo-out/chronam-df/$BATCH.feather

## Run the executable only if output does not exist
if [ -f "$OUTPUT" ]; then
  echo "Not running task because $OUTPUT already exists."
else
  Rscript ./bin/chronam-batch-to-dataframe.R \
    --log argo-out/logs/convert-chronam-batches.log \
    chronam-batches/$BATCH \
    -o $OUTPUT
fi
