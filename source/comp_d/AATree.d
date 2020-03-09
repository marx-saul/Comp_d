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
    static assert ( equal(aatree.array, [3, 4, 9]) );
    static assert ( !aatree.empty );
    static assert ( aatree.front == 3 );
    static assert ( aatree.hasKey(9) );
    static assert ( aatree.cardinal == 3 );
    
    // run time check
    auto aatree2 = new AATree!int(3, 9, 4);
    aatree2.insert(9, -1, 2, 6);
    aatree2.remove(2, 4, 4, 10);
    assert ( equal(aatree2.array, [-1, 3, 6, 9]) );
    assert ( aatree2.hasKey(-1) && !aatree2.hasKey(2) );
    assert ( aatree2.cardinal == 4 );
    writeln("## AATree unittest 1");
}

// T is key, S is value
class AATree(T, alias less = (a,b) => a < b, S = bool)
    if ( is(typeof(less(T.init, T.init))) )
{
    // if left and right are null (i.e., the node is a leaf), level = 1
    // left.level = this.level - 1
    // right.level = this.level or this.level - 1
    // right.right, right.left < this.level
    // if level > 1, then left !is null and right !is null
    private struct Node {
        T val;
        Node* left, right;
        size_t level;
        S s;
    }
    private Node* root;
    
    this(T[] args...) {
        insert(args);
    }
    
    // array returns the array of the elements in the ascending order
    public inout(T)[] array() @property inout const {
        return array_(cast(inout(Node*)) root);
    }
    private inout(T)[] array_(inout(Node*) node) inout const {
        if (node == null) return [];
        return array_(node.left) ~ [node.val] ~ array_(node.right);
    }
    // array.length
    private size_t cardinal_;
    public size_t cardinal() @property inout const {
        return cardinal_;
    }
    
    public bool empty() @property inout {
        return root == null;
    }
    public T front() @property inout {
        return getMinimum(cast(Node*) root).val;
    }
    // get the minumum node of the tree with the root 'node'
    private Node* getMinimum(Node* node) inout {
        if (node == null) return null;
        while (node.left) 
            node = node.left;
        return node;
    }
    
    private Node* hasKey(inout T val, Node* node) inout {
        while (true) {
            // not found
            if (node == null) return null;
            // found
            if (node.val == val) return node;
            
            // go left
            if      (less(val, node.val)) node = node.left;
            // go right
            else if (less(node.val, val)) node = node.right;
        }
    }
    public bool hasKey(inout T val) inout {
        return hasKey(val, cast(Node*) root) != null;
    }
    public ref S getValue(inout T val) inout const {
        return hasKey(val, cast(Node*) root).s;
    }
    
    // [] overload
    public ref S opIndex(T index) inout const {
        return getValue(index);
    }
    // aatree[index] = s
    public S opIndexAssign(S s, T index) {
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
    private Node* insert(T val, Node* node, S s = S.init) {
        if      (node == null) {
            auto new_node = new Node();
            new_node.val = val, new_node.level = 1, new_node.s = s; 
            cardinal_++;
            return new_node;
        }
        else if (less(val, node.val)) {
            node.left  = insert(val, node.left, s);
        }
        else if (less(node.val, val)) {
            node.right = insert(val, node.right, s);
        }
        else {
            node.s = s;
        }
        node = skew (node);
        node = split(node);
        return node;
    }
    
    public void insert(T[] vals...) {
        foreach (val; vals)
            root = insert(val, root);
    }
    
    /////////////
    // remove
    public Node* remove(T val, Node* node) {
        if (node == null)
            return null;
        else if (less(node.val, val))
            node.right = remove(val, node.right);
        else if (less(val, node.val))
            node.left  = remove(val, node.left);
        else {
            // leaf
            if (node.left == null && node.right == null) {
                cardinal_--;
                return null;
            }
            else if (node.left == null) {
                auto R = successor(node);
                node.right = remove(R.val, node.right);
                node.val = R.val;
            }
            else {
                auto L = predecessor(node);
                node.left = remove(L.val, node.left);
                node.val = L.val;
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
    
    public void remove(T[] vals...) {
        foreach (val; vals)
            root = remove(val, root);
    }
    
    version (unittest) {
        public void test() inout {
            {
                //     l <---- n      m = l ---->  n
                //   |   |     |    =>    |      |   |
                //   v   v     v          v      v   v
                //   a   b     r          a      b   r
                Node n, l, r, a, b;
                //n.val = 0, l.val = 1, r.val = 2, a.val = 3, b.val = 4;
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
                //n.val = 0, x.val = 1, r.val = 2, a.val = 3, b.val = 4;
                n.left = &a, n.right = &r, r.left = &b, r.right = &x;
                a.level = 1, b.level = 1, n.level = 2, r.level = 2, x.level = 2;
                
                auto m = split(&n);
                assert ( m == &r && m.left == &n && m.right == &x && m.left.left == &a && m.left.right == &b );
                
            }
        }
    }
}
