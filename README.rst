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

  gp.initialize()

  gp.start("count")
  for i in range(1000):
      pass
  gp.stop("count")

  ## Or, use with a decorator
  @gp.profile
  def count():
    for i in range(1000):
        pass
  count()

  gp.pr_summary()
  gp.finalize()


For more details, check `example` directory.