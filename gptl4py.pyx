# cython: language_level=3

import mpi4py.MPI as MPI
cimport mpi4py.MPI as MPI

cdef extern from "mpi.h":
    ctypedef struct MPI_Comm:
        pass

cdef extern from "gptl.h":
    ctypedef struct MPI_Comm:
        pass

    cdef void GPTLinitialize ();
    cdef int GPTLfinalize ();
    cdef int GPTLstart (const char *);
    cdef int GPTLstop (const char *);
    cdef int GPTLpr (const int);
    cdef int GPTLpr_file (const char *);
    cdef int GPTLpr_summary (MPI_Comm comm);
    cdef int GPTLpr_summary_file (MPI_Comm, const char *);

from cpython.version cimport PY_MAJOR_VERSION

cdef extern from "string.h" nogil:
    char   *strdup  (const char *s)
    size_t strlen   (const char *s)

## bytes-to-str problem for supporting both python2 and python3
## python2: str(b"") return str
## python3: str(b"") return 'b""'. Correct way: b"".decode()

cpdef str b2s(bytes x):
    if PY_MAJOR_VERSION < 3:
        return str(x)
    else:
        return x.decode()

cpdef bytes s2b(str x):
    if PY_MAJOR_VERSION < 3:
        return <bytes>x
    else:
        return strdup(x.encode())

cpdef initialize():
    GPTLinitialize()

cpdef finalize():
    GPTLfinalize()

cpdef pr(int):
    GPTLpr(int)

cpdef pr_file(str name):
    GPTLpr_file(s2b(name))

cpdef start(str name):
    GPTLstart(s2b(name))

cpdef stop(str name):
    GPTLstop(s2b(name))

cpdef pr_summary(MPI.Comm comm = MPI.COMM_WORLD):
    GPTLpr_summary(comm.ob_mpi)

cpdef pr_summary_file(str name, MPI.Comm comm = MPI.COMM_WORLD):
    GPTLpr_summary_file(comm.ob_mpi, s2b(name))

def hello_world():
    print("hello world")