from __future__ import annotations

__all__ = ["QPBODouble", "QPBOFloat", "QPBOInt"]

EdgeId = int
NodeId = int

class QPBODouble:
    @staticmethod
    def __new__(cls, type, *args, **kwargs):
        """
        Create and return a new object. See help(type) for accurate signature.
        """

    @staticmethod
    def __reduce__(*args, **kwargs): ...
    @staticmethod
    def __setstate__(*args, **kwargs): ...
    def add_node(self, num: int):
        """
        Adds node(s) to the graph. By default, one node is added (num=1); then first call returns 0, second call returns 1, and so on.
                If num>1, then several nodes are added, and NodeId of the first one is returned.
                IMPORTANT: see note about the constructor

        """

    def add_pairwise_term(
        self, i: NodeId, j: NodeId, E00: float, E01: float, E10: float, E11: float
    ):
        """
        Adds pairwise term Eij(x_i, x_j) with cost values E00, E01, E10, E11.
                    IMPORTANT: see note about the constructor

        """

    def add_unary_term(self, i: NodeId, E0: float, E1: float):
        """
        Adds unary term Ei(x_i) to the energy function with cost values Ei(0)=E0, Ei(1)=E1.
                    Can be called multiple times for each node.

        """

    def compute_twice_energy(self, option=0):
        """
        Return energy bound.
                NOTE: in the current implementation Probe() may add constants to the energy
                during transormations, so after Probe() the energy/lower bound would be shifted by some offset.

                option == 0: returns 2 times the energy of internally stored solution which would be
                            returned by GetLabel(). Negative values (unknown) are treated as 0.
                option == 1: returns 2 times the energy of solution set by the user (via SetLabel()).

        """

    def compute_twice_lower_bound(self):
        """
        Returns the lower bound defined by current reparameterizaion.

        """

    def compute_weak_persistencies(self):
        """
        Can only be called immediately after Solve()/Probe() (and before any modifications are made to the energy).
                Computes WEAKLY PERSISTENT LABELING. Use GetLabel() to read the result.
                NOTE: if the energy is submodular, then ComputeWeakPersistences() will label all nodes (in general, this is not necessarily true for Solve()).

        """

    def get_label(self, i):
        """
        Returns 0 or 1, if the node is labeled, and a negative number otherwise.
                    Can be called after Solve()/ComputeWeakPersistencies()/Probe()/Improve().

        """

    def get_node_num(self): ...
    def get_twice_pairwise_term(self, e: NodeId): ...
    def get_twice_unary_term(self, i: NodeId): ...
    def improve(self):
        """
        Tries to improve the labeling provided by the user (via SetLabel()).
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

    def load(self, filename: str):
        """
        Load energy from a text file. Current terms of the energy (if any) are destroyed.
                Type identifier in the file (int/float/double) should match the type QPBO::REAL.
                    Returns true if success, false otherwise.

        """

    def merge_parallel_edges(self):
        """
        If AddPairwiseTerm(i,j,...) has been called twice for some pairs of nodes,
                then MergeParallelEdges() must be called before calling Solve()/Probe()/Improve().

        """

    def modify_pairwise_term(
        self, e, i: NodeId, j: NodeId, E00: float, E01: float, E10: float, E11: float
    ):
        """
        This function modifies an already existing pairwise term.

        """

    def reset(self):
        """
        Removes all nodes and edges.
                After that functions AddNode(), AddUnaryTerm(), AddPairwiseTerm() must be called again.

                Advantage compared to deleting QPBO and allocating it again:
                no calls to delete/new (which could be quite slow).

        """

    def save(self, filename: str):
        """
        Save current reparameterisation of the energy to a text file. (Note: possibly twice the energy is saved).
                    Returns true if success, false otherwise.

        """

    def set_label(self, i: NodeId, label: bool): ...
    def solve(self):
        """
        Runs QPBO. After calling Solve(), use GetLabel(i) to get label of node i.
                    Solve() produces a STRONGLY PERSISTENT LABELING. It means, in particular,
                    that if GetLabel(i)>=0 (i.e. node i is labeled) then x_i == GetLabel(i) for ALL global minima x.

        """

    def stitch(self):
        """
        GetRegion()/Stitch():
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

class QPBOFloat:
    @staticmethod
    def __new__(cls, *args, **kwargs):
        """
        Create and return a new object. See help(type) for accurate signature.
        """

    @staticmethod
    def __reduce__(*args, **kwargs): ...
    @staticmethod
    def __setstate__(*args, **kwargs): ...
    def add_node(self, num: int):
        """
        Adds node(s) to the graph. By default, one node is added (num=1); then first call returns 0, second call returns 1, and so on.
                If num>1, then several nodes are added, and NodeId of the first one is returned.
                IMPORTANT: see note about the constructor

        """

    def add_pairwise_term(
        self, i: NodeId, j: NodeId, E00: float, E01: float, E10: float, E11: float
    ):
        """
        Adds pairwise term Eij(x_i, x_j) with cost values E00, E01, E10, E11.
                    IMPORTANT: see note about the constructor

        """

    def add_unary_term(self, i: NodeId, E0: float, E1: float):
        """
        Adds unary term Ei(x_i) to the energy function with cost values Ei(0)=E0, Ei(1)=E1.
                    Can be called multiple times for each node.

        """

    def compute_twice_energy(self, option=0):
        """
        Return energy bound.
                NOTE: in the current implementation Probe() may add constants to the energy
                during transormations, so after Probe() the energy/lower bound would be shifted by some offset.

                option == 0: returns 2 times the energy of internally stored solution which would be
                            returned by GetLabel(). Negative values (unknown) are treated as 0.
                option == 1: returns 2 times the energy of solution set by the user (via SetLabel()).

        """

    def compute_twice_lower_bound(self):
        """
        Returns the lower bound defined by current reparameterizaion.

        """

    def compute_weak_persistencies(self):
        """
        Can only be called immediately after Solve()/Probe() (and before any modifications are made to the energy).
                Computes WEAKLY PERSISTENT LABELING. Use GetLabel() to read the result.
                NOTE: if the energy is submodular, then ComputeWeakPersistences() will label all nodes (in general, this is not necessarily true for Solve()).

        """

    def get_label(self, i: NodeId):
        """
        Returns 0 or 1, if the node is labeled, and a negative number otherwise.
                    Can be called after Solve()/ComputeWeakPersistencies()/Probe()/Improve().

        """

    def get_node_num(self): ...
    def get_twice_pairwise_term(self, e: NodeId): ...
    def get_twice_unary_term(self, i: NodeId): ...
    def improve(self):
        """
        Tries to improve the labeling provided by the user (via SetLabel()).
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

    def load(self, filename: str):
        """
        Load energy from a text file. Current terms of the energy (if any) are destroyed.
                Type identifier in the file (int/float/double) should match the type QPBO::REAL.
                    Returns true if success, false otherwise.

        """

    def merge_parallel_edges(self):
        """
        If AddPairwiseTerm(i,j,...) has been called twice for some pairs of nodes,
                then MergeParallelEdges() must be called before calling Solve()/Probe()/Improve().

        """

    def modify_pairwise_term(
        self,
        e: NodeId,
        i: NodeId,
        j: NodeId,
        E00: float,
        E01: float,
        E10: float,
        E11: float,
    ):
        """
        This function modifies an already existing pairwise term.

        """

    def reset(self):
        """
        Removes all nodes and edges.
                After that functions AddNode(), AddUnaryTerm(), AddPairwiseTerm() must be called again.

                Advantage compared to deleting QPBO and allocating it again:
                no calls to delete/new (which could be quite slow).

        """

    def save(self, filename: str):
        """
        Save current reparameterisation of the energy to a text file. (Note: possibly twice the energy is saved).
                    Returns true if success, false otherwise.

        """

    def set_label(self, i: NodeId, label: bool): ...
    def solve(self):
        """
        Runs QPBO. After calling Solve(), use GetLabel(i) to get label of node i.
                    Solve() produces a STRONGLY PERSISTENT LABELING. It means, in particular,
                    that if GetLabel(i)>=0 (i.e. node i is labeled) then x_i == GetLabel(i) for ALL global minima x.

        """

    def stitch(self):
        """
        GetRegion()/Stitch():
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

class QPBOInt:
    @staticmethod
    def __new__(cls, *args, **kwargs):
        """
        Create and return a new object. See help(type) for accurate signature.
        """

    @staticmethod
    def __reduce__(*args, **kwargs): ...
    @staticmethod
    def __setstate__(*args, **kwargs): ...
    def add_node(self, num: int):
        """
        Adds node(s) to the graph. By default, one node is added (num=1); then first call returns 0, second call returns 1, and so on.
                If num>1, then several nodes are added, and NodeId of the first one is returned.
                IMPORTANT: see note about the constructor

        """

    def add_pairwise_term(
        self, i: NodeId, j: NodeId, E00: int, E01: int, E10: int, E11: int
    ):
        """
        Adds pairwise term Eij(x_i, x_j) with cost values E00, E01, E10, E11.
                    IMPORTANT: see note about the constructor

        """

    def add_unary_term(self, i: NodeId, E0: int, E1: int):
        """
        Adds unary term Ei(x_i) to the energy function with cost values Ei(0)=E0, Ei(1)=E1.
                    Can be called multiple times for each node.

        """

    def compute_twice_energy(self, option=0):
        """
        Return energy bound.
                NOTE: in the current implementation Probe() may add constants to the energy
                during transormations, so after Probe() the energy/lower bound would be shifted by some offset.

                option == 0: returns 2 times the energy of internally stored solution which would be
                            returned by GetLabel(). Negative values (unknown) are treated as 0.
                option == 1: returns 2 times the energy of solution set by the user (via SetLabel()).

        """

    def compute_twice_lower_bound(self):
        """
        Returns the lower bound defined by current reparameterizaion.

        """

    def compute_weak_persistencies(self):
        """
        Can only be called immediately after Solve()/Probe() (and before any modifications are made to the energy).
                Computes WEAKLY PERSISTENT LABELING. Use GetLabel() to read the result.
                NOTE: if the energy is submodular, then ComputeWeakPersistences() will label all nodes (in general, this is not necessarily true for Solve()).

        """

    def get_label(self, i):
        """
        Returns 0 or 1, if the node is labeled, and a negative number otherwise.
                    Can be called after Solve()/ComputeWeakPersistencies()/Probe()/Improve().

        """

    def get_node_num(self): ...
    def get_twice_pairwise_term(self, e: NodeId): ...
    def get_twice_unary_term(self, i: NodeId): ...
    def improve(self):
        """
        Tries to improve the labeling provided by the user (via SetLabel()).
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

    def load(self, filename):
        """
        Load energy from a text file. Current terms of the energy (if any) are destroyed.
                Type identifier in the file (int/float/double) should match the type QPBO::REAL.
                    Returns true if success, false otherwise.

        """

    def merge_parallel_edges(self):
        """
        If AddPairwiseTerm(i,j,...) has been called twice for some pairs of nodes,
                then MergeParallelEdges() must be called before calling Solve()/Probe()/Improve().

        """

    def modify_pairwise_term(
        self, e: NodeId, i: NodeId, j: NodeId, E00: int, E01: int, E10: int, E11: int
    ):
        """
        This function modifies an already existing pairwise term.

        """

    def reset(self):
        """
        Removes all nodes and edges.
                After that functions AddNode(), AddUnaryTerm(), AddPairwiseTerm() must be called again.

                Advantage compared to deleting QPBO and allocating it again:
                no calls to delete/new (which could be quite slow).

        """

    def save(self, filename: str):
        """
        Save current reparameterisation of the energy to a text file. (Note: possibly twice the energy is saved).
                    Returns true if success, false otherwise.

        """

    def set_label(self, i: NodeId, label: bool): ...
    def solve(self):
        """
        Runs QPBO. After calling Solve(), use GetLabel(i) to get label of node i.
                    Solve() produces a STRONGLY PERSISTENT LABELING. It means, in particular,
                    that if GetLabel(i)>=0 (i.e. node i is labeled) then x_i == GetLabel(i) for ALL global minima x.

        """

    def stitch(self):
        """
        GetRegion()/Stitch():
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

def __reduce_cython__(self): ...
def __setstate_cython__(self, _): ...

__test__: dict = {}
