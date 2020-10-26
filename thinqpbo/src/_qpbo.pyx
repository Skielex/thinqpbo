# distutils: language = c++

from .src._qpbo cimport QPBO, EdgeId, NodeId


cdef public class QPBOInt[object PyObject_QPBOInt, type QPBOInt]:
    cdef QPBO[int]* c_qpbo

    def __cinit__(self, int node_num_max=0, EdgeId edge_num_max=0):
        """Constructor. 
        The first argument gives an estimate of the maximum number of nodes that can be added
        to the graph, and the second argument is an estimate of the maximum number of edges.
        The last (optional) argument is the pointer to the function which will be called 
        if an error occurs; an error message is passed to this function. 
        If this argument is omitted, exit(1) will be called.
        
        IMPORTANT: 
        1. It is possible to add more nodes to the graph than node_num_max 
        (and node_num_max can be zero). However, if the count is exceeded, then 
        the internal memory is reallocated (increased by 50%) which is expensive. 
        Also, temporarily the amount of allocated memory would be more than twice than needed.
        Similarly for edges.
        
        2. If Probe() is used with option=1 or option=2, then it is advisable to specify
        a larger value of edge_num_max (e.g. twice the number of edges in the original energy).
        """
        self.c_qpbo = new QPBO[int](node_num_max, edge_num_max)

    def __dealloc__(self):
        """Destructor
        """
        del self.c_qpbo

    def save(self, filename):
        """Save current reparameterisation of the energy to a text file. (Note: possibly twice the energy is saved).
	    Returns true if success, false otherwise.
        """
        filename_bytes = filename.encode('UTF-8')
        return self.c_qpbo.Save(filename_bytes)

    def load(self, filename):
        """Load energy from a text file. Current terms of the energy (if any) are destroyed.
        Type identifier in the file (int/float/double) should match the type QPBO::REAL.
	    Returns true if success, false otherwise.
        """
        filename_bytes = filename.encode('UTF-8')
        return self.c_qpbo.Load(filename_bytes)

    def reset(self):
        """Removes all nodes and edges. 
        After that functions AddNode(), AddUnaryTerm(), AddPairwiseTerm() must be called again. 
        
        Advantage compared to deleting QPBO and allocating it again:
        no calls to delete/new (which could be quite slow).
        """
        self.c_qpbo.Reset()

    def add_node(self, int num):
        """Adds node(s) to the graph. By default, one node is added (num=1); then first call returns 0, second call returns 1, and so on. 
        If num>1, then several nodes are added, and NodeId of the first one is returned.
        IMPORTANT: see note about the constructor 
        """
        return self.c_qpbo.AddNode(num)

    def add_unary_term(self, NodeId i, int E0, int E1):
        """Adds unary term Ei(x_i) to the energy function with cost values Ei(0)=E0, Ei(1)=E1.
	    Can be called multiple times for each node.
        """
        self.c_qpbo.AddUnaryTerm(i, E0, E1)

    def add_pairwise_term(self, NodeId i, NodeId j, int E00, int E01, int E10, int E11):
        """Adds pairwise term Eij(x_i, x_j) with cost values E00, E01, E10, E11.
	    IMPORTANT: see note about the constructor 
        """
        return self.c_qpbo.AddPairwiseTerm(i, j, E00, E01, E10, E11)

    def modify_pairwise_term(self, EdgeId e, NodeId i, NodeId j, int E00, int E01, int E10, int E11):
        """This function modifies an already existing pairwise term.
        """
        self.c_qpbo.AddPairwiseTerm(e, i, j, E00, E01, E10, E11)

    def merge_parallel_edges(self):
        """If AddPairwiseTerm(i,j,...) has been called twice for some pairs of nodes,
        then MergeParallelEdges() must be called before calling Solve()/Probe()/Improve().
        """
        self.c_qpbo.MergeParallelEdges()

    def get_label(self, NodeId i):
        """Returns 0 or 1, if the node is labeled, and a negative number otherwise.
	    Can be called after Solve()/ComputeWeakPersistencies()/Probe()/Improve().
        """
        return self.c_qpbo.GetLabel(i)

    def set_label(self, NodeId i, char label):
        self.c_qpbo.SetLabel(i, label)

    def get_node_num(self):
        return self.c_qpbo.GetNodeNum()

    def get_twice_unary_term(self, NodeId i):
        cdef int E0, E1
        self.c_qpbo.GetTwiceUnaryTerm(i, E0, E1)
        return (E0, E1)

    def get_twice_pairwise_term(self, EdgeId e):
        cdef NodeId i, j
        cdef int E00, E01, E10, E11
        self.c_qpbo.GetTwicePairwiseTerm(e, i, j, E00, E01, E10, E11)
        return (i, j, E00, E01, E10, E11)

    def compute_twice_energy(self, int option=0):
        """Return energy bound.
        NOTE: in the current implementation Probe() may add constants to the energy
        during transormations, so after Probe() the energy/lower bound would be shifted by some offset.

        option == 0: returns 2 times the energy of internally stored solution which would be
                    returned by GetLabel(). Negative values (unknown) are treated as 0. 
        option == 1: returns 2 times the energy of solution set by the user (via SetLabel()).
        """
        return self.c_qpbo.ComputeTwiceEnergy(option)

    def compute_twice_lower_bound(self):
        """Returns the lower bound defined by current reparameterizaion.
        """
        return self.c_qpbo.ComputeTwiceLowerBound()

    def solve(self):
        """Runs QPBO. After calling Solve(), use GetLabel(i) to get label of node i.
	    Solve() produces a STRONGLY PERSISTENT LABELING. It means, in particular,
	    that if GetLabel(i)>=0 (i.e. node i is labeled) then x_i == GetLabel(i) for ALL global minima x.
        """
        self.c_qpbo.Solve()

    def compute_weak_persistencies(self):
        """Can only be called immediately after Solve()/Probe() (and before any modifications are made to the energy).
        Computes WEAKLY PERSISTENT LABELING. Use GetLabel() to read the result.
        NOTE: if the energy is submodular, then ComputeWeakPersistences() will label all nodes (in general, this is not necessarily true for Solve()).
        """
        self.c_qpbo.ComputeWeakPersistencies()

    def stitch(self):
        """GetRegion()/Stitch():
        ComputeWeakPersistencies() also splits pixels into regions (``strongly connected components'') U^0, U^1, ..., U^k as described in
        
            A. Billionnet and B. Jaumard. 
            A decomposition method for minimizing quadratic pseudoboolean functions. 
            Operation Research Letters, 8:161�163, 1989.	
    
        For a review see also 
    
            V. Kolmogorov, C. Rother
            Minimizing non-submodular functions with graph cuts - a review
            Technical report MSR-TR-2006-100, July 2006. To appear in PAMI.
    
        Nodes in U^0 are labeled, nodes in U^1, ..., U^k are unlabeled.
        (To find out to what region node i belongs, call GetRegion(i)).
        The user can use these regions as follows:
        -- For each r=1..k, compute somehow minimum x^r of the energy corresponding to region U^r.
            This energy can be obtained by calling GetPairwiseTerm() for edges inside the region.
            (There are no unary terms). Note that computing the global minimum is NP-hard;
            it is up to the user to decide how to solve this problem.
        -- Set the labeling by calling SetLabel().
        -- Call Stitch(). It will compute a complete global minimum (in linear time).
        -- Call GetLabel() for nodes in U^1, ..., U^k to read new solution.
        Note that if the user can provides approximate rather than global minima x^r, then the stitching
        can still be done but the result is not guaranteed to be a *global* minimum.
    
        GetRegion()/Stitch() can be called only immediately after ComputeWeakPersistencies().
        NOTE: Stitch() changes the stored energy!
        """
        self.c_qpbo.Stitch()

    def improve(self):
        """Tries to improve the labeling provided by the user (via SetLabel()).
        The new labeling is guaranteed to have the same or smaller energy than the input labeling.
        
        The procedure is as follows:
        1. Run QBPO
        2. Go through nodes in the order order_array[0], ..., order_array[N-1].
            If a node is unlabeled, fix it to the label provided by the user and run QBPO again.
        3. For remaining unlabeled nodes run set their labels to values provided by the user.
            (If order_array[] contains all nodes, then there should be no unlabeled nodes in step 3).
        
        New labeling can be obtained via GetLabel(). (The procedure also calls SetLabel() with
        new labels, so Improve() can be called again). Returns true if success 
        (i.e. the labeling has changed and, thus, the energy has decreased), and false otherwise.
        
        If array fixed_pixels of size nodeNum is provided, then it is set as follows:
        fixed_nodes[i] = 1 if node i was fixed during Improve(), and false otherwise.
        order_array and fixed_pixels can point to the same array.
        """
        return self.c_qpbo.Improve()


cdef public class QPBOFloat[object PyObject_QPBOFloat, type QPBOFloat]:
    cdef QPBO[float]* c_qpbo

    def __cinit__(self, int node_num_max=0, EdgeId edge_num_max=0):
        """Constructor. 
        The first argument gives an estimate of the maximum number of nodes that can be added
        to the graph, and the second argument is an estimate of the maximum number of edges.
        The last (optional) argument is the pointer to the function which will be called 
        if an error occurs; an error message is passed to this function. 
        If this argument is omitted, exit(1) will be called.
        
        IMPORTANT: 
        1. It is possible to add more nodes to the graph than node_num_max 
        (and node_num_max can be zero). However, if the count is exceeded, then 
        the internal memory is reallocated (increased by 50%) which is expensive. 
        Also, temporarily the amount of allocated memory would be more than twice than needed.
        Similarly for edges.
        
        2. If Probe() is used with option=1 or option=2, then it is advisable to specify
        a larger value of edge_num_max (e.g. twice the number of edges in the original energy).
        """
        self.c_qpbo = new QPBO[float](node_num_max, edge_num_max)

    def __dealloc__(self):
        """Destructor
        """
        del self.c_qpbo

    def save(self, filename):
        """Save current reparameterisation of the energy to a text file. (Note: possibly twice the energy is saved).
	    Returns true if success, false otherwise.
        """
        filename_bytes = filename.encode('UTF-8')
        return self.c_qpbo.Save(filename_bytes)

    def load(self, filename):
        """Load energy from a text file. Current terms of the energy (if any) are destroyed.
        Type identifier in the file (int/float/double) should match the type QPBO::REAL.
	    Returns true if success, false otherwise.
        """
        filename_bytes = filename.encode('UTF-8')
        return self.c_qpbo.Load(filename_bytes)

    def reset(self):
        """Removes all nodes and edges. 
        After that functions AddNode(), AddUnaryTerm(), AddPairwiseTerm() must be called again. 
        
        Advantage compared to deleting QPBO and allocating it again:
        no calls to delete/new (which could be quite slow).
        """
        self.c_qpbo.Reset()

    def add_node(self, int num):
        """Adds node(s) to the graph. By default, one node is added (num=1); then first call returns 0, second call returns 1, and so on. 
        If num>1, then several nodes are added, and NodeId of the first one is returned.
        IMPORTANT: see note about the constructor 
        """
        return self.c_qpbo.AddNode(num)

    def add_unary_term(self, NodeId i, float E0, float E1):
        """Adds unary term Ei(x_i) to the energy function with cost values Ei(0)=E0, Ei(1)=E1.
	    Can be called multiple times for each node.
        """
        self.c_qpbo.AddUnaryTerm(i, E0, E1)

    def add_pairwise_term(self, NodeId i, NodeId j, float E00, float E01, float E10, float E11):
        """Adds pairwise term Eij(x_i, x_j) with cost values E00, E01, E10, E11.
	    IMPORTANT: see note about the constructor 
        """
        return self.c_qpbo.AddPairwiseTerm(i, j, E00, E01, E10, E11)

    def modify_pairwise_term(self, EdgeId e, NodeId i, NodeId j, float E00, float E01, float E10, float E11):
        """This function modifies an already existing pairwise term.
        """
        self.c_qpbo.AddPairwiseTerm(e, i, j, E00, E01, E10, E11)

    def merge_parallel_edges(self):
        """If AddPairwiseTerm(i,j,...) has been called twice for some pairs of nodes,
        then MergeParallelEdges() must be called before calling Solve()/Probe()/Improve().
        """
        self.c_qpbo.MergeParallelEdges()

    def get_label(self, NodeId i):
        """Returns 0 or 1, if the node is labeled, and a negative number otherwise.
	    Can be called after Solve()/ComputeWeakPersistencies()/Probe()/Improve().
        """
        return self.c_qpbo.GetLabel(i)

    def set_label(self, NodeId i, char label):
        self.c_qpbo.SetLabel(i, label)

    def get_node_num(self):
        return self.c_qpbo.GetNodeNum()

    def get_twice_unary_term(self, NodeId i):
        cdef float E0, E1
        self.c_qpbo.GetTwiceUnaryTerm(i, E0, E1)
        return (E0, E1)

    def get_twice_pairwise_term(self, EdgeId e):
        cdef NodeId i, j
        cdef float E00, E01, E10, E11
        self.c_qpbo.GetTwicePairwiseTerm(e, i, j, E00, E01, E10, E11)
        return (i, j, E00, E01, E10, E11)

    def compute_twice_energy(self, int option=0):
        """Return energy bound.
        NOTE: in the current implementation Probe() may add constants to the energy
        during transormations, so after Probe() the energy/lower bound would be shifted by some offset.

        option == 0: returns 2 times the energy of internally stored solution which would be
                    returned by GetLabel(). Negative values (unknown) are treated as 0. 
        option == 1: returns 2 times the energy of solution set by the user (via SetLabel()).
        """
        return self.c_qpbo.ComputeTwiceEnergy(option)

    def compute_twice_lower_bound(self):
        """Returns the lower bound defined by current reparameterizaion.
        """
        return self.c_qpbo.ComputeTwiceLowerBound()

    def solve(self):
        """Runs QPBO. After calling Solve(), use GetLabel(i) to get label of node i.
	    Solve() produces a STRONGLY PERSISTENT LABELING. It means, in particular,
	    that if GetLabel(i)>=0 (i.e. node i is labeled) then x_i == GetLabel(i) for ALL global minima x.
        """
        self.c_qpbo.Solve()

    def compute_weak_persistencies(self):
        """Can only be called immediately after Solve()/Probe() (and before any modifications are made to the energy).
        Computes WEAKLY PERSISTENT LABELING. Use GetLabel() to read the result.
        NOTE: if the energy is submodular, then ComputeWeakPersistences() will label all nodes (in general, this is not necessarily true for Solve()).
        """
        self.c_qpbo.ComputeWeakPersistencies()

    def stitch(self):
        """GetRegion()/Stitch():
        ComputeWeakPersistencies() also splits pixels into regions (``strongly connected components'') U^0, U^1, ..., U^k as described in
        
            A. Billionnet and B. Jaumard. 
            A decomposition method for minimizing quadratic pseudoboolean functions. 
            Operation Research Letters, 8:161�163, 1989.	
    
        For a review see also 
    
            V. Kolmogorov, C. Rother
            Minimizing non-submodular functions with graph cuts - a review
            Technical report MSR-TR-2006-100, July 2006. To appear in PAMI.
    
        Nodes in U^0 are labeled, nodes in U^1, ..., U^k are unlabeled.
        (To find out to what region node i belongs, call GetRegion(i)).
        The user can use these regions as follows:
        -- For each r=1..k, compute somehow minimum x^r of the energy corresponding to region U^r.
            This energy can be obtained by calling GetPairwiseTerm() for edges inside the region.
            (There are no unary terms). Note that computing the global minimum is NP-hard;
            it is up to the user to decide how to solve this problem.
        -- Set the labeling by calling SetLabel().
        -- Call Stitch(). It will compute a complete global minimum (in linear time).
        -- Call GetLabel() for nodes in U^1, ..., U^k to read new solution.
        Note that if the user can provides approximate rather than global minima x^r, then the stitching
        can still be done but the result is not guaranteed to be a *global* minimum.
    
        GetRegion()/Stitch() can be called only immediately after ComputeWeakPersistencies().
        NOTE: Stitch() changes the stored energy!
        """
        self.c_qpbo.Stitch()

    def improve(self):
        """Tries to improve the labeling provided by the user (via SetLabel()).
        The new labeling is guaranteed to have the same or smaller energy than the input labeling.
        
        The procedure is as follows:
        1. Run QBPO
        2. Go through nodes in the order order_array[0], ..., order_array[N-1].
            If a node is unlabeled, fix it to the label provided by the user and run QBPO again.
        3. For remaining unlabeled nodes run set their labels to values provided by the user.
            (If order_array[] contains all nodes, then there should be no unlabeled nodes in step 3).
        
        New labeling can be obtained via GetLabel(). (The procedure also calls SetLabel() with
        new labels, so Improve() can be called again). Returns true if success 
        (i.e. the labeling has changed and, thus, the energy has decreased), and false otherwise.
        
        If array fixed_pixels of size nodeNum is provided, then it is set as follows:
        fixed_nodes[i] = 1 if node i was fixed during Improve(), and false otherwise.
        order_array and fixed_pixels can point to the same array.
        """
        return self.c_qpbo.Improve()


cdef public class QPBODouble[object PyObject_QPBODouble, type QPBODouble]:
    cdef QPBO[double]* c_qpbo

    def __cinit__(self, int node_num_max=0, EdgeId edge_num_max=0):
        """Constructor. 
        The first argument gives an estimate of the maximum number of nodes that can be added
        to the graph, and the second argument is an estimate of the maximum number of edges.
        The last (optional) argument is the pointer to the function which will be called 
        if an error occurs; an error message is passed to this function. 
        If this argument is omitted, exit(1) will be called.
        
        IMPORTANT: 
        1. It is possible to add more nodes to the graph than node_num_max 
        (and node_num_max can be zero). However, if the count is exceeded, then 
        the internal memory is reallocated (increased by 50%) which is expensive. 
        Also, temporarily the amount of allocated memory would be more than twice than needed.
        Similarly for edges.
        
        2. If Probe() is used with option=1 or option=2, then it is advisable to specify
        a larger value of edge_num_max (e.g. twice the number of edges in the original energy).
        """
        self.c_qpbo = new QPBO[double](node_num_max, edge_num_max)

    def __dealloc__(self):
        """Destructor
        """
        del self.c_qpbo

    def save(self, filename):
        """Save current reparameterisation of the energy to a text file. (Note: possibly twice the energy is saved).
	    Returns true if success, false otherwise.
        """
        filename_bytes = filename.encode('UTF-8')
        return self.c_qpbo.Save(filename_bytes)

    def load(self, filename):
        """Load energy from a text file. Current terms of the energy (if any) are destroyed.
        Type identifier in the file (int/float/double) should match the type QPBO::REAL.
	    Returns true if success, false otherwise.
        """
        filename_bytes = filename.encode('UTF-8')
        return self.c_qpbo.Load(filename_bytes)

    def reset(self):
        """Removes all nodes and edges. 
        After that functions AddNode(), AddUnaryTerm(), AddPairwiseTerm() must be called again. 
        
        Advantage compared to deleting QPBO and allocating it again:
        no calls to delete/new (which could be quite slow).
        """
        self.c_qpbo.Reset()

    def add_node(self, int num):
        """Adds node(s) to the graph. By default, one node is added (num=1); then first call returns 0, second call returns 1, and so on. 
        If num>1, then several nodes are added, and NodeId of the first one is returned.
        IMPORTANT: see note about the constructor 
        """
        return self.c_qpbo.AddNode(num)

    def add_unary_term(self, NodeId i, double E0, double E1):
        """Adds unary term Ei(x_i) to the energy function with cost values Ei(0)=E0, Ei(1)=E1.
	    Can be called multiple times for each node.
        """
        self.c_qpbo.AddUnaryTerm(i, E0, E1)

    def add_pairwise_term(self, NodeId i, NodeId j, double E00, double E01, double E10, double E11):
        """Adds pairwise term Eij(x_i, x_j) with cost values E00, E01, E10, E11.
	    IMPORTANT: see note about the constructor 
        """
        return self.c_qpbo.AddPairwiseTerm(i, j, E00, E01, E10, E11)

    def modify_pairwise_term(self, EdgeId e, NodeId i, NodeId j, double E00, double E01, double E10, double E11):
        """This function modifies an already existing pairwise term.
        """
        self.c_qpbo.AddPairwiseTerm(e, i, j, E00, E01, E10, E11)

    def merge_parallel_edges(self):
        """If AddPairwiseTerm(i,j,...) has been called twice for some pairs of nodes,
        then MergeParallelEdges() must be called before calling Solve()/Probe()/Improve().
        """
        self.c_qpbo.MergeParallelEdges()

    def get_label(self, NodeId i):
        """Returns 0 or 1, if the node is labeled, and a negative number otherwise.
	    Can be called after Solve()/ComputeWeakPersistencies()/Probe()/Improve().
        """
        return self.c_qpbo.GetLabel(i)

    def set_label(self, NodeId i, char label):
        self.c_qpbo.SetLabel(i, label)

    def get_node_num(self):
        return self.c_qpbo.GetNodeNum()

    def get_twice_unary_term(self, NodeId i):
        cdef double E0, E1
        self.c_qpbo.GetTwiceUnaryTerm(i, E0, E1)
        return (E0, E1)

    def get_twice_pairwise_term(self, EdgeId e):
        cdef NodeId i, j
        cdef double E00, E01, E10, E11
        self.c_qpbo.GetTwicePairwiseTerm(e, i, j, E00, E01, E10, E11)
        return (i, j, E00, E01, E10, E11)

    def compute_twice_energy(self, int option=0):
        """Return energy bound.
        NOTE: in the current implementation Probe() may add constants to the energy
        during transormations, so after Probe() the energy/lower bound would be shifted by some offset.

        option == 0: returns 2 times the energy of internally stored solution which would be
                    returned by GetLabel(). Negative values (unknown) are treated as 0. 
        option == 1: returns 2 times the energy of solution set by the user (via SetLabel()).
        """
        return self.c_qpbo.ComputeTwiceEnergy(option)

    def compute_twice_lower_bound(self):
        """Returns the lower bound defined by current reparameterizaion.
        """
        return self.c_qpbo.ComputeTwiceLowerBound()

    def solve(self):
        """Runs QPBO. After calling Solve(), use GetLabel(i) to get label of node i.
	    Solve() produces a STRONGLY PERSISTENT LABELING. It means, in particular,
	    that if GetLabel(i)>=0 (i.e. node i is labeled) then x_i == GetLabel(i) for ALL global minima x.
        """
        self.c_qpbo.Solve()

    def compute_weak_persistencies(self):
        """Can only be called immediately after Solve()/Probe() (and before any modifications are made to the energy).
        Computes WEAKLY PERSISTENT LABELING. Use GetLabel() to read the result.
        NOTE: if the energy is submodular, then ComputeWeakPersistences() will label all nodes (in general, this is not necessarily true for Solve()).
        """
        self.c_qpbo.ComputeWeakPersistencies()

    def stitch(self):
        """GetRegion()/Stitch():
        ComputeWeakPersistencies() also splits pixels into regions (``strongly connected components'') U^0, U^1, ..., U^k as described in
        
            A. Billionnet and B. Jaumard. 
            A decomposition method for minimizing quadratic pseudoboolean functions. 
            Operation Research Letters, 8:161�163, 1989.	
    
        For a review see also 
    
            V. Kolmogorov, C. Rother
            Minimizing non-submodular functions with graph cuts - a review
            Technical report MSR-TR-2006-100, July 2006. To appear in PAMI.
    
        Nodes in U^0 are labeled, nodes in U^1, ..., U^k are unlabeled.
        (To find out to what region node i belongs, call GetRegion(i)).
        The user can use these regions as follows:
        -- For each r=1..k, compute somehow minimum x^r of the energy corresponding to region U^r.
            This energy can be obtained by calling GetPairwiseTerm() for edges inside the region.
            (There are no unary terms). Note that computing the global minimum is NP-hard;
            it is up to the user to decide how to solve this problem.
        -- Set the labeling by calling SetLabel().
        -- Call Stitch(). It will compute a complete global minimum (in linear time).
        -- Call GetLabel() for nodes in U^1, ..., U^k to read new solution.
        Note that if the user can provides approximate rather than global minima x^r, then the stitching
        can still be done but the result is not guaranteed to be a *global* minimum.
    
        GetRegion()/Stitch() can be called only immediately after ComputeWeakPersistencies().
        NOTE: Stitch() changes the stored energy!
        """
        self.c_qpbo.Stitch()

    def improve(self):
        """Tries to improve the labeling provided by the user (via SetLabel()).
        The new labeling is guaranteed to have the same or smaller energy than the input labeling.
        
        The procedure is as follows:
        1. Run QBPO
        2. Go through nodes in the order order_array[0], ..., order_array[N-1].
            If a node is unlabeled, fix it to the label provided by the user and run QBPO again.
        3. For remaining unlabeled nodes run set their labels to values provided by the user.
            (If order_array[] contains all nodes, then there should be no unlabeled nodes in step 3).
        
        New labeling can be obtained via GetLabel(). (The procedure also calls SetLabel() with
        new labels, so Improve() can be called again). Returns true if success 
        (i.e. the labeling has changed and, thus, the energy has decreased), and false otherwise.
        
        If array fixed_pixels of size nodeNum is provided, then it is set as follows:
        fixed_nodes[i] = 1 if node i was fixed during Improve(), and false otherwise.
        order_array and fixed_pixels can point to the same array.
        """
        return self.c_qpbo.Improve()
