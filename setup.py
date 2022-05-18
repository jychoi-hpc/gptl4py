# from conf.mpidistutils import setup
from setuptools import setup, find_packages
from setuptools.extension import Extension
from Cython.Build import cythonize

import os

gptl_dir = os.environ.get("GPTL_DIR")
gptl_include_dir = os.path.join(gptl_dir, "include")
gptl_lib_dir = os.path.join(gptl_dir, "lib")

papi_dir = os.environ.get("PAPI_DIR")
papi_include_dir = os.path.join(papi_dir, "include")
papi_lib_dir = os.path.join(papi_dir, "lib")

extensions = [
    Extension(
        "gptl4py",
        ["gptl4py.pyx"],
        include_dirs=[gptl_include_dir,papi_include_dir],
        libraries=["gptl","papi"],
        library_dirs=[gptl_lib_dir,papi_lib_dir],
        extra_compile_args=["-DHAVE_MPI"],
        extra_link_args=["-fopenmp","-Wl,-rpath=%s"%gptl_lib_dir],
    ),
]

setup(name="gptl4py", packages=find_packages(), ext_modules=cythonize(extensions))
