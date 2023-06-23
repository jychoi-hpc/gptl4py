===============
GPTL for Python
===============

Python bindings for General Purpose Timing Library (GPTL).

Overview
--------

This package provides Python bindings for General Purpose Timing Library (GPTL).

Build and install
-----------------

.. code-block:: rst

  GPTL_DIR=/dir/to/gptl CC=mpicc python setup.py install --prefix=/dir/to/install


Quick Start
-----------

.. code-block:: python
  
  import gptl4py as gp

  gp.start("foo")
  for i in range(1000):
      pass
  gp.stop("foo")

  gp.pr_summary()
  gp.finalize()

For more details, check `example` directory.