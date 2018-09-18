#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>

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
	st->size = INITIAL_SIZE; //defined in header
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

static int st_hash(const char* s, const int a, const int m){
	long hash = 0;
	const int len_s = strlen(s);
	int i;
	for (i = 0; i < len_s; i++) {
		hash += (long) pow(a, len_s - (i+1)) * s[i];
		hash = hash % m;
	}
	return (int) hash;
}

static int st_get_hash(const char* s, const int num_buckets,
		const int attempt) {
	const int hash_a = st_hash(s, PRIME_1, num_buckets);
	const int hash_b = st_hash(s, PRIME_2, num_buckets);
	return (hash_a + (attempt * (hash_b + 1))) % num_buckets;
}

// Public functions

void st_insert(symbol_table* st, const char* key, id_type type, id_data* val) {
	identifier* id = new_item(key, type, val);
	int index = st_get_hash(id->key, st->size, 0);
	identifier* current_id = st->items[index];
	int i = 1;
	while (current_id != NULL) {
		index = st_get_hash(id->key, st->size, i);
		current_id = st->items[index];
		i++;
	}
	st->items[index] = id;
	st->count++;
}

id_data* st_search(symbol_table* st, const char* key) {
	int index = st_get_hash(key, st->size, 0);
	identifier* id = st->items[index];
	int i = 1;
	while (id != NULL) {
		if (strcmp(id->key, key) == 0) {
			return id->val;
		}
		index = st_get_hash(key, st->size, i);
		id = st->items[index];
		i++;
	}	
	return NULL;
}

int main() {
	int num = 7;
	identifier* id = new_item("apple", int_id, &num);
	printf("id key: %s id val: %d\n", id->key, id->val);
	symbol_table* st = st_new_table();
	st_insert(st, "apple", int_id, &num);
	int* result = st_search(st, "apple");
	if (result == NULL) printf("not found\n");
	else printf("result: %d\n", result);	
	del_item(id);
	return 0;
}

		
