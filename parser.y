/* ===== Definition Section ===== */

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "symboltable.h"
static int linenumber = 1;
static char* current_type = tERROR;
static scope* current_scope;
static scope* global;
char* out;
%}

%union {
    int i;
    float f;
    char* s;
    struct const_type *con_pt;
    char* ID_list;
    char* type;
    int num_args;
}

%token <s> ID
%token <i> NUM_INT
%token <f> NUM_FLOAT
%token <s> STRING
%token <type> VOID    
%token <type> INT     
%token <type> FLOAT   
%token IF      
%token ELSE    
%token WHILE   
%token FOR
%token <type> STRUCT  
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

%type<type> type var factor unary_op_res mul_op_res add_op_res comp_op_res
            and_op_res expression
%type<ID_list> id_list id_tail
%type<num_args> parameter_list parameter_tail

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
    /*TODO:Add return type checking*/
    type ID MK_LPAREN parameter_list MK_RPAREN MK_LBRACE block MK_RBRACE
        {
            ptr p = insert_id(global, $2);
            strcpy(p->return_type, $1);
            printf("Parameter count: %d/n", $4);
            p->arg_num = $4;
        }
    | type ID MK_LPAREN parameter_list MK_RPAREN MK_SEMICOLON
        {
            ptr p = insert_id(global, $2);
            strcpy(p->return_type, $1);
            printf("Parameter count: %d\n", $4);
            p->arg_num = $4;
        }
		;

parameter_list : parameter parameter_tail
                {
                    $$ = 1 + $2;
                }
    | %empty{$$ = 0;};

parameter_tail : 
    MK_COMMA parameter parameter_tail
        {
            $$ = 1 + $3;
        }
    | %empty{$$ = 0;};

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
    {
        //TODO: Fix this
        char* token;
        token = strtok($2, ",");
        printf("Type: %s\n", $1);
        printf("Full id_list: %s\n", $2);
        printf("Out: %s\n", out);
       /* while(token!=NULL){
            ptr p = insert_id(global, token);
            printf("Inserted %s\n", token);
            strcpy($1, p->return_type);
            token = strtok(NULL,",");
        }*/
    }
    | type ID OP_ASSIGN expression MK_SEMICOLON
        {
           // printf("Id to be inserted: %s\n", $2 );
            if(($1!=$4)){ //TODO: Numeric types can be added
                printf("Incompatible type\n");
            } else {
                ptr p = insert_id(global, $2);
                strcpy(p-> return_type, $1);
	            //printf("declaration!\n");
            }
        }
    | typedef
    | struct_def
    ;


/*
decl :
    INT ID MK_SEMICOLON
        {
            printf("Read: %s\n", $2);
            ptr id = insert_id(current_scope, $2);
            id->return_type = tINT;
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
    {
       // strcpy($$, $1);
        out = malloc(strlen($1)+1);
        strcpy(out, $1);
        printf("Out: %s\n", out);
        $$=out;
	    printf("id_head: %s\n", $$);
    }
    ;

id_tail :
    MK_COMMA ID bracket_chain id_tail
    {
        printf("id: %s\n", $2);
        strcat($$, ",");
        strcat($$, $2);
    }   
    | %empty {strcat($$, "");}
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
        {
            if($1!=tINT || $3!=tINT){
                $$=tERROR;
                //TODO: Add operator symbols
                printf("Invalid operand to ||\n");
            }
            else {$$ = tINT;}
        }
    | and_op_res {$$ = $1;}
    ;

and_op_res : 
    and_op_res OP_AND comp_op_res
        {
            if($1!=tINT || $3!=tINT){
                $$=tERROR;
                //TODO: Add operator symbols
                printf("Invalid operand to &&\n");
            }
            else {$$ = tINT;}
        }
    | comp_op_res {$$ = $1;}
    ;

comp_op_res : 
    comp_op_res comp_op add_op_res
        {
            if($1!=$3){
                $$=tERROR;
                //TODO: Add operator symbols
                printf("Invalid operand to comp_op\n");
            }
            else {$$ = tINT;}
        }
    | add_op_res {$$ = $1;}
    ;

add_op_res : 
    add_op_res add_op mul_op_res
        {
            if(($1!=tFLOAT&&$1!=tINT)||($3!=tFLOAT&&$3!=tINT)){
                $$=tERROR;
                //TODO: Add operator symbols
                printf("Invalid operand to add_op\n");
            }
            else if ($1 != $3){
                $$=tFLOAT;
            }
            else {$$ = $1;}
        }
    | mul_op_res {$$=$1;}
    ;

mul_op_res :
    mul_op_res mul_op unary_op_res
        {
            if(($1!=tFLOAT&&$1!=tINT)||($3!=tFLOAT&&$3!=tINT)){
                $$=tERROR;
                //TODO: Add operator symbols
                printf("Invalid operand to mul_op\n");
            }
            else if ($1 != $3){
                $$=tFLOAT;
            }
            else {$$ = $1;}
        }
    | unary_op_res {$$ = $1;}
    ;

unary_op_res :
    OP_MINUS factor
        {
            if($2!=tFLOAT&&$2!=tINT){
                $$=tERROR;
                printf("Invalid operand to -\n");
            }
            else {$$ = $2;}
        }
    | OP_NOT factor
        {
            if($2!=tINT){
                $$=tERROR;
                printf("Invalid operand to !\n");
            }
            else{$$ = $2;}
        }
    | factor
        {$$ = $1;}

factor : 
    NUM_INT {$$ = tINT;}
    | NUM_FLOAT {$$ = tFLOAT;}
    | STRING {$$ = tCHAR;}
    | var {$$ = $1;}
    | MK_LPAREN expression MK_RPAREN {$$ = $2;}
    | function_call {$$ = tTEMP;}
    ;

var :
    ID {$$ = search_id(global, $1)-> return_type;}
    /*TODO:Make array and struct types work*/
    | array {$$ = tTEMP;}
    | struct_ref {$$ = tTEMP;}
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

struct const_type{
  int con_type;         /*0: Int, 1: Float, -1: String*/
  union {
    int ival;
    float fval;
    char *sc;
  } const_u;
};

struct idPassing_type{
    char* id;
    char* lst;
} idPass_type;

main (argc, argv)
int argc;
char *argv[];
  {
     	yyin = fopen(argv[1],"r");
        global = init_scope();
     	yyparse();
     	printf("%s\n", "Parsing completed. No errors found.");
        print_symtab(global);
  }
yyerror (mesg)
char *mesg;
{
	printf("%s\t%d\t%s\t%s\n", "Error found in Line ", linenumber, "next token: ", yytext );
  	printf("%s\n", mesg);
  	exit(1);
}
