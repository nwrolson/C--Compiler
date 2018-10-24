/* ===== Definition Section ===== */

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "symboltable.h"
static int linenumber = 1;
#define YYSTYPE char*
%}


%token ID
%token NUM_INT
%token NUM_FLOAT
%token STRING
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

global_decl	:
    function_decl
    | decl
    ;

function_decl	:
    type ID MK_LPAREN parameter_list MK_RPAREN MK_LBRACE block MK_RBRACE
    | type ID MK_LPAREN parameter_list MK_RPAREN MK_SEMICOLON
		;

parameter_list : parameter parameter_tail
    | %empty;

parameter_tail : 
    MK_COMMA parameter parameter_tail
    | %empty;

parameter : type ID parameter_bracket_chain

parameter_bracket_chain : 
    MK_LB MK_RB bracket_chain
    | bracket_chain
    ;

block : 
    decl block
    | typedef_decl block
    | statement block
    | %empty
    ;

decl : 
    type id_list MK_SEMICOLON
    | type ID OP_ASSIGN expression MK_SEMICOLON
    | typedef
    | struct_def
    ;

/*
decl :
    INT ID MK_SEMICOLON
        {
            printf("Read: %s\n", $2);
            insert_id($2);
            getnode($2) -> return_type = tINT;
        }
    | FLOAT ID MK_SEMICOLON
    | typedef
    | struct_def
    ;
*/

bracket_chain : 
    MK_LB NUM_INT MK_RB bracket_chain
    | %empty
    ;


id_list : ID bracket_chain id_tail
    ;

id_tail :
    MK_COMMA ID bracket_chain id_tail
    | %empty
    ;

type :
    INT
    | FLOAT 
    | VOID
    ;

typedef : TYPEDEF type ID MK_SEMICOLON
        ;

typedef_decl : ID id_list MK_SEMICOLON
    ;

/* Structs */

struct_def :
    STRUCT ID struct_block MK_SEMICOLON
    | STRUCT ID struct_block id_list MK_SEMICOLON
    | STRUCT struct_block id_list MK_SEMICOLON
    | TYPEDEF STRUCT ID struct_block MK_SEMICOLON
    ;

struct_block :
    MK_LBRACE decl_list MK_RBRACE
    | %empty
    ;

decl_list :
    decl decl_list
    | typedef_decl decl_list
    | %empty
    ;

/* Statements */

statement : 
    expression_statement
    | assignment_statement
    | control_statement
    | RETURN MK_SEMICOLON
    | RETURN expression MK_SEMICOLON
    ;

expression_statement: expression MK_SEMICOLON
    ;

assignment_statement: assignment MK_SEMICOLON
    ;

assignment: var OP_ASSIGN expression
    ;

reference_bracket_chain:
    MK_LB expression MK_RB reference_bracket_chain
    | MK_LB expression MK_RB
    ;

/* Expressions */

function_call : ID MK_LPAREN expression_list MK_RPAREN
    ;

expression_list :
    expression expression_tail
    | %empty
    ;

expression_tail :
    MK_COMMA expression expression_tail
    | %empty
    ;

expression : 
    expression OP_OR and_op_res
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
    mul_op_res mul_op unary_op_res
    | unary_op_res
    ;

unary_op_res :
    OP_MINUS factor
    | OP_NOT factor
    | factor

factor : 
    NUM_INT
    | NUM_FLOAT
    | STRING
    | var
    | MK_LPAREN expression MK_RPAREN
    | function_call
    ;

var :
    ID {printf("In parser: %s\n", $1);}
    | array
    | struct_ref
    ;

array: ID reference_bracket_chain
    ;

struct_ref :
    ID MK_DOT ID
    | ID MK_DOT array
    | array MK_DOT ID
    | array MK_DOT array

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

for_statement : FOR MK_LPAREN assignment_statement expression_statement
     assignment MK_RPAREN MK_LBRACE block MK_RBRACE
    ;

while_statement : WHILE MK_LPAREN expression_list MK_RPAREN MK_LBRACE block MK_RBRACE
    ;


%%
#include "lex.yy.c"
main (argc, argv)
int argc;
char *argv[];
  {
     	yyin = fopen(argv[1],"r");
        init_symtab();
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
