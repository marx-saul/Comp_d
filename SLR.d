//import data;
//import tool;
import std.algorithm;
import std.array;
import std.stdio;
import std.typecons;
/+
struct Item {
	ulong num; int index;
}

alias ItemSet = bool[Item];

// item = A -> X.YZ
// item.rule = tuple(A, [X,Y,Z]), intem.index = 1

@property Grammar augument(Grammar grammar) {
	auto start_ = grammar.sym_num;
	return grammar ~ [tuple(start_, [0])];
}

ItemSet closure(Grammar grammar, ItemSet items) {
	auto result = items;
	
	while (true) {
		bool end = true;
		
		foreach(item; result.byKey) {
			// A -> α. (the dot is placed at the last)
			if (item.index >= grammar[item.num][1].length) continue;
			
			// item = A -> α.Bβ, symbol = B
			auto symbol = grammar[item.num][1][item.index];
			
			foreach (num, rule; grammar) {
				
				// i = B -> .γ
				Item i;
				
				if (rule[0] == symbol) i.num = num, i.index = 0;
				else continue;
				
				// if i is not in result, add it
				if (i in result) continue;
				// still can add some items
				else result[i] = true, end = false;
			}
			
		}
		
		if (end) break;
		
	}
	return items;
}

ItemSet _goto(Grammar grammar, ItemSet items, Symbol symbol) {
	ItemSet result;
	foreach (item; items.byKey) {
		// A -> α. (the dot is placed at the last)
		if (item.index >= grammar[item.num][1].length) continue;
		
		// A -> α.Xβ,  X == symbol
		if (grammar[item.num][1][item.index] != symbol) continue;
		
		// add all the element of closure( {[A -> αX.β]} );
		item.index++;
		foreach (i; grammar.closure([item: true]).byKey) {
			result[i] = true;
		}
	}
	return result;
}


// make the SLR table
LRTable SLRtable(Grammar grammar_) {
	
	auto grammar = grammar_.dup();
	auto sym_num = grammar.sym_num;
	auto nonterminal = grammar.nonterminal;
	auto is_term    = (Symbol x) => x>=0 &&  !canFind(nonterminal, x);
	
	grammar = grammar.augument;
	
	// make the canonical LR(0) collection
	
	Item _itm = { grammar.length-1, 0 };
	ItemSet[] collection = [ grammar.closure( [_itm: true] ) ] ;
	ulong[][Symbol] goto_map;
	foreach (symbol; 0 .. sym_num+1) { goto_map[symbol] = []; }
	
	
	while(true) {
		bool end = true;
		
		// for each items in result and each grammatical symbol symbol,
		// if goto(items, symbol) is not empty and is not contained in result,
		// then add it
		foreach (state, items; collection) foreach (symbol; 0 .. sym_num+1) {
			if (goto_map[symbol].length <= state) goto_map[symbol].length = state+1, goto_map[symbol][$-1] = -1;
			
			auto i = grammar._goto(items, symbol);
			auto num = countUntil(collection, i);
			if (i.length != 0 && num == -1) {
				collection ~= i;
				end = false;
			}
			else if (i.length != 0) { goto_map[symbol][state] = num; } // goto(state, symbol) = num
		
		}
		
		if (end) break;
		
	}
	
	
	auto follow_table = follow(grammar);
	
	
	// result[symbol][state]
	LRTable result;
	foreach (symbol; 0 .. sym_num) { result[symbol].length = collection.length; }
	result[end_of_file].length = collection.length;
	
	void set(Symbol symbol, ulong state, LREntry entry) {
		//writeln(symbol, " ", state, " ", entry);
		if (result[symbol][state][0] == Action.error || result[symbol][state] == entry)  result[symbol][state] = entry;
		// if shift/reduce conflict happens, solve it by replacing shift for reduce
		// (for solving if-else problem)
		else if (result[symbol][state][0] == Action.reduce && entry[0] == Action.shift) result[symbol][state] = entry;
		else { writeln("Error: symbol = ", symbol, ", state = ", state, ", entry = ", entry, ", result[symbol][state] = ", result[symbol][state], "\n This grammar is not SLR" ); /+ error +/ }
	}
	
	foreach ( ulong state; 0 .. collection.length ) {
	
		foreach ( item; collection[state].byKey ) {
		
			// A -> α.aβ where a is a terminal symbol
			// goto(state, a) = j
			// action[state, a] = shift j
			if (item.index < grammar[item.num][1].length) {
				auto to_ = goto_map[grammar[item.num][1][item.index]][state];
				if (is_term(grammar[item.num][1][item.index])) set(grammar[item.num][1][item.index], state, tuple(Action.shift, to_));
			}
			
			// A -> α. A is not S'
			// a ∈ Follow(A), action[state, a] = reduce A -> α
			else if (grammar[item.num][0] != sym_num) {
				
				if ( follow_table[end_of_file][grammar[item.num][0]] ) set(end_of_file, state, tuple(Action.reduce, item.num) );
				foreach (symbol; 0 .. sym_num) {
					if ( follow_table[symbol][grammar[item.num][0]] ) set(symbol, state, tuple(Action.reduce, item.num) );
				}
				
			}
			
			// S' -> S.
			else { set(end_of_file, state, tuple(Action.accept, 0uL)); }
		}
		
		foreach ( symbol; nonterminal ) {
			auto to_ = goto_map[symbol][state];
			if (to_ == -1) { continue; }
			set(symbol, state, tuple(Action.goto_, to_));
		}
		
	}
	
	return result;
}
+/
