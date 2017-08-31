#!/bin/bash
## Specify Job name if you want; Short option form -J
#SBATCH --job-name=convert-chronam-batches
##
## Specify output file name
## If you want output and error to be written to different files
## You will need to provide output and error file names ## short form -o
#SBATCH --output=R-%N-%j.output
##
## %N is the name of the node on which it ran ## %j is the job-id
## NOTE: this format has to be changed if Array job
## filename-%A-%a.out - where A is job ID and a is the array index ##
## Specify error file name
## short form -e
#SBATCH --error=R-%N-%j.error
##
## Send email
#SBATCH --mail-user=lmullen@gmu.edu
##
## Email notification for the following types
## Some valid types are: NONE,BEGIN,END,FAIL,REQUEUE, TIME_LIMIT_XX
#SBATCH --mail-type=BEGIN,END,FAIL,REQUEUE
##
## Select partition to run this job
## Default partition is all-HiPri - run time limit is 12 hours ## short form -p
#SBATCH --partition=all-HiPri
##
## How much memory job needs specified in MB
## Default Memory is 2048MB
##SBATCH --mem=2048
##
## Time needed for the job to run ## format D-HH:MM:SS
##SBATCH --time=0-00:15:00
##
## Don’t export my current environment
## NOTE: if you use this option, you have to load modules explicitly
#SBATCH --export=NONE
##
## Load modules since we are not exporting our environment
module load R/3.4.1
##
## Run the executable
Rscript ./bin/chronam-batch-to-dataframe.R \
  --debug \
  --log argo-out/logs/convert-chronam-batches-`date --iso-8601=seconds`.log \
  chronam-batches/batch_wvu_jordan_ver03.tar.bz2 \
  -o argo-out/chronam-df/batch_wvu_jordan_ver03.tar.bz2.feather
