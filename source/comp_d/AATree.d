module comp_d.AATree;

import comp_d.tool, comp_d.data;
import std.typecons;
import std.array, std.container, std.container.binaryheap;
import std.algorithm, std.algorithm.comparison;
import std.stdio: writeln;
import std.conv: to;

unittest {
    // CTFE check
    static const aatree = new AATree!int(3, 9, 4);
    aatree.test();
    static assert ( equal(aatree.keys, [3, 4, 9]) );
    static assert ( !aatree.empty );
    static assert ( aatree.front == 3 );
    static assert ( aatree.hasKey(9) );
    static assert ( aatree.cardinal == 3 );
    
    // run time check
    auto aatree2 = new AATree!int(3, 9, 4);
    aatree2.insert(9, -1, 2, 6);
    aatree2.remove(2, 4, 4, 10);
    assert ( equal(aatree2.keys, [-1, 3, 6, 9]) );
    assert ( aatree2.hasKey(-1) && !aatree2.hasKey(2) );
    assert ( aatree2.cardinal == 4 );
    writeln("## AATree unittest 1");
}

// K is key, V is value
class AATree(K, alias less = (a,b) => a < b, V = bool)
    if ( is(typeof(less(K.init, K.init))) )
{
    // if left and right are null (i.e., the node is a leaf), level = 1
    // left.level = this.level - 1
    // right.level = this.level or this.level - 1
    // right.right, right.left < this.level
    // if level > 1, then left !is null and right !is null
    private struct Node {
        K key;
        Node* left, right;
        size_t level;
        V value;
    }
    private Node* root;
    
    this(K[] args...) {
        insert(args);
    }
    
    // returns the keys of the elements in the ascending order
    public inout(K)[] keys() @property inout const {
        return array_(cast(inout(Node*)) root);
    }
    deprecated("Use keys() instead.") public inout(K)[] array() @property inout const {
        return array_(cast(inout(Node*)) root);
    }
    private inout(K)[] array_(inout(Node*) node) inout const {
        if (node == null) return [];
        return array_(node.left) ~ [node.key] ~ array_(node.right);
    }
    // array.length
    private size_t cardinal_;
    public size_t cardinal() @property inout const {
        return cardinal_;
    }
    
    public bool empty() @property inout {
        return root == null;
    }
    public K front() @property inout {
        return getMinimum(cast(Node*) root).key;
    }
    // get the minumum node of the tree with the root 'node'
    private Node* getMinimum(Node* node) inout {
        if (node == null) return null;
        while (node.left) 
            node = node.left;
        return node;
    }
    
    private Node* hasKey(inout K key, Node* node) inout {
        while (true) {
            // not found
            if (node == null) return null;
            // found
            if (node.key == key) return node;
            
            // go left
            if      (less(key, node.key)) node = node.left;
            // go right
            else if (less(node.key, key)) node = node.right;
        }
    }
    public bool hasKey(inout K key) inout {
        return hasKey(key, cast(Node*) root) != null;
    }
    public ref V getValue(inout K key) inout const {
        return hasKey(key, cast(Node*) root).value;
    }
    
    // [] overload
    public ref V opIndex(K index) inout const {
        return getValue(index);
    }
    // aatree[index] = s
    public V opIndexAssign(V s, K index) {
        root = insert(index, root, s);
        return s;
    }
    
    //   left <- node -                left ->   node
    //   |  |          |       =>        |      |    |
    //   v  v          v                 v      v    v
    //   a  b        right               a      b  right
    private Node* skew(Node* node) inout {
        if (node == null)           return null;
        else if (node.left == null) return node;
        else if (node.left.level == node.level) {
            auto L = node.left;
            node.left = L.right;
            L.right = node;
            return L;
        }
        else return node;
    }
    
    //                               - r -
    //                     =>       |     |
    //                              v     v
    // node  ->  r  ->  x          node   x
    //   |       |                |    |
    //   v       v                v    v
    //   a       b                a    b
    private Node* split(Node* node) inout {
        if      (node == null)                                   return null;
        else if (node.right == null || node.right.right == null) return node;
        else if (node.level == node.right.right.level) {
            auto R = node.right;
            node.right = R.left;
            R.left = node;
            R.level++;
            return R;
        }
        else return node;
    }
    /////////////
    // insert
    private Node* insert(K key, Node* node, V value = V.init) {
        if      (node == null) {
            auto new_node = new Node();
            new_node.key = key, new_node.level = 1, new_node.value = value; 
            cardinal_++;
            return new_node;
        }
        else if (less(key, node.key)) {
            node.left  = insert(key, node.left, value);
        }
        else if (less(node.key, key)) {
            node.right = insert(key, node.right, value);
        }
        else {
            node.value = value;
        }
        node = skew (node);
        node = split(node);
        return node;
    }
    
    public void insert(K[] keys...) {
        foreach (key; keys)
            root = insert(key, root);
    }
    
    /////////////
    // remove
    public Node* remove(K key, Node* node) {
        if (node == null)
            return null;
        else if (less(node.key, key))
            node.right = remove(key, node.right);
        else if (less(key, node.key))
            node.left  = remove(key, node.left);
        else {
            // leaf
            if (node.left == null && node.right == null) {
                cardinal_--;
                return null;
            }
            else if (node.left == null) {
                auto R = successor(node);
                node.right = remove(R.key, node.right);
                node.key = R.key;
            }
            else {
                auto L = predecessor(node);
                node.left = remove(L.key, node.left);
                node.key = L.key;
            }
        }
        // 
        node = decrease_level(node);
        node = skew(node);
        node.right = skew(node.right);
        if (node.right != null) node.right.right = skew(node.right.right);
        node = split(node);
        node.right = split(node.right);
        return node;
    }
    
    private Node* decrease_level(Node* node) {
        auto normalize
           = min(
               node.left  ? node.left.level  : 0,
               node.right ? node.right.level : 0
             )
           + 1;
        if (normalize < node.level) {
            node.level = normalize;
            if (normalize < node.right.level)
                node.right.level = normalize;
        }
        return node;
    }
    
    private Node* predecessor(Node* node) {
        //if (node == null || node.left == null) return null;
        node = node.left;
        while (node.right)
            node = node.right;
        return node;
    }
    
    private Node* successor(Node* node) {
        //if (node == null || node.right == null) return null;
        node = node.right;
        while (node.left)
            node = node.left;
        return node;
    }
    
    public void remove(K[] keys...) {
        foreach (key; keys)
            root = remove(key, root);
    }
    
    version (unittest) {
        public void test() inout {
            {
                //     l <---- n      m = l ---->  n
                //   |   |     |    =>    |      |   |
                //   v   v     v          v      v   v
                //   a   b     r          a      b   r
                Node n, l, r, a, b;
                //n.key = 0, l.key = 1, r.key = 2, a.key = 3, b.key = 4;
                n.left = &l, n.right = &r, l.left = &a, l.right = &b;
                a.level = 1, b.level = 1, r.level = 1, l.level = 2, n.level = 2;
                
                auto m = skew(&n);
                static assert ( is(typeof(*m.left) == Node) );
                static assert ( is(typeof(m.left) == Node*) );
                static assert ( is(typeof(m.left.left) == Node*) );
                static assert ( is(typeof(*m.left.left) == Node) );
                static assert ( is(typeof((*m.left).left) == Node*) );
                assert ( m == &l && m.left == &a && m.right == &n && m.right.left == &b && m.right.right == &r );
            }
            {
                //   n -> r -> x              -r=m-
                //   |    |         =>       |     |
                //   v    v                  v     v
                //   a    b                - n -   x
                //                         |   |
                //                         v   v
                //                         a   b
                Node n, x, r, a, b;
                //n.key = 0, x.key = 1, r.key = 2, a.key = 3, b.key = 4;
                n.left = &a, n.right = &r, r.left = &b, r.right = &x;
                a.level = 1, b.level = 1, n.level = 2, r.level = 2, x.level = 2;
                
                auto m = split(&n);
                assert ( m == &r && m.left == &n && m.right == &x && m.left.left == &a && m.left.right == &b );
                
            }
        }
    }
}
