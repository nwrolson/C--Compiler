/* ===== Definition Section ===== */

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
static int linenumber = 1;
%}


%token ID
%token CONST
%token VOID    
%token INT     
%token FLOAT   
%token IF      
%token ELSE    
%token WHILE   
%token FOR
%token STRUCT  
%token TYPEDEF 
%token OP_ASSIGN  
%token OP_OR   
%token OP_AND  
%token OP_NOT  
%token OP_EQ   
%token OP_NE   
%token OP_GT   
%token OP_LT   
%token OP_GE   
%token OP_LE   
%token OP_PLUS 
%token OP_MINUS        
%token OP_TIMES        
%token OP_DIVIDE       
%token MK_LB 
%token MK_RB 
%token MK_LPAREN       
%token MK_RPAREN       
%token MK_LBRACE       
%token MK_RBRACE       
%token MK_COMMA        
%token MK_SEMICOLON    
%token MK_DOT  
%token ERROR
%token RETURN

%token COMMENT

%start program

%%

/* ==== Grammar Section ==== */


/* Declarations */

program	: global_decl_list
		;

global_decl_list :
    global_decl_list global_decl 
    |  %empty
		;

global_decl	: decl_list function_decl_list
		;

function_decl_list : 
    function_decl function_decl_list
    | %empty
    ;

function_decl	: type ID MK_LPAREN parameter_list MK_RPAREN MK_LBRACE block MK_RBRACE
		;

parameter_list : 
    type ID parameter_bracket_chain parameter_list
    | %empty;

parameter_bracket_chain : 
    MK_LB MK_RB bracket_chain
    | bracket_chain
    | %empty
    ;

block : 
    decl_list statement_list
    | %empty
    ;

decl_list : 
    decl decl_list
    | %empty
    ;

decl : 
    type ID bracket_chain
    | type id_list
    | struct_def
    | TYPEDEF type ID
    ;

bracket_chain : 
    MK_LB INT MK_RB bracket_chain
    | %empty
    ;


id_list : ID id_tail
    ;

id_tail :
    ID id_tail
    | %empty
    ;

type :
    INT
    | FLOAT 
    | STRUCT ID
    | ID
    | VOID
    ;

/* Structs */

struct_def :
   STRUCT ID MK_LBRACE struct_block MK_RBRACE MK_SEMICOLON
   | TYPEDEF STRUCT ID MK_LBRACE struct_block MK_RBRACE MK_SEMICOLON
   ;

struct_block : type ID struct_block_tail
    ;

struct_block_tail : 
    type ID struct_block_tail
    | %empty

/* Statements */

statement_list : statement statement_tail
    ;

statement_tail : 
    statement statement_tail
    | %empty
    ;

statement : 
    expression MK_SEMICOLON
    | ID OP_ASSIGN expression MK_SEMICOLON
    | control_statement
    | RETURN MK_SEMICOLON
    | RETURN expression MK_SEMICOLON
    ;

/* Expressions */

function_call : ID MK_LPAREN expression_list MK_RPAREN
    ;

expression_list : expression expression_tail

expression_tail :
    expression expression_tail
    | %empty
    ;

expression : 
    expression OP_NOT or_op_res
    | or_op_res
    | function_call
    ;

or_op_res : 
    or_op_res OP_OR and_op_res
    | and_op_res
    ;

and_op_res : 
    and_op_res OP_AND comp_op_res
    | comp_op_res
    ;

comp_op_res : 
    comp_op_res comp_op add_op_res
    | add_op_res 
    ;

add_op_res : 
    add_op_res add_op mul_op_res
    | mul_op_res
    ;

mul_op_res :
    mul_op_res mul_op factor
    | factor
    ;

factor : 
    INT
    | FLOAT
    | ID
    | MK_LPAREN expression MK_RPAREN
    | function_call
    ;

add_op :
    OP_PLUS
    | OP_MINUS
    ;

mul_op :
    OP_TIMES
    | OP_DIVIDE
    ;

comp_op :
    OP_EQ
    | OP_NE
    | OP_LT
    | OP_GT
    | OP_LE
    | OP_GE
    ;

/* Control Statements */

control_statement :
    if_statement
    | for_statement
    | while_statement
    ;

if_statement : IF MK_LPAREN expression MK_RPAREN MK_LBRACE block MK_RBRACE if_tail
    ;

if_tail : 
    ELSE MK_LBRACE block MK_RBRACE 
    | %empty
    ;

for_statement : FOR MK_LPAREN expression MK_COMMA expression MK_COMMA
     expression MK_RPAREN MK_LBRACE block MK_RBRACE
    ;

while_statement : WHILE MK_LPAREN expression MK_RPAREN MK_LBRACE block MK_RBRACE
    ;


%%

#include "lex.yy.c"
main (argc, argv)
int argc;
char *argv[];
  {
     	yyin = fopen(argv[1],"r");
     	yyparse();
     	printf("%s\n", "Parsing completed. No errors found.");
  } 


yyerror (mesg)
char *mesg;
{
	printf("%s\t%d\t%s\t%s\n", "Error found in Line ", linenumber, "next token: ", yytext );
  	printf("%s\n", mesg);
  	exit(1);
}
