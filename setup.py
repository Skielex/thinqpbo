from setuptools import setup, Extension
from Cython.Build import cythonize
import numpy as np


with open("README.md", "r") as fh:
    long_description = fh.read()


class LazyCythonize(list):
    def __init__(self, callback):
        self._list, self.callback = None, callback

    def c_list(self):
        if self._list is None:
            self._list = self.callback()
        return self._list

    def __iter__(self):
        for e in self.c_list():
            yield e

    def __getitem__(self, ii): return self.c_list()[ii]

    def __len__(self): return len(self.c_list())


def extensions():

    numpy_include_dir = np.get_include()

    maxflow_module = Extension(
        "thinqpbo._qpbo",
        [
            "thinqpbo/src/_qpbo.pyx",
            "thinqpbo/src/core/QPBO.cpp",
            "thinqpbo/src/core/QPBO_extra.cpp",
            "thinqpbo/src/core/QPBO_maxflow.cpp",
            "thinqpbo/src/core/QPBO_postprocessing.cpp",
        ],
        language="c++",
        include_dirs=[
            numpy_include_dir,
        ]
    )
    return cythonize([maxflow_module])


setup(name="thinqpbo",
      version="0.1.0",
      author="Niels Jeppesen",
      author_email="niejep@dtu.dk",
      description="A thin QPBO wrapper for Python",
      long_description=long_description,
      url="https://github.com/Skielex/thinqpbo",
      packages=["thinqpbo"],
      classifiers=[
          "Development Status :: 3 - Alpha",
          "Environment :: Console",
          "Intended Audience :: Developers",
          "Intended Audience :: Science/Research",
          "License :: OSI Approved :: GNU General Public License (GPL)",
          "Natural Language :: English",
          "Operating System :: OS Independent",
          "Programming Language :: C++",
          "Programming Language :: Python",
          "Topic :: Scientific/Engineering :: Image Recognition",
          "Topic :: Scientific/Engineering :: Artificial Intelligence",
          "Topic :: Scientific/Engineering :: Mathematics"
      ],
      ext_modules=LazyCythonize(extensions),
      requires=["numpy", "Cython"],
      setup_requires=['numpy', 'Cython']
      )
