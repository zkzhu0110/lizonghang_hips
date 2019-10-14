import argparse
import mxnet as mx
from mxnet import init, nd
from mxnet.gluon import loss as gloss
from mxnet.gluon import Trainer
from config import *

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("-l", "--learning-rate", type=float, default=LEARNING_RATE)
    parser.add_argument("-b", "--batch-size", type=int, default=BATCH_SIZE)
    parser.add_argument("-le", "--num-local-epochs", type=int, default=NUM_LOCAL_EPOCHS)
    parser.add_argument("-dd", "--data-dir", type=str, default=DATA_DIR)
    parser.add_argument("-dt", "--data-type", type=str, default=DATA_TYPE)
    parser.add_argument("-g", "--gpu", type=int, default=DEFAULT_GPU_ID)
    parser.add_argument("-c", "--cpu", type=int, default=USE_CPU)
    parser.add_argument("-n", "--network", type=str, default=NETWORK)
    parser.add_argument("-ld", "--log-dir", type=str, default=LOG_DIR)
    parser.add_argument("-e", "--eval-duration", type=int, default=EVAL_DURATION)
    parser.add_argument("-m", "--mode", type=str, default=MODE)
    parser.add_argument("-dcasgd", "--use-dcasgd", type=int, default=USE_DCASGD)
    parser.add_argument("-s", "--split-by-class", type=int, default=SPLIT_BY_CLASS)
    parser.add_argument("-ds", "--data-slice-idx", type=int, default=0)
    parser.add_argument("-gc", "--use-2bit-compression", type=int, default=USE_2BIT_COMPRESSION)
    args, unknown = parser.parse_known_args()

    lr = args.learning_rate
    batch_size = args.batch_size
    num_local_epochs = args.num_local_epochs
    data_dir = args.data_dir
    data_type = args.data_type.lower()
    network = args.network
    eval_duration = args.eval_duration
    log_dir = args.log_dir
    ctx = mx.cpu() if args.cpu else mx.gpu(args.gpu)
    mode = args.mode
    use_dcasgd = args.use_dcasgd
    split_by_class = args.split_by_class
    data_slice_idx = args.data_slice_idx
    use_2bit_compression = args.use_2bit_compression

    if data_type == "fashion-mnist":
        depth = 1
        shape = (batch_size, depth, 28, 28)
    elif data_type == "cifar10":
        depth = 3
        shape = (batch_size, depth, 32, 32)
    else:
        raise NotImplementedError("Dataset %s not support." % data_type)

    net = None
    if network == "resnet18-v1":
        from symbols.resnet import resnet18_v1
        net = resnet18_v1(classes=10)
    elif network == "resnet50-v1":
        from symbols.resnet import resnet50_v1
        net = resnet50_v1(classes=10)
    elif network == "resnet50-v2":
        from symbols.resnet import resnet50_v2
        net = resnet50_v2(classes=10)
    elif network == "alexnet":
        from symbols.alexnet import alexnet
        net = alexnet(classes=10)
        shape = (batch_size, depth, 224, 224)
    elif network == "mobilenet-v1":
        from symbols.mobilenet import mobilenet1_0
        net = mobilenet1_0(classes=10)
    elif network == "mobilenet-v2":
        from symbols.mobilenet import mobilenet_v2_1_0
        net = mobilenet_v2_1_0(classes=10)
    elif network == "inception-v3":
        from symbols.inception import inception_v3
        net = inception_v3(classes=10)
        shape = (batch_size, depth, 299, 299)
    else:
        from symbols.simplenet import simplenet
        net = simplenet(classes=10)
    net.initialize(init=init.Xavier(), ctx=ctx)
    net(nd.random.uniform(shape=shape, ctx=ctx))

    loss = gloss.SoftmaxCrossEntropyLoss()
    local_trainer = Trainer(net.collect_params(), "sgd", {"learning_rate": lr})

    kwargs = {
        "lr": lr,
        "batch_size": batch_size,
        "num_local_epochs": num_local_epochs,
        "data_dir": data_dir,
        "data_type": data_type,
        "log_dir": log_dir,
        "eval_duration": eval_duration,
        "ctx": ctx,
        "shape": shape,
        "net": net,
        "loss": loss,
        "trainer": local_trainer,
        "split_by_class": split_by_class,
        "data_slice_idx": data_slice_idx,
        "use_2bit_compression": use_2bit_compression,
    }

    if mode == "sync":
        from trainer.sync_trainer import trainer
        trainer(kwargs)
    elif mode == "async":
        from trainer.async_trainer import trainer
        kwargs.update({
            "use_dcasgd": use_dcasgd
        })
        trainer(kwargs)
    elif mode == "local":
        from trainer.local_trainer import trainer
        trainer(kwargs)
    else:
        raise NotImplementedError("Not Implemented.")
