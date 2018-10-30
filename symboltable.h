struct node{	/* Structure for Identifiers */
    char id[257];
    int freq;
    int arg_num;	/*# of Arguments in the function*/
    char return_type[257];	/*Return type of the function*/
    struct node *next;
};

typedef struct node* ptr;

#define TABLESIZE 100
#define tVOID "VOID"
#define tINT "INT"
#define tFLOAT "FLOAT"
#define tINTARR "INTARR"
#define tFLOATARR "FLOATARR"
#define tCHAR "CHAR"
#define tERROR "ERROR"
#define tTEMP "TEMPTYPE"

typedef struct scope {
    ptr* symtab;
    struct scope *parent;
} scope;

struct com_node{	/* Structure for Comments */
    char *com;
    struct com_node *next;
};

struct com_node *comtab,*curcom;

/* Function definitions */
int hash(char *key);
ptr getnode(char *text);
struct com_node* getcomment(char *str);
scope* init_scope();
ptr insert_id(scope* s, char *text);
ptr search_id(scope* s, char *text);
void print_symtab(scope* s);
void cleanup_symtab(scope* s);
void init_comtab();
void insert_comment(char *comment);
void print_comtab();
void cleanup_comtab();
