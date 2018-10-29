Main: symboltable.h symboltable.c Lex Bison
	gcc parser.tab.c symboltable.c -ll -o parser

Lex:
	flex lexer.lex

Bison:
	bison parser.y

clean:
	rm lex.yy.c && rm parser && rm parser.tab.c

