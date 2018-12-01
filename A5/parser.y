/* ===== Definition Section ===== */

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "symboltable.h"
#include "stack.h"

static int linenumber = 1;

int ARoffset;
int reg_number = 8;
int current_type;
char current_scope[256] = "global";
int current_label=0;

int get_label(){
    return current_label++;
}

void gen_prologue(char* name){
    printf("\tsw $ra, 0($sp)\n");
    printf("\tsw $fp, -4($sp)\n");
    printf("\tadd $fp, $sp, -4\n");
    printf("\tadd $sp, $sp, -8\n");
    printf("\tlw $2, _framesize_%s\n", name);
    printf("\tsub $sp, $sp, $2\n");
    printf("_begin_%s:\n", name);
}

void gen_epilogue(char* name){
    printf("_end_%s:\n", name);
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
    printf("_framesize_%s:\t.word\t%d\n", name, -ARoffset);
}

void gen_head(char* name){
    printf(".text\n");
    printf("%s:\n", name);
}
int get_reg(){
    if(reg_number > 15){
        reg_number = 8;
    }
    return reg_number++;
}

int get_offset(char* id, char* scope){
    ptr p;
    p = search_id(id, scope);
    if(p==NULL){
        p = search_id(id, "global");
        if(p==NULL){
            return 3;
        }
        return 5;
    }
    return p->offset;
}

void insert_var(char* id, int arr){
    ptr p;
    p = search_id(id, current_scope);
    if (p!=NULL){
        printf("Error, ID '%s' already declared in scope.\n", id);
        return;
    }
    insert_id(id, current_scope);
    p = search_id(id, current_scope);
    if(p!=NULL){
        p -> size = current_type*arr;
        p -> fun = 0;
        if(strcmp(current_scope, "global")){
            p->offset = ARoffset;
            ARoffset -= p->size;
        }
    }
}

struct cnst_struct{
    int type;
    int i;
    float f;
    char s[256];
};

struct var_ref{
    int offset;
    char id[256];
};

%}

%union {
 char id[256];
 ptr p;
 int i;
 int op;
 int place;
 struct cnst_struct* con;
 struct var_ref* var;
 int dim;
}

%token<id> ID
%token<con> CONST
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

%type<i> type dim_decl dim_fn dimfn1 struct_type
%type<place> relop_expr relop_term relop_factor expr term factor
%type<var> var_ref
%type<op> add_op mul_op rel_op
%type<dim> cexpr mcexpr cfactor

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

function_decl	: type ID MK_LPAREN param_list MK_RPAREN MK_LBRACE {
                    ARoffset = -4; /*TODO: Fix AR offset for parameters*/
                    gen_head($2);
                    gen_prologue($2);
                    strcpy(current_scope, $2);
                    change_scope("param", current_scope);
                } block {
                    gen_epilogue($2);
                } MK_RBRACE {strcpy(current_scope, "global");}
                /*Empty parameter list.*/
		| type ID MK_LPAREN MK_RPAREN MK_LBRACE {
            ARoffset = -4;
            gen_head($2);
            gen_prologue($2);
            strcpy(current_scope, $2);
        } block {
            gen_epilogue($2);
        } MK_RBRACE {strcpy(current_scope, "global");}
                /*Function declarations. The above ones are function definitions*/
		| type ID MK_LPAREN param_list MK_RPAREN MK_SEMICOLON 
		| type ID MK_LPAREN MK_RPAREN MK_SEMICOLON
		;

param_list	: param_list MK_COMMA  param 
		| param	
		;

param		: type ID
        {
            current_type = $1;
            strcpy(current_scope, "param");
            insert_var($2, 1);
        }
		| struct_type ID
		| type ID dim_fn
        {
            current_type = $1;
            strcpy(current_scope, "param");
            insert_var($2, $3);
        }
		| struct_type ID dim_fn 
		;

dim_fn		:MK_LB expr_null MK_RB dimfn1 {$$ = 1 + $4;}
		;

dimfn1		:MK_LB expr MK_RB dimfn1 {$$ = 1 + $4;}
		| {$$ = 0;}
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

struct_type	: STRUCT tag {$$ = -1;} /*UNIMPLEMENTED*/
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
dim_decl	: MK_LB cexpr MK_RB {$$ = $2;}
		| dim_decl MK_LB cexpr MK_RB {$$ = $1 + $3;}
		;
cexpr		: cexpr add_op mcexpr {$$ = $1 + $3;}
		| mcexpr {$$ = $1;}
		;  
mcexpr		: mcexpr mul_op cfactor {$$ = $1 * $3;}
		| cfactor {$$ = $1;}
		;

cfactor:	CONST {$$ = $1->i;}
		| MK_LPAREN cexpr MK_RPAREN {$$ = $2;}
		;

init_id_list	: init_id
		| init_id_list MK_COMMA init_id
		;

init_id		: ID {
                    insert_var($1, 1);
                    if(strcmp(current_scope, "global")==0){
                        printf("\t.data\n");
                        printf("\t.align 2\n");
                        printf("_%s:\t.space %d", $1, current_type);
                    }
                 }
		| ID dim_decl {
            insert_var($1, $2);
            if(strcmp(current_scope, "global")==0){
                printf("\t.data\n");
                printf("\t.align 2\n");
                printf("_%s:\t.space %d", $1, current_type*$2);
            }
          }
        /*| ID OP_ASSIGN relop_expr*/
		| ID OP_ASSIGN CONST {
            insert_var($1, 1);
            if(strcmp(current_scope, "global")==0){
                printf("\t.data\n");
                printf("\t.align 2\n");
                printf("_%s:\t.space %d", $1, current_type);
            }
            int reg = get_reg();
            if($3->type == 1){
                printf("\tli $%d, %d\n", reg, $3->i);
            } else if ($3->type == 2){
                printf("\tli $%d, %f\n", reg, $3->f);
            }
            if(strcmp(current_scope, "global")==0){
                printf("\tsw $%d, _%s\n", reg, $1);
            } else {
                int offset = get_offset($1, current_scope);
                printf("\tsw $%d, %d($fp)\n", reg, offset);
            }
          }
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
		| var_ref OP_ASSIGN relop_expr MK_SEMICOLON{
            if($1->offset != 5){
                printf("\tsw $%d, %d($fp)\n", $3, $1->offset);
            } else {
                printf("\tsw $%d, _%s\n", $3, $1->id);
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

assign_expr     : ID OP_ASSIGN relop_expr {
                    int offset = get_offset($1, current_scope);
                    printf("\tsw $%d, %d($fp)\n", $3, offset);
                }
                | relop_expr


relop_expr	: relop_term
		| relop_expr OP_OR relop_term {
            int label = get_label();
            int reg = get_reg();
            printf("\tbnez $%d, T%d\n", $1, label); //If first statement is true, jump to true label
            printf("\tbnez $%d, T%d\n", $3, label); //If second statement is true, jump to true label
            printf("F%d:\n", label); //False label
            printf("\tli $%d, 0\n", reg); //Set register to false
            printf("\tj E%d\n", label); //Jump to exit
            printf("T%d:\n", label); //True label
            printf("\tli $%d, 1\n", reg); //Set register to true
            printf("E%d:\n", label); //Exit label
            $$ = reg;
          }
		;

relop_term	: relop_factor
		| relop_term OP_AND relop_factor {
            int label = get_label();
            int reg = get_reg();
            printf("\tbeqz $%d, F%d\n", $1, label); //If first statement is false, jump to false label
            printf("\tbeqz $%d, F%d\n", $3, label); //If second statement is false, jump to false label
            printf("T%d:\n", label); //True label
            printf("\tli $%d, 1\n", reg); //Set register to true
            printf("\tj E%d\n", label); //Jump to exit
            printf("F%d:\n", label); //False label
            printf("\tli $%d, 0\n", reg); //Set register to false
            printf("E%d:\n", label); //Exit label
            $$ = reg;
        }
		;

relop_factor	: expr
		| expr rel_op expr{
            int reg = get_reg();
            switch($2){
                case 0:
                    printf("\tslt ");
                    break;
                case 1:
                    printf("\tsle ");
                    break;
                case 2:
                    printf("\tsgt ");
                    break;
                case 3:
                    printf("\tsge ");
                    break;
                case 4:
                    printf("\tseq ");
                    break;
                case 5:
                    printf("\tsne ");
                    break;
            }
            printf("$%d, $%d, $%d\n", reg, $1, $3);
            $$ = reg;
          }
		;

/* Relational operators added.*/
rel_op		: OP_LT {$$ = 0;}
		| OP_LE {$$ = 1;}
		| OP_GT {$$ = 2;}
		| OP_GE {$$ = 3;}
		| OP_EQ {$$ = 4;}
		| OP_NE {$$ = 5;}
		;

relop_expr_list	: nonempty_relop_expr_list 
		| 
		;

nonempty_relop_expr_list	: nonempty_relop_expr_list MK_COMMA relop_expr
		| relop_expr
		;

expr		: expr add_op term
        {
            int reg = get_reg();
            if($2==0){
                printf("\tadd ");
            }else{
                printf("\tsub ");
            }
            printf("$%d, $%d, $%d\n", reg, $1, $3);
            $$ = reg;
        }
		| term
		;

add_op		: OP_PLUS {$$ = 0;}
		| OP_MINUS {$$ = 1;}
		;

term		: term mul_op factor
        {
            int reg = get_reg();
            if($2==0){
                printf("\tmul ");
            }else{
                printf("\tdiv ");
            }
            printf("$%d, $%d, $%d\n", reg, $1, $3);
            $$ = reg;
        }
		| factor
		;

mul_op		: OP_TIMES {$$ = 0;}
		| OP_DIVIDE {$$ = 1;}
		;

factor		: MK_LPAREN relop_expr MK_RPAREN {$$ = -1;} /*UNIMPLEMENTED*/
		/* | -(<relop_expr>) */ 
		| OP_NOT MK_LPAREN relop_expr MK_RPAREN {$$ = -1;} /*UNIMPLEMENTED*/
                /* OP_MINUS condition added as C could have a condition like: "if(-(i < 10))".	*/		
		| OP_MINUS MK_LPAREN relop_expr MK_RPAREN {$$ = -1;} /*UNIMPLEMENTED*/
		| CONST {
                    int reg=get_reg();
                    if($1->type == 1){
                        printf("\tli $%d, %d\n", reg, $1->i);
                        $$ = reg;
                    }
                    if($1->type == 3){
                        printf("\t.data\n");
                        printf("Label:\t.ascii\t%s", $1->s); /*TODO: Make label generator. Make method to pass string literal labels*/
                    }
                } /*UNIMPLEMENTED*/	
		/* | - constant, here - is an Unary operator */ 
		| OP_NOT CONST {$$ = -1;} /*UNIMPLEMENTED*/
                /*OP_MINUS condition added as C could have a condition like: "if(-10)".	*/		
		| OP_MINUS CONST {$$ = -1;} /*UNIMPLEMENTED*/
		| ID MK_LPAREN relop_expr_list MK_RPAREN {$$ = -1;}/*UNIMPLEMENTED*/
		/* | - func ( <relop_expr_list> ) */ 
		| OP_NOT ID MK_LPAREN relop_expr_list MK_RPAREN {$$ = -1;}/*UNIMPLEMENTED*/
                /* OP_MINUS condition added as C could have a condition like: "if(-read(i))".	*/	
		| OP_MINUS ID MK_LPAREN relop_expr_list MK_RPAREN {$$ = -1;}
		| var_ref {
            int reg = get_reg();
            if($1->offset == 3){
                printf("Error, ID not declared in this scope.\n");
                $$ = -1;
            }else if($1->offset == 5){
                printf("\tlw $%d, _%s\n", reg, $1->id);
                $$ = reg;
            }else {
                printf("\tlw $%d, %d($fp)\n", reg, $1->offset);
                $$ = reg;
            }
        }
		/* | - var-reference */ 
		| OP_NOT var_ref {$$ = -1;} /*UNIMPLEMENTED*/
                /* OP_MINUS condition added as C could have a condition like: "if(-a)".	*/	
		| OP_MINUS var_ref {$$ = -1;} /*UNIMPLEMENTED*/
		;

var_ref		: ID {
                struct var_ref *p;
                p = (struct var_ref *) malloc(sizeof(struct var_ref));
                p->offset = get_offset($1, current_scope);
                strcpy(p->id, $1);
                $$ = p;
            }
		| var_ref dim {$$ = NULL;} /*UNIMPLEMENTED*/
		| var_ref struct_tail{$$ = NULL;} /*UNIMPLEMENTED*/
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
