struct node{	/* Structure for Identifiers */
    char id[257];
    int freq;
    int arg_num;	/*# of Arguments in the function*/
    int return_type;	/*Return type of the function*/
    struct node *next;
};

typedef struct node* ptr;

#define TABLESIZE 100
#define tVOID 0
#define tINT 1
#define tFLOAT 2
#define tINT_ARR 3
#define tFLOAT_ARR 4
#define tCHAR 5

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
