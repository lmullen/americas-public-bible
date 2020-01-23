#!/bin/bash
#SBATCH --job-name=predict-quotations
#SBATCH --output="/scratch/lmullen/logs/predict-quotations-%A_%a.out"
#SBATCH --mail-type=ALL
#SBATCH --mail-user=lmullen@gmu.edu
#SBATCH --partition=all-HiPri
#SBATCH --mem-per-cpu=8G
#SBATCH --export=NONE
#SBATCH --array=1-3825

## Load modules since we are not exporting our environment
module load R/3.5.2

## Get the file name associated with that line of the list of files
BATCH_LIST=/home/lmullen/public-bible/bin/newspaper-batches.txt
BATCH=$(sed -n "${SLURM_ARRAY_TASK_ID}p" $BATCH_LIST)
INPUT=/scratch/lmullen/argo-out/quotations/$BATCH-quotations.csv
OUTPUT=/scratch/lmullen/argo-out/predictions/$BATCH-predictions.csv

## Run the executable only if output does not exist
echo "Job details: BATCH=$BATCH TASKID=$SLURM_ARRAY_TASK_ID"
echo "Input file: $INPUT"
if [ -f "$OUTPUT" ]; then
  echo "SKIPPED: Not running task because $OUTPUT already exists"
else
  echo "RUNNING: Starting script to create $OUTPUT"
  Rscript /home/lmullen/public-bible/bin/predict-quotations.R \
    $INPUT \
    --model=/home/lmullen/public-bible/bin/prediction-payload.rda \
    -o $OUTPUT && \
  echo "FINISHED: Finished script to create $OUTPUT"
fi
