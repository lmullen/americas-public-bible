#!/bin/bash
#SBATCH --job-name=convert-news19c
#SBATCH --output="argo-out/logs/convert-news19c-%A_%a.out"
#SBATCH --mail-type=ALL
#SBATCH --mail-user=lmullen@gmu.edu
#SBATCH --partition=all-HiPri
#SBATCH --export=NONE
#SBATCH --array=1-30000

## Load modules since we are not exporting our environment
module load R/3.4.1

## Get the file name associated with that line of the list of files
BATCH_LIST=./bin/news19c-issue-list.txt
BATCH=$(sed -n "${SLURM_ARRAY_TASK_ID}p" $BATCH_LIST)
INPUT=news19c-issues/$BATCH
INPUT_ID=$(basename "$INPUT")
OUTPUT_META=argo-out/news19c-metadata/$INPUT_ID-metadata.csv
OUTPUT_TEXT=argo-out/news19c-texts/$INPUT_ID-texts.feather

## Run the executable only if output does not exist
echo "Job details: BATCH=$BATCH TASKID: $SLURM_ARRAY_TASK_ID"
echo "Input files is $INPUT"
if [ -f "$OUTPUT_META" ] && [ -f "$OUTPUT_TEXT" ]; then
  echo "SKIPPED: Not running task because $OUTPUT_META and $OUTPUT_TEXT already exist"
else
  echo "RUNNING: Starting script to create $OUTPUT_META and $OUTPUT_TEXT"
  Rscript ./bin/convert-news19c-issue.R \
    $INPUT \
    --metadata $OUTPUT_META \
    --texts $OUTPUT_TEXT && \
  echo "FINISHED: Finished script to create $OUTPUT_META and $OUTPUT_TEXT"
fi
