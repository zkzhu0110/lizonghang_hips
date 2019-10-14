# for train
LEARNING_RATE = 0.001
BATCH_SIZE = 32
NETWORK = "alexnet"
MODE = "sync"
USE_DCASGD = 0
SPLIT_BY_CLASS = 0
NUM_LOCAL_EPOCHS = 1
USE_2BIT_COMPRESSION = 0
DATA_DIR = "/root/data"
DATA_TYPE = "cifar10"

# for evaluation
EVAL_DURATION = 1
LOG_DIR = "logs"

# devices
USE_CPU = 0
DEFAULT_GPU_ID = 0
