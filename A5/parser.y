/* ===== Definition Section ===== */

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "symboltable.h"

static int linenumber = 1;

int ARoffset;
int reg_number = 8;
int current_type;
char current_scope[256] = "global";

void gen_prologue(char* name){
    printf(".text\n");
    printf("\tsw $ra, 0($sp)\n");
    printf("\tsw $fp, -4($sp)\n");
    printf("\tadd $fp, $sp, -4\n");
    printf("\tadd $sp, $sp, -8\n");
    printf("\tlw $2, _framesize_%s\n", name);
    printf("\tsub $sp, $sp, $2\n");
    printf("_begin_%s:\n", name);
}

void gen_epilogue(char* name){
    printf("_end_%d:\n", name);
    printf("\tlw $ra, 4($fp)\n");
    printf("\tadd $sp, $fp, 4\n");
    printf("\tlw $fp, 0($fp)\n");
    if(strcmp(name, "main")==0){
        printf("\tli $v0, 10\n");
        printf("\tsyscall\n");
    } else {
        printf("\t jr $ra\n");
    }
    printf(".data\n");
    printf("_framesize_%s\n:\t.word\t%d", name, ARoffset);
}

void gen_head(char* name){
    printf(".text");
    printf("%s:\n", name);
}
int get_reg(){
    if(reg_number > 15){
        reg_number = 8;
    }
    return reg_number++;
}

struct cnst_struct{
    int i;
    float f;
    char s[256];
};

%}

%union {
 char id[256];
 ptr p;
 int i;
}

%token<id> ID
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

%type<i> type dim_decl

%start program

%%

/* ==== Grammar Section ==== */

/* Productions */               /* Semantic actions */
program		: global_decl_list
		;

global_decl_list: global_decl_list global_decl
                |
		;

global_decl	: decl_list function_decl
		| function_decl
		;

function_decl	: type ID MK_LPAREN param_list MK_RPAREN {strcpy(current_scope, $2);} MK_LBRACE block MK_RBRACE
		/* | Other function_decl productions */
                /*Empty parameter list.*/
		| type ID MK_LPAREN MK_RPAREN {strcpy(current_scope, $2);}  MK_LBRACE block MK_RBRACE
                /*Function declarations. The above ones are function definitions*/
		| type ID MK_LPAREN param_list MK_RPAREN MK_SEMICOLON 
		| type ID MK_LPAREN MK_RPAREN MK_SEMICOLON
		;

param_list	: param_list MK_COMMA  param 
		| param	
		;

param		: type ID 
		| struct_type ID
		| type ID dim_fn
		| struct_type ID dim_fn 
		;

dim_fn		:MK_LB expr_null MK_RB dimfn1
		;

dimfn1		:MK_LB expr MK_RB dimfn1
		|
		;

expr_null	:expr
		|
		;

block           : decl_list stmt_list 
                | stmt_list
                | decl_list
                |
                ;
 
decl_list	: decl_list decl
		| decl
		;

decl		: type_decl
		| var_decl
		;

type_decl 	: TYPEDEF type id_list MK_SEMICOLON
		| TYPEDEF VOID id_list MK_SEMICOLON
		| TYPEDEF struct_type id_list MK_SEMICOLON
		| struct_type MK_SEMICOLON
		;

var_decl	: type {current_type = $1;} init_id_list MK_SEMICOLON
		| struct_type id_list MK_SEMICOLON
		| ID id_list MK_SEMICOLON 
		;

/* Suppported types. */
type		: INT {$$ = 4;}
		| FLOAT {$$ = 8;}
		| VOID {$$ = 0;}
        	|error {$$ = -1;}
		;

struct_type	: STRUCT tag
		;

/* Struct variable body. */
tag		: ID MK_LBRACE decl_list MK_RBRACE
		| MK_LBRACE decl_list MK_RBRACE
		| ID MK_LBRACE MK_RBRACE
		| MK_LBRACE MK_RBRACE
		| ID
		;


id_list		: ID
		| id_list MK_COMMA ID
		| id_list MK_COMMA ID dim_decl
		| ID dim_decl
		;
dim_decl	: MK_LB cexpr MK_RB {$$ = 1;}
		| dim_decl MK_LB cexpr MK_RB {$$ = 1 + $1;}
		;
cexpr		: cexpr add_op mcexpr
		| mcexpr
		;  
mcexpr		: mcexpr mul_op cfactor
		| cfactor 
		;

cfactor:	CONST 
		| MK_LPAREN cexpr MK_RPAREN
		;

init_id_list	: init_id
		| init_id_list MK_COMMA init_id
		;

init_id		: ID {
                    ptr p;
                    insert_id($1);
                    p = search_id($1);
                    if(p!=NULL){
                        p -> size = current_type;
                        p -> fun = 0;
                        strcpy(p -> scope, current_scope);
                    }
                 }
		| ID dim_decl {
                        ptr p;
                        insert_id($1);
                        p = search_id($1);
                        if(p!=NULL){
                            p -> size = current_type*$2;
                            p -> fun = 0;
                            strcpy(p -> scope, current_scope);
                        }
                      }
		| ID OP_ASSIGN relop_expr
		;

stmt_list	: stmt_list stmt
		| stmt
		;

stmt		: MK_LBRACE block MK_RBRACE
		/* | While Statement here */
		| WHILE MK_LPAREN relop_expr_list MK_RPAREN stmt
	        | FOR MK_LPAREN assign_expr_list MK_SEMICOLON relop_expr_list MK_SEMICOLON assign_expr_list MK_RPAREN stmt 
		/* | If then else here */ 
		| IF MK_LPAREN relop_expr MK_RPAREN stmt ELSE stmt
		/* | If statement here */ 
		| IF MK_LPAREN relop_expr MK_RPAREN stmt 
		/* | read and write library calls -- note that read/write are not keywords */ 
		| ID MK_LPAREN relop_expr_list MK_RPAREN
		| var_ref OP_ASSIGN relop_expr MK_SEMICOLON 
		| relop_expr_list MK_SEMICOLON
		| MK_SEMICOLON
		| RETURN MK_SEMICOLON
		| RETURN relop_expr MK_SEMICOLON
		;

assign_expr_list : nonempty_assign_expr_list
                |
                ;

nonempty_assign_expr_list        : nonempty_assign_expr_list MK_COMMA assign_expr
                | assign_expr

assign_expr     : ID OP_ASSIGN relop_expr 
                | relop_expr


relop_expr	: relop_term
		| relop_expr OP_OR relop_term
		;

relop_term	: relop_factor
		| relop_term OP_AND relop_factor
		;

relop_factor	: expr
		| expr rel_op expr
		;

/* Relational operators added.*/
rel_op		: OP_LT
		| OP_LE
		| OP_GT
		| OP_GE
		| OP_EQ
		| OP_NE
		;

relop_expr_list	: nonempty_relop_expr_list 
		| 
		;

nonempty_relop_expr_list	: nonempty_relop_expr_list MK_COMMA relop_expr
		| relop_expr
		;

expr		: expr add_op term
		| term
		;

add_op		: OP_PLUS
		| OP_MINUS
		;

term		: term mul_op factor
		| factor
		;

mul_op		: OP_TIMES
		| OP_DIVIDE
		;

factor		: MK_LPAREN relop_expr MK_RPAREN
		/* | -(<relop_expr>) */ 
		| OP_NOT MK_LPAREN relop_expr MK_RPAREN
                /* OP_MINUS condition added as C could have a condition like: "if(-(i < 10))".	*/		
		| OP_MINUS MK_LPAREN relop_expr MK_RPAREN
		| CONST	
		/* | - constant, here - is an Unary operator */ 
		| OP_NOT CONST
                /*OP_MINUS condition added as C could have a condition like: "if(-10)".	*/		
		| OP_MINUS CONST
		| ID MK_LPAREN relop_expr_list MK_RPAREN
		/* | - func ( <relop_expr_list> ) */ 
		| OP_NOT ID MK_LPAREN relop_expr_list MK_RPAREN
                /* OP_MINUS condition added as C could have a condition like: "if(-read(i))".	*/	
		| OP_MINUS ID MK_LPAREN relop_expr_list MK_RPAREN
		| var_ref
		/* | - var-reference */ 
		| OP_NOT var_ref
                /* OP_MINUS condition added as C could have a condition like: "if(-a)".	*/	
		| OP_MINUS var_ref
		;

var_ref		: ID 
		| var_ref dim
		| var_ref struct_tail
		;


dim		: MK_LB expr MK_RB
		;

struct_tail	: MK_DOT ID
		;
%%
#include "lex.yy.c"

int scope = 0;

int main (int argc, char *argv[])
{
    init_symtab();
    if(argc>0)
        yyin = fopen(argv[1],"r");
    else
        yyin=stdin;
    yyparse();
    printf("%s\n", "Parsing completed. No errors found.");
    print_symtab();
    cleanup_symtab();
    return 0;
} /* main */


yyerror (mesg)
char *mesg;
  {
      printf("%s\t%d\t%s\t%s\n", "Error found in Line ", linenumber, "next token: ", yytext );
      printf("%s\n", mesg);
      exit(1);
  }