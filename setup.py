from setuptools import setup, find_packages
from setuptools.extension import Extension
from Cython.Build import cythonize

import os
import subprocess
import tarfile
import urllib.request

GPTL_VERSION = "8.1.1"
# Release asset tarball includes pre-generated configure; GitHub archive does not.
GPTL_URL = f"https://github.com/jmrosinski/GPTL/releases/download/v{GPTL_VERSION}/gptl-{GPTL_VERSION}.tar.gz"
_HERE = os.path.dirname(os.path.abspath(__file__))
GPTL_INSTALL_DIR = os.path.join(_HERE, "_gptl_install")


def bootstrap_gptl():
    marker = os.path.join(GPTL_INSTALL_DIR, "include", "gptl.h")
    if os.path.exists(marker):
        print(f"Using cached GPTL build at {GPTL_INSTALL_DIR}")
        return GPTL_INSTALL_DIR

    import tempfile
    print(f"GPTL_DIR not set — downloading GPTL v{GPTL_VERSION} and building statically...")

    with tempfile.TemporaryDirectory() as tmpdir:
        tarball = os.path.join(tmpdir, "gptl.tar.gz")
        urllib.request.urlretrieve(GPTL_URL, tarball)

        with tarfile.open(tarball) as tf:
            tf.extractall(tmpdir)

        src_dir = os.path.join(tmpdir, f"gptl-{GPTL_VERSION}")
        def run(args, **kwargs):
            result = subprocess.run(args, cwd=src_dir, capture_output=True, text=True, **kwargs)
            if result.returncode != 0:
                raise RuntimeError(
                    f"Command {args} failed (exit {result.returncode}):\n"
                    f"STDOUT:\n{result.stdout}\nSTDERR:\n{result.stderr}"
                )

        if not os.path.exists(os.path.join(src_dir, "configure")):
            run(["autoreconf", "-i"])

        # GPTL 8.1.1 bug: --disable-fortran skips the AM_CONDITIONAL for
        # HAVE_FORT_OPENMP, causing autoconf to error "conditional was never defined".
        # Patch: pre-initialize the variable to disabled before the check fires.
        configure_path = os.path.join(src_dir, "configure")
        with open(configure_path) as f:
            configure_text = f.read()
        patched = configure_text.replace(
            'if test -z "${HAVE_FORT_OPENMP_TRUE}" && test -z "${HAVE_FORT_OPENMP_FALSE}"; then',
            ': ${HAVE_FORT_OPENMP_TRUE=\'#\'}; : ${HAVE_FORT_OPENMP_FALSE=\'\'}\n'
            'if test -z "${HAVE_FORT_OPENMP_TRUE}" && test -z "${HAVE_FORT_OPENMP_FALSE}"; then',
        )
        if patched == configure_text:
            print("Warning: HAVE_FORT_OPENMP patch target not found in configure script; skipping patch.")
        else:
            with open(configure_path, "w") as f:
                f.write(patched)

        run(["./configure", f"--prefix={GPTL_INSTALL_DIR}", "--enable-static", "--disable-shared", "--with-pic", "--disable-fortran"])
        run(["make", "-j4"])
        run(["make", "install"])

    return GPTL_INSTALL_DIR


include_dirs = []
library_dirs = []
libraries = []
extra_objects = []
extra_link_args = ["-fopenmp"]

if os.getenv("GPTL_DIR"):
    gptl_dir = os.environ["GPTL_DIR"]
    gptl_lib_dir = os.path.join(gptl_dir, "lib")
    include_dirs.append(os.path.join(gptl_dir, "include"))
    library_dirs.append(gptl_lib_dir)
    libraries.append("gptl")
    extra_link_args.append(f"-Wl,-rpath,{gptl_lib_dir}")
else:
    gptl_dir = bootstrap_gptl()
    include_dirs.append(os.path.join(gptl_dir, "include"))
    extra_objects.append(os.path.join(gptl_dir, "lib", "libgptl.a"))

USE_PAPI = False
if os.getenv("PAPI_DIR"):
    USE_PAPI = True
    papi_dir = os.environ["PAPI_DIR"]
    papi_lib_dir = os.path.join(papi_dir, "lib")
    include_dirs.append(os.path.join(papi_dir, "include"))
    library_dirs.append(papi_lib_dir)
    libraries.append("papi")

extensions = [
    Extension(
        "gptl4py",
        ["gptl4py.pyx"],
        include_dirs=include_dirs,
        library_dirs=library_dirs,
        libraries=libraries,
        extra_objects=extra_objects,
        extra_compile_args=["-DHAVE_MPI"],
        extra_link_args=extra_link_args,
    ),
]

setup(name="gptl4py", version="1.0.0", packages=find_packages(), ext_modules=cythonize(extensions, compile_time_env={"USE_PAPI": USE_PAPI}))
