import std.stdio : writeln;
import std.meta, std.typecons;
import std.algorithm, std.container.rbtree, std.array;

// this Set is not used because associative array cannot be used in the compile time.
// Set!Symbol is below:
struct Set(T) {
    private bool[T] _arr;
    public immutable(bool)[T] arr() @property {
        return cast(immutable(bool)[T]) _arr;
    }
    public this(T[] elems...) {
        add(elems);
    }
    
    public T[] toList() @property {
        return _arr.keys;
    }
    
    public void add(T[] elems...) {
        foreach (t; elems) _arr[t] = true;
    }
    public void remove(T[] elems...) {
        foreach (t; elems) _arr.remove(t);
    }
    
    // operator "in" overload (element)
    public bool opBinaryRight(string op)(T t)
        if (op == "in")
    {
        return (t in _arr) !is null;
    }
    
    // operator "in" overload (containment)
    public bool opBinary(string op)(Set!T set2)
        if (op == "in")
    {
        foreach (t; _arr.byKey)
            if (t !in set2) return false;
        return true;
    }
    
    // operator "==" overload
    public bool opEquals(Set!T a) {
        return ( a in this ) && ( this in a ) ;
    }
    
    // operator "+" overload
    // cup
    public Set!T opBinary(string op)(Set!T set2)
        if (op == "+")
    {
        Set!T result;
        foreach (t; this._arr.byKey) result.add(t);
        foreach (t; set2._arr.byKey) result.add(t);
        return result;
    }
    
    // operator "-" overload
    // subtract
    public Set!T opBinary(string op)(Set!T set2)
        if (op == "-")
    {
        Set!T result;
        foreach (t; this._arr.byKey) result.add(t);
        foreach (t; set2._arr.byKey) result.remove(t);
        return result;
    }
    
    public Set!T opOpAssign(string op)(Set!T set2) {
        // operator "+=" overload
        static if (op == "+") {
            foreach (t; set2._arr.byKey) this.add(t);
            return this;
        }
        // operator "-=" overload
        else if (op == "-") {
            foreach (t; set2._arr.byKey) this.remove(t);
            return this;
        }
        else assert(0, op ~ " for Set is not implemented.");
    }
}

// Set!Symbol is this
class SymbolSetRBT {
    private RedBlackTree!int rbt;
    // initialize
    public this(int[] args...) {
        rbt = redBlackTree(args);
    }
    
    // range (foreach )
    public @property bool empty() {
        return rbt.empty;
    }
    public @property int front() {
        return rbt.front;
    }
    public void popFront() {
        rbt.removeFront();
    }
    
    public int[] array() @property {
        return rbt[].array;
    }
    
    public void add(int[] args...) {
        rbt.insert(args);
    }
    public void remove(int[] args...) {
        rbt.removeKey(args);
    }
    
    
    // "in" overload (element)
    public bool opBinaryRight(string op)(int elem)
        if (op == "in")
    {
        return !rbt.equalRange(elem).empty;
    }
    
    // "in" overload (containment)
    public bool opBinary(string op)(SymbolSetRBT rhs)
        if (op == "in")
    {
        foreach(elem; rbt) {
            if (elem !in rhs) return false;
        }
        return true;
    }
    
    // "==" overload
    override public bool opEquals(Object o) {
        auto a = cast(SymbolSetRBT) o;
        return this.rbt == a.rbt;
    }
    
    // operator "+" overload
    // cup
    public SymbolSetRBT opBinary(string op)(SymbolSetRBT set2)
        if (op == "+")
    {
        auto result = new SymbolSetRBT();
        foreach (t; this.rbt) result.add(t);
        foreach (t; set2.rbt) result.add(t);
        return result;
    }
    
    // operator "-" overload
    // subtract
    public SymbolSetRBT opBinary(string op)(SymbolSetRBT set2)
        if (op == "-")
    {
        auto result = new SymbolSetRBT();
        foreach (t; this.rbt) result.add(t);
        foreach (t; set2.rbt) result.remove(t);
        return result;
    }
    
    public SymbolSetRBT opOpAssign(string op)(SymbolSetRBT set2) {
        // operator "+=" overload
        static if (op == "+") {
            foreach (t; set2.rbt) this.add(t);
            return this;
        }
        // operator "-=" overload
        else if (op == "-") {
            foreach (t; set2.rbt) this.remove(t);
            return this;
        }
        else assert(0, op ~ "= for Set is not implemented.");
    }
}

SymbolSetRBT symbolSetRBT(int[] args...) {
    return new SymbolSetRBT(args);
}

unittest {
    Set!int set1;
    set1.add(12, 11, 18, 19);
    auto set2 = Set!int(2, 2, 9, 3);
    
    set1 += set2;
    
    auto set3 = Set!int();
    set3.add(18, 9, 120, 168);
    
    set1 -= set3;
    
    auto set4 = Set!int(19, 12, 11, 3, 2);
    
    assert(set1 in set4);
    assert(set4 in set1);
    assert(set1 == set4);
    assert(set1 != set3);   
}

unittest {
    auto set1 = symbolSetRBT(3, 1, 4);
    set1.add(1, 99, 999);
    assert ( equal(set1.array, [1, 3, 4, 99, 999]) );
    assert (1 in set1);
    assert (10 !in set1);
    
    auto set2 = symbolSetRBT(1, 99, 4);
    assert (set2 in set1);
    
    auto set3 = symbolSetRBT(3, 999);
    assert ( (set2 + set3) == set1 );
    
    auto set4 = symbolSetRBT(-8);
    set4 += set3;
    assert (set4 == symbolSetRBT(-8, 3, 999));
}
