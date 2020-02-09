import data;
import tool;
import std.algorithm;
import std.array;
import std.stdio;
import std.typecons;

struct Item {
	ulong num; int index; Symbol sym;
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

ItemSet closure1(Grammar grammar, ItemSet items, bool[][Symbol] first_table) {
	auto result = items;
	auto sym_num = grammar.sym_num;
	
	while (true) {
		bool end = true;
		
		foreach(item; result.byKey) {
			// A -> α.,a : (the dot is placed at the last)
			if (item.index >= grammar[item.num][1].length) continue;
			
			// item = A -> α.Bβ,a : symbol = B
			auto symbol = grammar[item.num][1][item.index];
			
			foreach (num, rule; grammar) foreach (b; first_list(grammar, grammar[item.num][1][item.index+1 .. $] ~ item.sym , first_table) ) {
				// i = B -> .γ,b
				// ε ≠ b ∈ FIRST(βa)
				
				Item i;
				
				if (rule[0] == symbol && b != empty_) i.num = num, i.index = 0, i.sym = b;
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


// make the LR table
LRTable LALRtable(Grammar grammar_) {
	
	auto grammar = grammar_.dup();
	auto sym_num = grammar.sym_num;
	auto nonterminal = grammar.nonterminal;
	auto is_term    = (Symbol x) => x>=0 &&  !canFind(nonterminal, x);
	
	grammar = grammar.augument;
	auto first_table = grammar.first();
	
	
	////////////////////////////////////////////////////////////////////////////////////////////////////
	// make the canonical LR(0) collection
	
	Item _itm = { grammar.length-1, 0, end_of_file };
	ItemSet[] collection_ = [ grammar.closure( [_itm: true]) ] ;
	ulong[][Symbol] goto_map;
	foreach (symbol; 0 .. sym_num+1) { goto_map[symbol] = []; }
	
	while(true) {
		bool end = true;
		
		// for each items in result and each grammatical symbol symbol,
		// if goto(items, symbol) is not empty and is not contained in result,
		// then add it
		foreach (state, items; collection_) foreach (symbol; 0 .. sym_num+1) {
			if (goto_map[symbol].length <= state) goto_map[symbol].length = state+1, goto_map[symbol][$-1] = -1;
			
			auto i = grammar._goto(items, symbol);
			auto num = countUntil(collection_, i);
			if (i.length != 0 && num == -1) {
				collection_ ~= i;
				end = false;
			}
			else if (i.length != 0) { goto_map[symbol][state] = num; } // goto(state, symbol) = num
		
		}
		
		if (end) break;
		
	}
	
	auto collection = collection_;
	
	// determine lookahead
	bool is_kernel(Item item) {
		return (item.num == grammar.length-1 && item.index == 0) || item.index != 0;
	}
	
	Item[][Item] propagate;	// lookahead[i] = j ... i -> j
	bool[Symbol][Item] lookaheads;
	
	_itm.sym = virtual;
	lookaheads[_itm][end_of_file] = true;	// S' -> .S, $
	Item[] kernel_items;
	
	foreach (items; collection) foreach (item; items.byKey) {
		if (!is_kernel(item)) continue;
		kernel_items ~= item;
		
		auto it = item; it.sym = virtual;
		auto j = closure1(grammar, [it: true], first_table);
		
		foreach (i; j.byKey) {
			// . is at the end
			if (i.index >= grammar[i.num][1].length) continue;
			
			if (i.sym != virtual) { auto i_ = i; i_.sym = virtual, i_.index++; lookaheads[i_][i.sym] = true; }
			else { i.index++; item.sym = virtual, propagate[item] ~= i; }
		}
		
	}
	
	
	// propagate
	while (true) {
		bool end = true;
		
		foreach (from; kernel_items) {
			from.sym = virtual;
			// do not propagate to anywhere
			if (from !in propagate) continue;
			
			foreach (to_; propagate[from]) {
				to_.sym = virtual;
				// no lookahead symbol
				if (from !in lookaheads) continue;
				
				foreach (symbol; lookaheads[from].byKey) {
					if (to_ !in lookaheads || symbol !in lookaheads[to_]) { lookaheads[to_][symbol] = true, end = false; }
				}
			}
		}
		
		if (end) break;
	}
	
	
	writeln(lookaheads);
	////////////////////////////////////////////////////////////////////////////////////////////////////
	
	
	//writeln(collection);
	
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
		
			// A -> α.aβ,b :  where a is a terminal symbol
			// goto(state, a) = j
			// action[state, a] = shift j
			if (item.index < grammar[item.num][1].length) {
				auto to_ = goto_map[grammar[item.num][1][item.index]][state];
				if (is_term(grammar[item.num][1][item.index])) set(grammar[item.num][1][item.index], state, tuple(Action.shift, to_));
			}
			
			// A -> α.,a :  A is not S'
			// action[state, a] = reduce A -> α
			else if (grammar[item.num][0] != sym_num ) {
				item.sym = virtual;
				if (item in lookaheads) foreach (symbol; lookaheads[item].byKey) {
					set(symbol, state, tuple(Action.reduce, item.num) );
				}
			}
			
			// S' -> S., $
			else {
				item.sym = virtual;
				if(item in lookaheads && end_of_file in lookaheads[item]) { set(end_of_file, state, tuple(Action.accept, 0uL)); }
			}
		}
		
		foreach ( symbol; nonterminal ) {
			auto to_ = goto_map[symbol][state];
			if (to_ == -1) { continue; }
			set(symbol, state, tuple(Action.goto_, to_));
		}
		
	}
	
	return result;
}
