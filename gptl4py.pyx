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
        GPTLsync_mpi,
        GPTLwall,
        GPTLcpu,
        GPTLabort_on_error,
        GPTLoverhead,
        GPTLdepthlimit,
        GPTLverbose,
        GPTLnarrowprint,
        GPTLpercent,
        GPTLpersec,
        GPTLmultiplex
        
    cdef int GPTLsetoption (const int, const int)
    cdef int GPTLinitialize ()
    cdef int GPTLfinalize ()
    cdef int GPTLstart (const char *)
    cdef int GPTLstop (const char *)
    cdef int GPTLpr (const int)
    cdef int GPTLpr_file (const char *)
    cdef int GPTLreset ()
    cdef int GPTLreset_timer (const char *)
    cdef int GPTLenable ()
    cdef int GPTLdisable ()
    cdef int GPTLquery (const char *name, int t, int *count, int *onflg, double *wallclock, double *dusr, double *dsys, long long *papicounters_out, const int maxcounters)
    cdef int GPTLget_wallclock_latest (const char *name, int t, double *value)

IF USE_PAPI:
    cdef int GPTLevent_name_to_code(const char *, int *)

cdef extern from "gptlmpi.h":
    cdef int GPTLpr_summary (MPI_Comm comm)
    cdef int GPTLpr_summary_file (MPI_Comm, const char *)

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

cpdef int setoption(str option, int val=1):
    cdef int opt
    cdef int ret

    if option == "GPTLsync_mpi":
        opt = GPTLsync_mpi
    elif option == "GPTLwall":
        opt = GPTLwall
    elif option == "GPTLcpu":
        opt = GPTLcpu
    elif option == "GPTLabort_on_error":
        opt = GPTLabort_on_error
    elif option == "GPTLoverhead":
        opt = GPTLoverhead
    elif option == "GPTLdepthlimit":
        opt = GPTLdepthlimit
    elif option == "GPTLverbose":
        opt = GPTLverbose
    elif option == "GPTLnarrowprint":
        opt = GPTLnarrowprint
    elif option == "GPTLpercent":
        opt = GPTLpercent
    elif option == "GPTLpersec":
        opt = GPTLpersec
    elif option == "GPTLmultiplex":
        opt = GPTLmultiplex
    else:
        IF USE_PAPI:
            ret = GPTLevent_name_to_code(s2b(option), &opt)
        ELSE:
            pass
    return GPTLsetoption(opt, val)

cpdef int initialize():
    # ret = GPTLsetoption (GPTL_IPC, 1)
    # ret = GPTLsetoption (PAPI_TOT_INS, 1)
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

def query_raw(str name):
    cdef int t = -1
    cdef int count
    cdef int onflg
    cdef double wallclock
    cdef double dusr
    cdef double dsys
    cdef long long papicounters_out
    cdef int maxcounters = 1
    GPTLquery (s2b(name), t, &count, &onflg, &wallclock, &dusr, &dsys, &papicounters_out, maxcounters)
    return (count, wallclock)

def query(str name):
    cdef int t = -1
    cdef double value
    GPTLget_wallclock_latest (s2b(name), t, &value)
    return value

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

