#define PRIME_1 151
#define PRIME_2 163
#define INITIAL_SIZE 42

typedef enum id_type {int_id, float_id} id_type;

typedef union id_data {
	int int_v;
	float float_v;
} id_data;

typedef struct identifier {
	char key[256];
	id_type type;
	id_data* val;
} identifier;

typedef struct symbol_table {
	int size;
	int count;
	identifier** items;
} symbol_table;


