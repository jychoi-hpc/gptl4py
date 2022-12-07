# from conf.mpidistutils import setup
from setuptools import setup, find_packages
from setuptools.extension import Extension
from Cython.Build import cythonize

import os
import sys

include_dirs = list()
library_dirs = list()
libraries = list()
gptl_lib_dir = None
if os.getenv("GPTL_DIR") is not None:
    gptl_dir = os.environ.get("GPTL_DIR")
    gptl_include_dir = os.path.join(gptl_dir, "include")
    gptl_lib_dir = os.path.join(gptl_dir, "lib")
    include_dirs.append(gptl_include_dir)
    library_dirs.append(gptl_lib_dir)
    libraries.append("gptl")
else:
    raise Exception("GPTL_DIR env is not set.")

USE_PAPI = False
if os.getenv("PAPI_DIR") is not None:
    USE_PAPI = True
    papi_dir = os.environ.get("PAPI_DIR")
    papi_include_dir = os.path.join(papi_dir, "include")
    papi_lib_dir = os.path.join(papi_dir, "lib")
    include_dirs.append(papi_include_dir)
    library_dirs.append(papi_lib_dir)
    libraries.append("papi")

extensions = [
    Extension(
        "gptl4py",
        ["gptl4py.pyx"],
        include_dirs=include_dirs,
        library_dirs=library_dirs,
        libraries=libraries,
        extra_compile_args=["-DHAVE_MPI"],
        extra_link_args=["-fopenmp", "-Wl,-rpath,%s" % gptl_lib_dir],
    ),
]

setup(name="gptl4py", packages=find_packages(), ext_modules=cythonize(extensions, compile_time_env={"USE_PAPI": USE_PAPI}))
