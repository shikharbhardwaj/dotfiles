#ifndef GRAPH
#define GRAPH 1
#include <set>
#include <unordered_map>

namespace graph {
template <typename VType> class AdjList {
  private:
    std::unordered_map<VType, std::set<VType>> _lists;
    size_t V = 0;

  public:
    AdjList() = default;
    bool is_connected(VType i, VType j) {
        return _lists[i].find(j) != _lists[i].end();
    }
    void add_node(VType i) { _lists[i] = {}; }
    void add_directed_edge(VType i, VType j) { _lists[i].insert(j); }
    void add_undirected_edge(VType i, VType j) {
        add_directed_edge(i, j);
        add_directed_edge(j, i);
    }
    void remove_directed_edge(VType i, VType j) {
        auto it = _lists[i].find(j);
        _lists[i].erase(it);
    }
    void remove_undirected_edge(VType i, VType j) {
        remove_directed_edge(i, j);
        remove_directed_edge(j, i);
    }
    size_t out_degree(VType i) { return _lists[i].size(); }
};
template <typename VType, typename WeightType> class WeightedEdges {
  private:
    std::unordered_map<std::pair<VType, VType>, WeightType> _weights;

  public:
    void update_weight(VType u, VType v, WeightType w) { _weights[{u, v}] = w; }
    WeightType get_directed_weight(VType u, VType v) {
        return _weights[{u, v}];
    }
    WeightType get_undirected_weight(VType u, VType v) {
        auto it = _weights.find({u, v});
        if (it == _weights.end()) {
            it = _weights.find({v, u});
        }
        return it->second;
    }
};
template <typename VType> class UndirectedGraph {
  private:
    AdjList<VType> _lists;

  public:
    UndirectedGraph() = default;
    UndirectedGraph(size_t V) {
        for (size_t i = 1; i <= V; i++) {
            _lists.add_node(i);
        }
    }
    void add_edge(VType u, VType v) { _lists.add_undirected_edge(u, v); }
    void remove_edge(VType u, VType v) { _lists.remove_undirected_edge(u, v); }
    bool is_connected(VType u, VType v) { return _lists.is_connected(u, v); }
};
template <typename VType> class DirectedGraph {
  private:
    AdjList<VType> _lists;

  public:
    DirectedGraph() = default;
    DirectedGraph(size_t V) {
        for (size_t i = 1; i <= V; i++) {
            _lists.add_node(i);
        }
    }
    void add_edge(VType u, VType v) { _lists.add_directed_edge(u, v); }
    void remove_edge(VType u, VType v) { _lists.remove_directed_edge(u, v); }
    bool is_connected(VType u, VType v) { return _lists.is_connected(u, v); }
};
}
#endif /* ifndef GRAPH */
