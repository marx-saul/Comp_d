module comp_d.Set;

import comp_d.AATree;
import std.stdio : writeln;
import std.meta, std.typecons;
import std.algorithm, std.container.rbtree, std.array;

/*
unittest {
    auto set1 = AASet(3, 1, 4);
    set1.add(1, 99, 999);
    assert ( equal(set1.array, [1, 3, 4, 99, 999]) );
    assert (1 in set1);
    assert (10 !in set1);
    
    auto set2 = AASet(1, 99, 4);
    assert (set2 in set1);
    
    auto set3 = symbolSetRBT(3, 999);
    assert ( (set2 + set3) == set1 );
    
    auto set4 = symbolSetRBT(-8);
    set4 += set3;
    assert (set4 == symbolSetRBT(-8, 3, 999));
}
*/

class Set(T, alias less = (a,b)=>a<b)
    if ( is(typeof(less(T.init, T.init))) )
{
    private AATree!(T, less) aat;
    // initialize
    public this(T[] args...) {
        aat = new AATree!(T, less)(args);
    }
    
    // range (foreach )
    public @property bool empty() {
        return aat.empty;
    }
    public @property T front() {
        return aat.front;
    }
    
    public T[] array() @property {
        return aat.array;
    }
    
    public void add(T[] args...) {
        aat.insert(args);
    }
    public void remove(T[] args...) {
        aat.remove(args);
    }
    
    
    // "in" overload (element)
    public bool opBinaryRight(string op)(T elem)
        if (op == "in")
    {
        return !rbt.equalRange(elem).empty;
    }
    
    // "in" overload (containment)
    public bool opBinary(string op)(Set!(T, less) rhs)
        if (op == "in")
    {
        foreach(elem; aat.array) {
            if (elem !in rhs) return false;
        }
        return true;
    }
    
    // "==" overload
    override public bool opEquals(Object o) {
        auto a = cast(Set!(T, less)) o;
        return this.aat == a.aat;
    }
    
    // operator "+" overload
    // cup
    public Set!(T, less) opBinary(string op)(Set!(T, less) set2)
        if (op == "+")
    {
        auto result = new Set!(T, less)();
        foreach (t; this.aat.array) result.add(t);
        foreach (t; set2.aat.array) result.add(t);
        return result;
    }
    
    // operator "-" overload
    // subtract
    public Set!(T, less) opBinary(string op)(Set!(T, less) set2)
        if (op == "-")
    {
        auto result = new Set!(T, less)();
        foreach (t; this.aat.array) result.add(t);
        foreach (t; set2.aat.array) result.remove(t);
        return result;
    }
    
    public Set!(T, less) opOpAssign(string op)(Set!(T, less) set2) {
        // operator "+=" overload
        static if (op == "+") {
            foreach (t; set2.aat.array) this.add(t);
            return this;
        }
        // operator "-=" overload
        else if (op == "-") {
            foreach (t; set2.aat.array) this.remove(t);
            return this;
        }
        else assert(0, op ~ "= for Set is not implemented.");
    }
}


unittest {
    HashSet!int set1;
    set1.add(12, 11, 18, 19);
    auto set2 = HashSet!int(2, 2, 9, 3);
    
    set1 += set2;
    
    auto set3 = HashSet!int();
    set3.add(18, 9, 120, 168);
    
    set1 -= set3;
    
    auto set4 = HashSet!int(19, 12, 11, 3, 2);
    
    assert(set1 in set4);
    assert(set4 in set1);
    assert(set1 == set4);
    assert(set1 != set3);   
}

// this Set is not used because associative array cannot be used in the compile time.
// Set!Symbol is below:
struct HashSet(T) {
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
    public bool opBinary(string op)(HashSet!T set2)
        if (op == "in")
    {
        foreach (t; _arr.byKey)
            if (t !in set2) return false;
        return true;
    }
    
    // operator "==" overload
    public bool opEquals(HashSet!T a) {
        return ( a in this ) && ( this in a ) ;
    }
    
    // operator "+" overload
    // cup
    public HashSet!T opBinary(string op)(HashSet!T set2)
        if (op == "+")
    {
        HashSet!T result;
        foreach (t; this._arr.byKey) result.add(t);
        foreach (t; set2._arr.byKey) result.add(t);
        return result;
    }
    
    // operator "-" overload
    // subtract
    public HashSet!T opBinary(string op)(HashSet!T set2)
        if (op == "-")
    {
        HashSet!T result;
        foreach (t; this._arr.byKey) result.add(t);
        foreach (t; set2._arr.byKey) result.remove(t);
        return result;
    }
    
    public HashSet!T opOpAssign(string op)(HashSet!T set2) {
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

