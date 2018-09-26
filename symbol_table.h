#define PRIME_1 151
#define PRIME_2 163
#define INITIAL_SIZE 53


typedef struct identifier {
	char key[256];
	int* val;
} identifier;

typedef struct symbol_table {
	int size;
	int count;
	identifier** ids;
} symbol_table;

symbol_table* st_new_table(); //allocates a new symbol table
void st_del_table(symbol_table* st); //deallocates the table inputted
void st_delete(symbol_table* st, const char* key); //deletes the inputted item in the table 
void st_insert(symbol_table* st, const char* key, int* val); //inserts the given (key, val) pair into the table
int* st_search(symbol_table* st, const char* key); //finds the value for the given key

//sentinel to mark deleted items
static identifier ST_DELETED_ITEM = {NULL, NULL};
