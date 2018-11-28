struct node{	/* Structure for Identifiers */
    char id[257];
    char scope[356];
    int fun;
    int freq;
    int arg_num;	/*# of Arguments in the function*/
    int return_type;	/*Return type of the function*/
    struct node *next;
    int offset;
    int place;
    int size;
};

typedef struct node* ptr;

#define TABLESIZE 100
ptr symtab[TABLESIZE];

struct com_node{	/* Structure for Comments */
    char *com;
    struct com_node *next;
};

struct com_node *comtab,*curcom;

/* Function definitions */
int hash(char *key);
ptr getnode(char *text);
struct com_node* getcomment(char *str);
void init_symtab();
void insert_id(char *text, char *scope);
ptr search_id(char *text, char *scope);
void print_symtab();
void cleanup_symtab();
void init_comtab();
void insert_comment(char *comment);
void print_comtab();
void cleanup_comtab();
