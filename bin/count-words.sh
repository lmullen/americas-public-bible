#!/bin/bash
#SBATCH --job-name=count-words
#SBATCH --output="/scratch/lmullen/logs/count-words-%A_%a.out"
#SBATCH --mail-type=ALL
#SBATCH --mail-user=lmullen@gmu.edu
#SBATCH --partition=all-HiPri
#SBATCH --export=NONE
#SBATCH --array=1-1586%120

## Load modules since we are not exporting our environment
module load R/3.4.4

## Get the file name associated with that line of the list of files
BATCH_LIST=/home/lmullen/public-bible/bin/newspaper-batches.txt
BATCH=$(sed -n "${SLURM_ARRAY_TASK_ID}p" $BATCH_LIST)
INPUT=/scratch/lmullen/newspaper-batches/$BATCH.fst
OUTPUT=/scratch/lmullen/argo-out/wordcounts/$BATCH-wordcount.fst

## Run the executable only if output does not exist
echo "Job details: BATCH=$BATCH TASKID: $SLURM_ARRAY_TASK_ID"
echo "Input files is $INPUT"
if [ -f "$OUTPUT" ]; then
  echo "SKIPPED: Not running task because $OUTPUT already exists"
else
  echo "RUNNING: Starting script to create $OUTPUT"
  Rscript /home/lmullen/public-bible/bin/count-words.R \
    $INPUT \
    -o $OUTPUT && \
  echo "FINISHED: Finished script to create $OUTPUT"
fi
