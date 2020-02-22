module comp_d.AAtree;

import comp_d.tool, comp_d.data;
import std.typecons;
import std.array, std.container, std.container.binaryheap;
import std.algorithm, std.algorithm.comparison;
import std.stdio: writeln;
import std.conv: to;

class AATree(T, alias less = (a,b)=>a<b)
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
    }
    private Node* root;
    
    this(T[] args...) {
        insert(args);
    }
    
    T[] array() @property{
        return array_(root);
    }
    
    T[] array_(Node* node) {
        if (node == null) return [];
        return array_(node.left) ~ [node.val] ~ array_(node.right);
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
        if (node == null)                                        return null;
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
    
    private Node* insert(T val, Node* node) {
        if      (node == null) {
            auto new_node = new Node();
            new_node.val = val, new_node.level = 1; 
            return new_node;
        }
        else if (less(val, node.val)) {
            node.left  = insert(val, node.left);
        }
        else if (less(node.val, val)) {
            node.right = insert(val, node.right);
        }
        node = skew (node);
        node = split(node);
        return node;
    }
    
    public void insert(T[] vals...) {
        foreach (val; vals)
            root = insert(val, root);
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

unittest {
    static const aatree = new AATree!int(3, 9, 4);
    aatree.test();
    //static assert ( equal(aatree.array, [3, 4, 9]) );
}
