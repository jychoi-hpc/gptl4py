# from conf.mpidistutils import setup
from setuptools import setup, find_packages
from setuptools.extension import Extension
from Cython.Build import cythonize

extensions = [
    Extension(
        "gptl4py",
        ["gptl4py.pyx"],
        include_dirs=['/Users/jyc/sw/camtimers/devel/gcc/include'], 
        libraries=['timers'],
        library_dirs=['/Users/jyc/sw/camtimers/devel/gcc/lib'],
        extra_compile_args = ['-DHAVE_MPI'],
        extra_link_args = ['-fopenmp'],
    ),
]

setup(
    name = "gptl4py",
    packages = find_packages(),
    ext_modules = cythonize(extensions)
)