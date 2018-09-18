#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "symbol_table.h"

static identifier* new_item(const char* key, const id_type type, const id_data* val) {
	identifier* id = malloc(sizeof(identifier));
	strcpy(id->key, key);
 	memcpy(&id->val, val, sizeof(id_data));
	id->type = type;
	return id;
}

symbol_table* st_new_table() {
	symbol_table* st = malloc(sizeof(symbol_table));
	st->size = 42; //placeholder
	st->count = 0;
	st->items = calloc((size_t)st->size, sizeof(identifier));
	return st;
}

static void del_item(identifier* id) {
	free(id->key);
	//free(id->val);
	//free(id->type);
	free(id);
}

void del_symbol_table(symbol_table* st) {
	int i;
	for ( i = 0; i < st->size; i++) {
		identifier* id = st->items[i];
		if (id != NULL) {
			del_item(id);
		}
	}
	free(st->items);
	free(st);
}



int main() {
	int num = 7;
	identifier* id = new_item("apple", int_t, &num);
	printf("id key: %s id val: %d\n", id->key, id->val);
	del_item(id);
	return 0;
}

		
