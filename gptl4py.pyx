# cython: language_level=3
from __future__ import absolute_import
from functools import wraps
from contextlib import contextmanager

import mpi4py.MPI as MPI
cimport mpi4py.MPI as MPI

cdef extern from "mpi.h":
    ctypedef struct MPI_Comm:
        pass

cdef extern from "gptl.h":
    ctypedef struct MPI_Comm:
        pass

    ctypedef enum GPTLoption:
        GPTL_IPC

    cdef int GPTLsetoption (const int, const int);
    cdef int GPTLinitialize ();
    cdef int GPTLfinalize ();
    cdef int GPTLstart (const char *);
    cdef int GPTLstop (const char *);
    cdef int GPTLpr (const int);
    cdef int GPTLpr_file (const char *);
    cdef int GPTLreset ();
    cdef int GPTLreset_timer (const char *);
    cdef int GPTLenable ();
    cdef int GPTLdisable ();

cdef extern from "gptlmpi.h":
    cdef int GPTLpr_summary (MPI_Comm comm);
    cdef int GPTLpr_summary_file (MPI_Comm, const char *);

cdef extern from "papi.h":
    ctypedef enum:
        PAPI_TOT_INS

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

cpdef int setoption(int option, int val):
    return GPTLsetoption(option, val)

cpdef int initialize():
    ret = GPTLsetoption (GPTL_IPC, 1)
    ret = GPTLsetoption (PAPI_TOT_INS, 1)
    return GPTLinitialize()

cpdef int finalize():
    return GPTLfinalize()

cpdef int pr(int):
    return GPTLpr(int)

cpdef int pr_file(str name):
    return GPTLpr_file(s2b(name))

cpdef int start(str name):
    return GPTLstart(s2b(name))

cpdef int stop(str name):
    return GPTLstop(s2b(name))

cpdef int reset():
    return GPTLreset()

cpdef int reset_timer(str name):
    return GPTLreset_timer(s2b(name))

cpdef int pr_summary(MPI.Comm comm = MPI.COMM_WORLD):
    return GPTLpr_summary(comm.ob_mpi)

cpdef int pr_summary_file(str name, MPI.Comm comm = MPI.COMM_WORLD):
    return GPTLpr_summary_file(comm.ob_mpi, s2b(name))

cpdef int enable():
    return GPTLenable()

cpdef int disable():
    return GPTLdisable()

def hello_world():
    print("hello world")

def profile(x_or_func=None, *decorator_args, **decorator_kws):
    def _decorator(func):
        @wraps(func)
        def wrapper(*args, **kws):
            if 'x_or_func' not in locals() or callable(x_or_func) or x_or_func is None:
                x = func.__name__
            else:
                x = x_or_func
            start(x)
            out = func(*args, **kws)
            stop(x)
            return out
        return wrapper

    return _decorator(x_or_func) if callable(x_or_func) else _decorator

@contextmanager
def timer(x):
    start(x)
    yield
    stop(x)
