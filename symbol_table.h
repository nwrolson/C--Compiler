typedef enum id_type {int_t, float_t} id_type;

typedef union id_data {
	int int_v;
	float float_v;
} id_data;

typedef struct identifier {
	char key[256];
	id_type type;
	id_data val;
} identifier;

typedef struct symbol_table {
	int size;
	int count;
	identifier** items;
} symbol_table;


