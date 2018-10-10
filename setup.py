import os
import urllib.request
from zipfile import ZipFile
from setuptools import setup, Extension
from Cython.Build import cythonize
import numpy as np


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
        "qpbo._qpbo",
        [
            "qpbo/src/_qpbo.pyx",
            "qpbo/src/core/QPBO.cpp",
            "qpbo/src/core/QPBO_extra.cpp",
            "qpbo/src/core/QPBO_maxflow.cpp",
            "qpbo/src/core/QPBO_postprocessing.cpp",
        ],
        language="c++",
        include_dirs=[
            numpy_include_dir,
        ]
    )
    return cythonize([maxflow_module])


setup(name='qpbo-lite',
      packages=['qpbo'],
      version="0.1.0",
      author="Niels Jeppesen",
      author_email="niejep@dtu.dk",
      description='QPBO for Python',
      url="",
      ext_modules=LazyCythonize(extensions),
      requires=['numpy', 'Cython']
      )
