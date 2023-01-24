# Create log files for each query that is run
LOG_SECOND=`date +%s`
LOGFILE="logs/$0.txt.$LOG_SECOND"
mkdir -p logs

# This is the IP address of the master node for your spark cluster
MASTER="yarn"

# Set this value to the total number of cores that you have across all
# your worker nodes. e.g. 8 servers with 40 cores = 320 cores
# NOTE: The number or executors (GPUs) needs to divide equally into the number
# of cores. Reduce the core count until you get a round number.
# In this example the servers have 320 cores, but that is not a round number
# so we will reduce this to 240. This matters because we have to slice up
# the GPU resources to be equal to the number of cores
TOTAL_CORES=16
#
# Set this value to 1/4 the number of cores listed above. Generally,
# we have found that 4 cores per executor performs well.
NUM_EXECUTORS=2  # 1/4 the number of cores in the cluster
#
NUM_EXECUTOR_CORES=$((${TOTAL_CORES}/${NUM_EXECUTORS}))
#
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
OUTPUT_PREFIX="hdfs:///data/10scale_output/"

