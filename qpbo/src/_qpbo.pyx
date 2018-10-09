# distutils: language = c++

from _QPBO cimport QPBO

cdef public class QPBOInt[object PyObject_QPBOInt, type QPBOInt]:
    cdef QPBO[int]* c_qpbo

    def __cinit__(self, int node_num_max, int edge_num_max):
        self.c_qpbo = new QPBO[int](node_num_max, edge_num_max)

    def __dealloc__(self):
        del self.c_qpbo

    def save(self, filename):
        filename_bytes = filename.encode('UTF-8')
        return self.c_qpbo.Save(filename_bytes)

    def load(self, filename):
        filename_bytes = filename.encode('UTF-8')
        return self.c_qpbo.Load(filename_bytes)

    def reset(self):
        self.c_qpbo.Reset()

    def add_node(self, int num):
        return self.c_qpbo.AddNode(num)

    def add_unary_term(self, int i, int E0, int E1):
        self.c_qpbo.AddUnaryTerm(i, E0, E1)

    def add_pairwise_term(self, int i, int j, int E00, int E01, int E10, int E11):
        return self.c_qpbo.AddPairwiseTerm(i, j, E00, E01, E10, E11)

    def add_pairwise_term(self, int e, int i, int j, int E00, int E01, int E10, int E11):
        self.c_qpbo.AddPairwiseTerm(e, i, j, E00, E01, E10, E11)

    