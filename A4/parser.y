/* ===== Definition Section ===== */

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "symboltable.h"
static int linenumber = 1;
int ARoffset = 0;
int reg_number = 8;
int exit_number = 0;
int else_number = 0;
int while_number = 0;

int exit_stack[10];
int iexit = -1;
int else_stack[10];
int ielse = -1;
int while_stack[10];
int iwhile;

void push(char *stack, int label){
    if(strcmp(stack, "exit")==0){
        iexit++;
        exit_stack[iexit] = label;
    } else if (strcmp(stack, "else")==0) {
        ielse++;
        else_stack[ielse] = label;
    } else {
        iwhile++;
        while_stack[iwhile] = label;
    }
}

int pop(char *stack){
    int out;
    if(strcmp(stack, "exit")==0){
        out = exit_stack[iexit];
        iexit--;
    } else if(strcmp(stack, "else")==0){
        out = else_stack[ielse];
        ielse--;
    } else {
        out = while_stack[iwhile];
        iwhile--;
    }
    return out;
}

void insert(char *name){
    insert_id(name);
    ptr p = search_id(name);
    if(p==NULL){
        printf("ERROR: Failed inserting ID '%s'\n", name);
    } else {
        p->offset = ARoffset;
        ARoffset -=4; //Only for int;
    }
}

void gen_head(char *name){
    printf(".text\n");
    printf("%s:\n", name);
}

void gen_prologue(char *name){
    printf("sw $ra, 0($sp)\n");
    printf("sw $fp, -4($sp)\n");
    printf("add $fp, $sp, -4\n"); //Only for int
    printf("add $sp, $sp, -8\n"); //Only for int
    printf("lw $2, _framesize_%s\n", name);
    printf("sub $sp, $sp, $2\n");
    printf("_begin_%s:\n", name);
}

void gen_epilogue(char *name){
    printf("_end_%s:\n", name);
    printf("lw $ra, 4($fp)\n"); //Only for int
    printf("add $sp, $fp, 4\n"); //Only for int
    printf("lw $fp, 0($fp)\n");
    if (strcmp(name, "main") == 0) {
        printf("li $v0, 10\nsyscall\n");
    } else {
        printf("jr $ra\n");
    }
    printf(".data\n");
    printf("_framesize_%s:\t.word %d\n", name, (reg_number-8)*4);
}

int get_reg() {
    reg_number += 1;
    if(reg_number > 15){
        reg_number = 8;
    }
    return reg_number;
}

int get_exit() {return (exit_number++);}

int get_else() {return (else_number++);}

int get_while() {return (while_number++);}

int get_offset(char *name){
    ptr p = search_id(name);
    if(p == NULL){
        printf("ERROR: Couldn't find ID '%s'\n", name);
        return -314;
    } else {
        return p->offset;
    }
}

%}

%union {
    ptr n;
}

%token<n> ID
%token<n> CONST
%token<n> VOID    
%token<n> INT     
%token<n> FLOAT   
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

%type<n> id_list var_decl var_ref init_id_list init_id relop_expr
         relop_term relop_factor expr term factor decl decl_list
         block relop_expr_list nonempty_relop_expr_list stmt

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

function_decl	: type ID MK_LPAREN param_list MK_RPAREN MK_LBRACE block MK_RBRACE
		/* | Other function_decl productions */
                /*Empty parameter list.*/
		| type ID MK_LPAREN MK_RPAREN
        {
            gen_head($2->id);
            gen_prologue($2->id);
        }
        MK_LBRACE block MK_RBRACE
        {
            gen_epilogue($2->id);
        }

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
                | stmt_list {$$=NULL;}
                | decl_list
                |
                ;
 
decl_list	: decl_list decl
            {
                $$ = $2;
                $$->next = $1;
            }
		| decl
		;

decl		: type_decl {$$=NULL;}
		| var_decl
		;

type_decl 	: TYPEDEF type id_list MK_SEMICOLON
		| TYPEDEF VOID id_list MK_SEMICOLON
		| TYPEDEF struct_type id_list MK_SEMICOLON
		| struct_type MK_SEMICOLON
		;

var_decl	: type init_id_list MK_SEMICOLON{
                ptr p = $2;
                while (p!=NULL){
                    insert(p->id);
                    p = p->next;
                }
                $$ = $2;
            }
		| struct_type id_list MK_SEMICOLON{
            $$=NULL;
        }
		| ID id_list MK_SEMICOLON{
            ptr p = $2;
            while (p!=NULL){
                insert(p->id);
                p = p->next;
            }
            $$ = $2;
        }
		;

/* Suppported types. */
type		: INT
		| FLOAT
		| VOID
        	|error
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


id_list		: ID {
                $$ = $1;
            } 
		| id_list MK_COMMA ID {
            $$  = $3;
            $$->next = $1;
        }
		| id_list MK_COMMA ID dim_decl{
            $$ = $3;
            $$->next = $1;
        }
		| ID dim_decl {$$ = $1;}
		;
dim_decl	: MK_LB cexpr MK_RB 
		| dim_decl MK_LB cexpr MK_RB
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
		| init_id_list MK_COMMA init_id{
            $$=$3;
            $3->next = $1;
        }
		;

init_id		: ID
		| ID dim_decl
		| ID OP_ASSIGN relop_expr 
		;

stmt_list	: stmt_list stmt
		| stmt
		;

stmt		: MK_LBRACE block MK_RBRACE
		/* | While Statement here */
		/*| WHILE MK_LPAREN relop_expr_list MK_RPAREN stmt*/
        /*TODO: expand for the case of while(a, b, c,...){}*/
        | WHILE MK_LPAREN relop_expr MK_RPAREN
        {
            int reg, whilel;
            whilel= get_while();
            reg = get_reg();
            push("while", whilel);
            printf("_Test%d:\n", whilel);
            if($3->scope!=NULL){
                printf("lw $%d, _%s\n", reg, $3->id);
                printf("beqz $%d, _Lexit%d\n", reg, whilel);
            } else {
                printf("beqz $%d, _Lexit%d\n", $3->place, whilel);
            }
        }
        stmt
        {
            int whilel = pop("while");
            printf("j _Test%d\n", whilel);
            printf("_Lexit%d:\n", whilel);
        }
	    | FOR MK_LPAREN assign_expr_list MK_SEMICOLON relop_expr_list MK_SEMICOLON assign_expr_list MK_RPAREN stmt 
		/* | If then else here */ 
		| IF MK_LPAREN relop_expr MK_RPAREN
        {
            int reg, elsel;
            reg = get_reg();
            elsel = get_else();
            push("else", elsel);
            if($3->scope!=NULL){
                printf("lw $%d, _%s\n", reg, $3->id);
                printf("beqz $%d, Lelse%d\n", reg, elsel);
            } else {
                printf("beqz $%d, Lelse%d\n", $3->place, elsel);
            }
            
        }
        stmt ELSE
        {
            int exitl, elsel;
            exitl = get_exit();
            push("exit", exitl);
            elsel = pop("else");
            printf("j Lexit%d\n", exitl);
            printf("Lelse%d:\n", elsel);
        }
        stmt
        {
            printf("Lexit%d:\n", pop("exit"));
        }
		/* | If statement here */ 
		| IF MK_LPAREN relop_expr MK_RPAREN
        {
            int reg, exitl;
            reg = get_reg();
            exitl = get_exit();
            if($3->scope!=NULL){
                printf("lw $%d, _%s\n", reg, $3->id);
                printf("beqz $%d, Lexit%d\n", reg, exitl);
            } else {
                printf("beqz $%d, Lexit%d\n", $3->place, exitl);
            }
            push("exit", exitl);
        }
        stmt
        {
            printf("Lexit%d:\n", pop("exit"));
        }
		/* | read and write library calls -- note that read/write are not keywords */ 
		| ID MK_LPAREN relop_expr_list MK_RPAREN{
            if(strcmp($1->id, "write")==0){
                int label = get_while();
                printf(".data\n");
                printf("m%d:\t.asciiz\t%s\n", label,$3->id);
                printf(".text\n");
                printf("li $v0 4\n");
                printf("la $a0 m%d\n", label);
                printf("syscall\n");
            } else if (strcmp($1->id, "read")==0){
                int reg = get_reg();
                printf("li $v0 5\n");
                printf("syscall\n");
                printf("move $%d, $v0\n", reg);
                $$->place=reg;
                
            }
        }
		| var_ref OP_ASSIGN relop_expr MK_SEMICOLON{
            int offset, reg;
            reg = $3->place;
            if($1->scope == NULL){
                offset = get_offset($1->id);
                printf("sw $%d, %d($fp)\n", reg, offset);
            } else {
                printf("sw $%d, _%s", reg, $1->id);
            }
        }
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
                    {
                        
                    }
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

expr		: expr OP_PLUS term{
                int reg = get_reg();
                printf("add $%d, $%d, $%d\n", reg, $1->place, $3->place);
                $$=$1;
                $$->place = reg;
            }
        | expr OP_MINUS term{
            int reg = get_reg();
            printf("sub $%d, $%d, $%d\n", reg, $1->place, $3->place);
            $$=$1;
            $$->place = reg;
        }
		| term
		;

add_op      : OP_PLUS
        |OP_MINUS
        ;

term		: term OP_TIMES factor{
                int reg = get_reg();
                printf("mul $%d, $%d, $%d\n", reg, $1->place, $3->place);
                $$=$1;
                $$->place = reg;
                
            }
        | term OP_DIVIDE factor{
            int reg = get_reg();
            printf("div $%d, $%d, $%d\n", reg, $1->place, $3->place);
            $$=$1;
            $$->place = reg;
        }
		| factor
		;

mul_op      : OP_TIMES
        | OP_DIVIDE
        ;

factor		: MK_LPAREN relop_expr MK_RPAREN {$$=NULL;}
		/* | -(<relop_expr>) */ 
		| OP_NOT MK_LPAREN relop_expr MK_RPAREN {$$=NULL;}
                /* OP_MINUS condition added as C could have a condition like: "if(-(i < 10))".	*/		
		| OP_MINUS MK_LPAREN relop_expr MK_RPAREN {$$=NULL;}
		| CONST{
                int reg;
                reg = get_reg();
                printf("li $%d, %d\n", reg, $1->value);
                $$->place = reg;
            }	
		/* | - constant, here - is an Unary operator */ 
		| OP_NOT CONST {$$=NULL;}
                /*OP_MINUS condition added as C could have a condition like: "if(-10)".	*/
		| OP_MINUS CONST
        {
            int reg;
            reg = get_reg();
            printf("li $%d, %d\n", reg, 0-$2->value);
            $$->place = reg;
        }
		| ID MK_LPAREN relop_expr_list MK_RPAREN {$$=NULL;}
		/* | - func ( <relop_expr_list> ) */ 
		| OP_NOT ID MK_LPAREN relop_expr_list MK_RPAREN {$$=NULL;}
                /* OP_MINUS condition added as C could have a condition like: "if(-read(i))".	*/	
		| OP_MINUS ID MK_LPAREN relop_expr_list MK_RPAREN {$$=NULL;}
		/*| var_ref*/
        | ID {
            int offset, reg;
            reg = get_reg();
            $$->place = reg;
            offset = get_offset($1->id);
            printf("lw $%d, %d($fp)\n", reg, offset);
        }
		/* | - var-reference */ 
		| OP_NOT var_ref {$$=NULL;}
                /* OP_MINUS condition added as C could have a condition like: "if(-a)".	*/	
		| OP_MINUS var_ref {$$=NULL;}
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
