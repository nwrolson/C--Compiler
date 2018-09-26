Main: symbol_table.h symbol_table.c Lex
	gcc lex.yy.c symbol_table.c -ll -lm -w -o parser

Lex:
	flex symbol_parser.lex

clean:
	rm lex.yy.c && rm parser

