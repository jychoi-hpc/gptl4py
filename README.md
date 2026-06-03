# GPTL4py

Python bindings for the [General Purpose Timing Library (GPTL)](https://jmrosinski.github.io/GPTL/).

## Overview

gptl4py provides Python/Cython bindings for GPTL, a C library for profiling and timing code in HPC and MPI environments. It supports manual timer brackets, decorators, context managers, and optional PAPI hardware counter integration.

## Requirements

- Python 3
- Cython
- mpi4py
- GPTL (external C library)
- PAPI (optional, for hardware counter support)

## Build and Install

```sh
pip install .
```

Set `GPTL_DIR` before installing (required), and optionally `PAPI_DIR` for hardware counter support:

```sh
GPTL_DIR=/path/to/gptl CC=mpicc pip install .

# With PAPI support
GPTL_DIR=/path/to/gptl PAPI_DIR=/path/to/papi CC=mpicc pip install .
```

## Quick Start

> **Note:** `setoption()` must be called before `initialize()`.

```python
import gptl4py as gp

gp.setoption("GPTLwall")   # must be called before initialize()
gp.initialize()

# Option 1: manual brackets
gp.start("my_timer")
do_work()
gp.stop("my_timer")

# Option 2: decorator (uses function name as timer label)
@gp.profile
def do_work():
    ...
do_work()

# Option 3: context manager
with gp.timer("my_timer"):
    do_work()

gp.pr_summary()
gp.finalize()
```

## API Reference

### Lifecycle

| Function | Description |
|---|---|
| `initialize()` | Initialize GPTL |
| `finalize()` | Finalize and free GPTL resources |

### Timers

| Function | Description |
|---|---|
| `start(name)` | Start a named timer |
| `stop(name)` | Stop a named timer |
| `reset()` | Reset all timers |
| `reset_timer(name)` | Reset a specific timer |
| `enable()` | Enable timing globally |
| `disable()` | Disable timing globally |
| `@profile` | Decorator — wraps a function with `start`/`stop` using the function name |
| `timer(name)` | Context manager — wraps a block with `start`/`stop` |

### Querying

| Function | Description |
|---|---|
| `query(name)` | Return the latest wallclock time for a timer |
| `query_raw(name)` | Return `(count, wallclock)` tuple for a timer |

### Reporting

| Function | Description |
|---|---|
| `pr(rank)` | Print timing report to stdout for the given MPI rank |
| `pr_file(name)` | Write timing report to a file |
| `pr_summary(comm)` | Print MPI-aggregated summary (default: `MPI.COMM_WORLD`) |
| `pr_summary_file(name, comm)` | Write MPI-aggregated summary to a file |

### Options

Options must be set before calling `initialize()`.

```python
gp.setoption("GPTLwall")       # enable wallclock timing
gp.setoption("GPTLcpu")        # enable CPU timing
gp.setoption("GPTLmultiplex")  # enable PAPI multiplexing
gp.setoption("PAPI_TOT_INS")   # enable a PAPI hardware counter (requires PAPI)
```

Available option strings: `GPTLsync_mpi`, `GPTLwall`, `GPTLcpu`, `GPTLabort_on_error`, `GPTLoverhead`, `GPTLdepthlimit`, `GPTLverbose`, `GPTLnarrowprint`, `GPTLpercent`, `GPTLpersec`, `GPTLmultiplex`, and any PAPI event name when built with PAPI support.

## Examples

See the [`example/`](example/) directory for a complete MPI example.
