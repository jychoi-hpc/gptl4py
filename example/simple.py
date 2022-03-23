from mpi4py import MPI
import gptl4py as gp

comm = MPI.COMM_WORLD
size = comm.Get_size()
rank = comm.Get_rank()

gp.hello_world()

gp.initialize()

gp.start("foo")
for i in range(1000):
    pass
gp.stop("foo")
gp.pr(0)

gp.pr_summary()
gp.finalize()