import unittest

from thinqpbo import QPBODouble, QPBOFloat, QPBOInt


class TestGraph(unittest.TestCase):

    def setUp(self):
        self.qpbo_types = [QPBOInt, QPBOFloat, QPBODouble]

    def test_create_qpbo(self):
        """Test QPBO constructors."""
        for qpbo_type in self.qpbo_types:
            qpbo_type()

        for qpbo_type in self.qpbo_types:
            qpbo_type(100, 100)

    def test_add_node(self):
        """Test add_node function."""
        for qpbo_type in self.qpbo_types:

            qpbo = qpbo_type()

            node_id = qpbo.add_node(1)
            self.assertEqual(node_id, 0)

            node_count = qpbo.get_node_num()
            self.assertEqual(node_count, 1)

            node_id = qpbo.add_node(100)
            self.assertEqual(node_id, 1)

            node_count = qpbo.get_node_num()
            self.assertEqual(node_count, 101)

    def test_add_pairwise_term(self):
        """Test add_edge function."""
        for qpbo_type in self.qpbo_types:

            qpbo = qpbo_type()

            node_id = qpbo.add_node(2)
            self.assertEqual(node_id, 0)

            node_count = qpbo.get_node_num()
            self.assertEqual(node_count, 2)

            qpbo.add_pairwise_term(0, 0, 1, 1, 2, 0)

    def test_example(self):
        """Test maxflow function."""
        for qpbo_type in self.qpbo_types:

            qpbo = qpbo_type()

            # Number of nodes to add.
            nodes_to_add = 2

            # Add two nodes.
            first_node_id = qpbo.add_node(nodes_to_add)
            self.assertEqual(first_node_id, 0)

            # Add edges.
            qpbo.add_unary_term(0, 0, 5)  # E1(0) = 5, s     --5->   n(0)
            qpbo.add_unary_term(0, 1, 0)  # E0(0) = 1, n(0)  --1->   t
            qpbo.add_unary_term(1, 5, 0)  # E0(1) = 5, n(1)  --5->   t
            qpbo.add_pairwise_term(0, 1, 0, 7, 0, 4)  # E01(0,1) = 7, n(0)  --7->   n(1)
            # E11(0,1) = 4, Not possible with standard Maxflow

            # Find maxflow/cut qpbo.
            qpbo.solve()
            qpbo.compute_weak_persistencies()
            twice_energy = qpbo.compute_twice_energy()

            for n in range(nodes_to_add):
                segment = qpbo.get_label(n)
                self.assertEqual(0, segment)
            # Node 0 has label 0.
            # Node 1 has label 0.

            self.assertEqual(twice_energy, 12)
            # Twice energy/flow: 12


if __name__ == "__main__":
    unittest.main()
