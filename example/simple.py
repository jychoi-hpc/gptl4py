from mpi4py import MPI
import gptl4py as gp

comm = MPI.COMM_WORLD
size = comm.Get_size()
rank = comm.Get_rank()

gp.hello_world()

gp.setoption("PAPI_TOT_INS")
#gp.setoption("example:::EXAMPLE_CONSTANT")
#gp.setoption("nvml:::Tesla_V100-SXM2-16GB:device_0:gpu_utilization")
gp.initialize()

for _ in range(10):
    gp.start("foo")
    for i in range(1000):
        pass
    gp.stop("foo")

gp.pr(0)
gp.pr_summary()
gp.finalize()
