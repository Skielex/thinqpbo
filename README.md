# Thin wrapper for QPBO
Thin Python wrapper for a modified version of the quadratic pseudo-Boolean optimization (QPBO) algorithm by Vladimir Kolmogorov. The original source code by Vladimir Kolmogorov availbable at http://pub.ist.ac.at/~vnk/software.html. This wrapper uses a modified version with support for larger graphs and slightly lower memory usage. See [submodule repository](https://github.com/Skielex/QPBO) for more details.

## QPBO vs. Maxflow
While the QPBO algorithm performs a *s-t* graph cut similar to [Maxflow](https://github.com/Skielex/thinmaxflow), it allows for non-submodular energy terms, which Maxflow doesn't. Amongst other things, this allows QPBO to solve optimization problems with exclusions terms, which can be very usefull. The graph constructed by the QPBO implementation is twice the size of a Maxflow graph for an equivalent problem. Thus, QPBO uses more memory and is slightly slower than Maxflow.

## Installation
Install package using `pip install thinqpbo` or clone this repository (including [submodule](https://github.com/Skielex/QPBO)). Building the package requires Cython.

## Graph types
Currently, there are three different types of graphs: `QPBOInt`, `QPBOFloat` and `QPBODouble`. The only difference is the underlying datatypes used for the edge capacities in the graph. For stability, it is recommended to use `QPBOInt` for integer capacities and `QPBODouble` for floating point capacities. However, in some cases, it maybe be favourable to use `QPBOFloat` to reduce memory consumption.

## Advanced features (QPBO-P and QPBO-I)
The QPBO implementation has a few advanced extensions known as QPBO-P and QPBO-I. Currently, not all advanced functions have been wrapped. If you need to use features of the QPBO C++ library that are not wrapped by `thinqpbo`, please let me know by creating an issue on GitHub.

## Tiny example
```python
import thinqpbo as tq

# Create graph object.
graph = tq.QPBOInt()

# Number of nodes to add.
nodes_to_add = 2

# Add two nodes.
first_node_id = graph.add_node(nodes_to_add)

# Add edges.
graph.add_unary_term(0, 0, 5) # E1(0) = 5, s     --5->   n(0)
graph.add_unary_term(0, 1, 0) # E0(0) = 1, n(0)  --1->   t
graph.add_unary_term(1, 5, 0) # E0(1) = 5, n(1)  --5->   t
graph.add_pairwise_term(0, 1, 0, 7, 0, 4)   # E01(0,1) = 7, n(0)  --7->   n(1)
                                            # E11(0,1) = 4, Not possible with standard Maxflow


# Find maxflow/cut graph.
graph.solve()
graph.compute_weak_persistencies()
twice_energy = graph.compute_twice_energy()

for n in range(nodes_to_add):
    segment = graph.get_label(n)
    print('Node %d has label %d.' % (n, segment))
# Node 0 has label 0.
# Node 1 has label 0.
    
print('Twice energy/flow: %s' % twice_energy)
# Twice energy/flow: 12
```

## License
As the QPBO implementation is distributed under the GPLv3 license, so is this package.