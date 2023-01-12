# Create log files for each query that is run
LOG_SECOND=`date +%s`
LOGFILE="logs/$0.txt.$LOG_SECOND"
mkdir -p logs

# This is the IP address of the master node for your spark cluster
MASTER="yarn"

# Set this value to 5 times the number of GPUs you have in the cluster.
# We have found that 5 CPU cores per GPU executor performs better than
# having a higher number of cores. e.g. If you have 8 GPUs in your cluster
# set this value to 40.
TOTAL_CORES=16
#
# Set this value to the number of GPUs that you have within your cluster. If
# each server has 2 GPUs count that as 2
NUM_EXECUTORS=2   # change to fit how many GPUs you have
#
NUM_EXECUTOR_CORES=$((${TOTAL_CORES}/${NUM_EXECUTORS}))
#
# This setting needs to be a decimal equivalent to the ratio of cores to
# executors. In our example we have 40 cores and 8 executors. So, this
# would be 1/5, hench the 0.1 value.

RESOURCE_GPU_AMT="0.125"

# Set this to the total memory across all your worker nodes. e.g. 8 server
# with 96GB of ram = 768
TOTAL_MEMORY=50   # unit: GB
DRIVER_MEMORY=4    # unit: GB
#
# This takes the total memory and calculates the maximum amount of memory
# per executor
EXECUTOR_MEMORY=$(($((${TOTAL_MEMORY}-$((${DRIVER_MEMORY}*1000/1024))))/${NUM_EXECUTORS}))

# These paths need to be set based on what storage mediume you are using
#
# **** NOTE TRAILING SLASH IS REQUIRED FOR ALL PREFIXES
#
# Input prefix designates where the data to be processed is located
INPUT_PREFIX="hdfs:///data/10scale/"
#
# Output prefix is where results from the queries are stored
OUTPUT_PREFIX="hdfs:///data/10scale_output_gpu/"
