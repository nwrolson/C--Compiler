TARGET=parser
OBJECT=parser.tab.c parser.tab.o lex.yy.c lex.yy.o symboltable.o parser.output
CC=gcc -Wall -g
LEX=flex
YACC = bison -v
YACCFLAG = 
LIBS = -lfl 


parser:	parser.tab.o symboltable.o
	$(CC) -o $(TARGET) parser.tab.o symboltable.o $(LIBS)

parser.tab.o:	parser.tab.c lex.yy.c
	$(CC) -c parser.tab.c

symboltable.o:	symboltable.c
		$(CC) -c symboltable.c

parser.tab.c:	parser.y
	$(YACC) $(YACCFLAG) parser.y

lex.yy.c:	lexer.lex
		$(LEX) lexer.lex

clean:
		rm -f $(TARGET) $(OBJECT) 

