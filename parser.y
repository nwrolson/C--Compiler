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
struct const_type{
  int con_type;         /*0: Int, 1: Float, -1: String*/
  union {
    int ival;
    float fval;
    char *sc;
  } const_u;
};

%}

%union {
    int i;
    float f;
    char* s;
    struct const_type *con_pt;
    char* ID_list;
    char* type;
    int num_args;
    int arr_dim;
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
%token <s> OP_ASSIGN  
%token <s> OP_OR   
%token <s> OP_AND  
%token <s> OP_NOT  
%token <s> OP_EQ   
%token <s> OP_NE   
%token <s> OP_GT   
%token <s> OP_LT   
%token <s> OP_GE   
%token <s> OP_LE   
%token <s> OP_PLUS 
%token <s> OP_MINUS        
%token <s> OP_TIMES        
%token <s> OP_DIVIDE       
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
%token CONST

%token COMMENT

%type<type> type var factor unary_op_res mul_op_res add_op_res comp_op_res
            and_op_res expression function_call
%type<ID_list> id_list id_tail

/*Use num_args to get number of arguments in function declaration and call*/
%type<num_args> parameter_list parameter_tail expression_list expression_tail

%type<arr_dim> bracket_chain parameter_bracket_chain

/*Use s to get operators*/
%type<s> comp_op add_op mul_op

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
    type ID MK_LPAREN parameter_list MK_RPAREN MK_LBRACE block RETURN MK_SEMICOLON MK_RBRACE
        {
            if(strcmp($1, "VOID")!=0){
                printf("Incompatible return type\n");
            } else {
                ptr p = insert_id(global, $2);
                strcpy(p->return_type, $1);
                p->arg_num = $4;
            }
        }
    |type ID MK_LPAREN parameter_list MK_RPAREN MK_LBRACE block RETURN expression MK_SEMICOLON MK_RBRACE
        {
            if(strcmp($1, $9)!=0){
                printf("Incompatible return type\n");
            } else {
                ptr p = insert_id(global, $2);
                strcpy(p->return_type, $1);
                p->arg_num = $4;
            }
        }
    | type ID MK_LPAREN parameter_list MK_RPAREN MK_SEMICOLON
        {
            ptr p = insert_id(global, $2);
            strcpy(p->return_type, $1);
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
            {
                ptr p = insert_id(global, $2);
                strcpy(p->return_type, $1);
            }

parameter_bracket_chain : 
    MK_LB MK_RB bracket_chain
        {
            if($3<1){
                $$ = -1;
            } else {
                $$ = 1 + $3;
            }
        }
    | bracket_chain {$$ = $1;}
    ;

block : 
    decl block
    | typedef_decl block
    | statement block
    | %empty
    ;

 decl : 
    /* //TEMPORARY COMMENTED OUT UNTIL PROBLEM OF PASSING AN
       //ID LIST IS SOLVED
    type id_list MK_SEMICOLON
    {
        //TODO: Fix this
        char* token;
        token = strtok($2, ",");
        printf("Type: %s\n", $1);
        printf("Full id_list: %s\n", $2);
        printf("Out: %s\n", out);
    }*/
    type ID bracket_chain MK_SEMICOLON
        {
            ptr p = insert_id(global, $2);
            strcpy(p-> return_type, $1);
            p-> arr_dim = $3;
        }
    | type ID OP_ASSIGN expression MK_SEMICOLON
        {
           // printf("Id to be inserted: %s\n", $2 );
            if(strcmp($1, $3)!=0
                &&((strcmp($1, "INT")!=0&&strcmp($1, "FLOAT")!=0))
                   ||(strcmp($3, "INT")!=0&&strcmp($3, "FLOAT")!=0)){
                printf("Incompatible type\n");
            } else {
                ptr p = insert_id(global, $2);
                strcpy(p-> return_type, $1);
	            //printf("declaration!\n");
            }
        }
    | CONST type ID OP_ASSIGN expression MK_SEMICOLON
    | typedef
    | struct_def
    ;

bracket_chain : 
    MK_LB expression MK_RB bracket_chain
        {
            if(strcmp($2, "INT")!=0){
                printf("Array subscript is not an integer\n");
                $$=-1;
            } else {
                $$ = 1 + $4;
            }
        }
    | %empty {$$ = 0;}
    ;


id_list : ID bracket_chain id_tail
    {
       // strcpy($$, $1);
        out = malloc(strlen($1)+1);
        strcpy(out, $1);
        $$=out;
    }
    ;

id_tail :
    MK_COMMA ID bracket_chain id_tail
    {
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
/*    | RETURN MK_SEMICOLON
    | RETURN expression MK_SEMICOLON */
    ;

expression_statement: expression MK_SEMICOLON
    ;

assignment_statement: assignment MK_SEMICOLON
    ;

assignment: var OP_ASSIGN expression
         {
             if(strcmp($1, $3)!=0
                &&((strcmp($1, "INT")!=0&&strcmp($1, "FLOAT")!=0))
                   ||(strcmp($3, "INT")!=0&&strcmp($3, "FLOAT")!=0)){
                 printf("Incompatible types %s and %s\n", $1, $3);
             } 
         }
    ;

reference_bracket_chain:
    MK_LB expression MK_RB reference_bracket_chain
    | MK_LB expression MK_RB
    ;

/* Expressions */

function_call : ID MK_LPAREN expression_list MK_RPAREN
                {
                    ptr p = search_id(global, $1);
                    if(p==NULL){
                        printf("Function '%s' not found.\n", $1);
                        $$=tERROR;
                    }else if (p->arg_num>$3){
                        printf("Too few arguments to function.\n");
                        $$=tERROR;
                    }else if (p-> arg_num<$3){
                        printf("Too many arguments to function.\n");
                        $$=tERROR;
                    }else{
                        $$ = p->return_type;
                    }
                }
    ;

expression_list :
    expression expression_tail {$$ = 1+$2;}
    | %empty {$$ = 0;}
    ;

expression_tail :
    MK_COMMA expression expression_tail {$$ = 1+$3;}
    | %empty {$$ = 0;}
    ;

expression : 
    expression OP_OR and_op_res
        {
            if(strcmp($1, "INT")!=0 || strcmp($3, "INT")!=0){
                $$=tERROR;
                printf("Invalid operand to %s\n", $2);
            }
            else {$$ = tINT;}
        }
    | and_op_res {$$ = $1;}
    ;

and_op_res : 
    and_op_res OP_AND comp_op_res
        {
            if(strcmp($1, "INT")!=0 || strcmp($3, "INT")!=0){
                $$=tERROR;
                printf("Invalid operand to %s\n", $2);
            }
            else {$$ = tINT;}
        }
    | comp_op_res {$$ = $1;}
    ;

comp_op_res : 
    comp_op_res comp_op add_op_res
        {
            if(strcmp($1, $3) != 0){
                $$=tERROR;
                printf("Invalid operand to %s\n", $2);
            }
            else {$$ = tINT;}
        }
    | add_op_res {$$ = $1;}
    ;

add_op_res : 
    add_op_res add_op mul_op_res
        {
            if((strcmp($1, "INT")!=0&&strcmp($1, "FLOAT")!=0)
            ||(strcmp($3, "INT")!=0&&strcmp($3, "FLOAT")!=0)){
                $$=tERROR;
                printf("Invalid operand to %s\n", $2);
            }
            else if (strcmp($1, $3) != 0){
                $$=tFLOAT;
            }
            else {$$ = $1;}
        }
    | mul_op_res {$$=$1;}
    ;

mul_op_res :
    mul_op_res mul_op unary_op_res
        {
            if((strcmp($1, "INT")!=0&&strcmp($1, "FLOAT")!=0)
            ||(strcmp($3, "INT")!=0&&strcmp($3, "FLOAT")!=0)){
                $$=tERROR;
                printf("Invalid operand to %s\n", $2);
            }
            else if (strcmp($1, $3) != 0){
                $$=tFLOAT;
            }
            else {$$ = $1;}
        }
    | unary_op_res {$$ = $1;}
    ;

unary_op_res :
    OP_MINUS factor
        {
            if(strcmp($2, "INT")!=0 && strcmp($2, "FLOAT")!=0){
                $$=tERROR;
                printf("Invalid operand to %s\n", $1);
            }
            else {$$ = $2;}
        }
    | OP_NOT factor
        {
            if(strcmp($2, "INT")!= 0){
                $$=tERROR;
                printf("Invalid operand to %s\n", $1);
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
    ID  {
            ptr p = search_id(global, $1);
            if (p == NULL){
                $$ = tERROR;
                printf("Variable '%s' not found.\n", $1);
            } else {
                $$ = p-> return_type;
            }
        }
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
main (argc, argv)
int argc;
char *argv[];
  {
     	yyin = fopen(argv[1],"r");
        global = init_scope();
     	yyparse();
     	printf("%s\n", "Parsing completed. No errors found.");
        print_symtab(global);
        cleanup_symtab(global);
  }
yyerror (mesg)
char *mesg;
{
	printf("%s\t%d\t%s\t%s\n", "Error found in Line ", linenumber, "next token: ", yytext );
  	printf("%s\n", mesg);
  	exit(1);
}
