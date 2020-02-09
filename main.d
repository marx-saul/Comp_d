// Reference: Compilers: Principles, Techniques, and Tools, written by Alfred V. Aho, Monica S. Lam, Ravi Sethi, and Jeffrey D. Ullman

import data, tool, SLR, LR, LALR;
import std.stdio, std.ascii, std.typecons;
import std.algorithm, std.array, std.container;

void main() {
	
}

unittest {
	
	
	enum {
		Expr = 0, Term, Fact, plus, minus, mult, div, lPar, rPar, digit
	}
	
	Grammar grammar = [
		tuple(Expr, [Expr, plus, Term]),
		tuple(Expr, [Expr, minus, Term]),
		tuple(Expr, [Term]),
		tuple(Term, [Term, mult, Fact]),
		tuple(Term, [Term, div, Fact]),
		tuple(Term, [Fact]),
		tuple(Fact, [lPar, Expr, rPar]),
		tuple(Fact, [digit]),
		tuple(Fact, [minus, Fact])
	];
	
	// show LALR table
	
	auto table = grammar.LALRtable();
	foreach (state; 0 .. table[end_of_file].length) {
		write(state, ": ");
		write(table[end_of_file][state][0], " ", table[end_of_file][state][1] ," / ");
		foreach (symbol; 0 .. grammar.sym_num) {
			write(table[symbol][state][0], "->", table[symbol][state][1] ," / ");
		}
		writeln();
	}
	
	alias Token = Tuple!(Symbol, "sym", int, "val");
	class SyntaxNode {
		Token token;
		SyntaxNode* left, right;
	}
	
	class SyntaxAnalyzer : LRSyntaxAnalyzer {
		
		this(Grammar g, LRTable t){ super(g, t); }
		
		// 9 + 7 * -(2+4)
		//Token[] input = [ tuple(digit, 9), tuple(plus, 0), tuple(digit, 7), tuple(mult, 0), tuple(minus, 0), tuple(lPar, 0), tuple(digit, 2), tuple(plus, 0), tuple(digit, 4), tuple(mult, 4), tuple(minus, 9), tuple(digit, 8), tuple(rPar, 0) ]; // tuple(mult, 4) <- 4 is meaningless, same as tuple(minus, 9)
		Token[] input = [];
		
		public void init() {
			states_stack = SList!ulong(0);
			auto expr = readln();
			int num;
			ulong index;
			while (index < expr.length) {
				auto c = expr[index];
				
				if (isWhite(c)) { ++index; continue; }
				if (isDigit(c)) {
					while (index < expr.length && isDigit(expr[index])) {
						num = num*10 + cast(int) (expr[index] - '0');
						++index;
					}
					input ~= Token(digit, num);
					num = 0;
					continue;
				}
				
				switch (c) {
				case '+': input ~= Token(plus,  0); break;
				case '-': input ~= Token(minus, 0); break;
				case '*': input ~= Token(mult,  0); break;
				case '/': input ~= Token(div,   0); break;
				case '(': input ~= Token(lPar,  0); break;
				case ')': input ~= Token(rPar,  0); break;
				default : writeln("Unexpected character: '", c, "'");
				}
				++index;
			}
		}
		
		public void show_expression() {
			static immutable texts = ["", "", "", " + ", " - ", " * ", " / ", "(", ")", ""];
			foreach (token; input) {
				if (token[0] == digit) write(token[1]);
				else write(texts[token[0]]);
			}
		}
		
		
		ulong pointer = -1;
		override Symbol next_token() {
		
			if (pointer == input.length-1) return end_of_file;
			else ++pointer;
			return input[pointer][0];
		}
		
		Token now_token() {
			return input[pointer];
		}
		
		SList!SyntaxNode stack;
		
		// make the syntax tree
		override void reduce(ulong index) {
			switch (index) {
			// Expr -> Expr + Term 
			case 0:
				auto term = stack.front; stack.removeFront;
				auto p    = stack.front; stack.removeFront;
				auto expr = stack.front; stack.removeFront;
				p.left = &expr, p.right = &term;
				p.token.val = expr.token.val + term.token.val;
				stack.insert(p);
			
			break;
			
			// Expr -> Expr - Term 
			case 1:
				auto term = stack.front; stack.removeFront;
				auto m    = stack.front; stack.removeFront;
				auto expr = stack.front; stack.removeFront;
				m.left = &expr, m.right = &term;
				m.token.val = expr.token.val - term.token.val;
				stack.insert(m);
			break;
			
			// Expr -> Term
			case 2:
			break;
			
			// Term -> Term * Fact
			case 3:
				auto fact = stack.front; stack.removeFront;
				auto m    = stack.front; stack.removeFront;
				auto term = stack.front; stack.removeFront;
				m.left = &term, m.right = &fact;
				m.token.val = term.token.val * fact.token.val;
				stack.insert(m);
			break;
			
			// Term -> Term / Fact
			case 4:
				auto fact = stack.front; stack.removeFront;
				auto d    = stack.front; stack.removeFront;
				auto term = stack.front; stack.removeFront;
				d.left = &term, d.right = &fact;
				d.token.val = term.token.val / fact.token.val;
				stack.insert(d);
			break;
			
			// Term -> Fact
			case 5:
			break;
			
			// Fact -> ( Expr )
			case 6:
				stack.removeFront;
				auto expr = stack.front; stack.removeFront;
				stack.removeFront;
				stack.insert(expr);
			break;
			
			// Fact -> digit
			case 7:
			break;
			
			// Fact -> - Fact
			case 8:
				auto fact = stack.front; stack.removeFront;
				auto m    = stack.front; stack.removeFront;
				m.left = &fact;
				m.token.val = -fact.token.val;
				stack.insert(m);
			break;
			
			default:
			}
		}
		
		override void shift(ulong) {
			auto node = new SyntaxNode;
			node.token = now_token();
			stack.insert(node);
		}
		
		int get() { return stack.front.token.val; }
		
	}
	
	writeln("start");
	auto sa = new SyntaxAnalyzer(grammar, table);
	writeln("end");
	//sa.show_expression();
	sa.init();
	
	while (true) {
		try {
			if (sa.next()) {
				writeln("= ", sa.get());
				break;
			}
			
		}
		catch (Exception e) {
			writeln(e.toString);
			break;
		}
	}
	
}

/+
unittest {
	
	
	enum {
		S = 0, C, c, d
	}
	
	Grammar grammar = [
		tuple(S, [C, C]),
		tuple(C, [c, C]),
		tuple(C, [d])
	];
	
	// show SLR table
	
	auto table = grammar.LALRtable();
	foreach (state; 0 .. table[end_of_file].length) {
		write(state, ": ");
		write(table[end_of_file][state][0], " ", table[end_of_file][state][1] ," / ");
		foreach (symbol; 0 .. grammar.sym_num) {
			write(table[symbol][state][0], "->", table[symbol][state][1] ," / ");
		}
		writeln();
	}
}
+/

/+

// an example of grammar that is not SLR(1) but is LALR(1) and LR(1)
unittest {
	
	enum {
		S, L, R, eq, id, ptr
	}
	
	Grammar grammar = [
		tuple(S, [L, eq, R]),
		tuple(S, [R]),
		tuple(L, [ptr, R]),
		tuple(L, [id]),
		tuple(R, [L])
	];
	
	auto table = LALRtable(grammar);
	writeln(table);
	
}
+/

