#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <stdio.h>

#include "symbol_table.h"

// Internal Functions

static identifier* st_new_id(const char* key, const int* val) {
	identifier* id = malloc(sizeof(identifier));
	strcpy(id->key, key);
	memcpy(&id->val, val, sizeof(int));
	return id;
}

static void st_del_id(identifier* id) {
	//free(id->key);
	//free(id->val);
	//free(id);
}

static int st_hash(const char* key, const int prime, const int mod) {
	long hash = 0;
	const int length_key = strlen(key);
	int i;
	for (i = 0; i < length_key; i++) {
		hash += (long) pow(prime, length_key - (i+1)) * key[i];
		hash = hash % mod;
	}
	return (int) hash;
}

static int st_get_hash(const char* key, const int size, const int attempt) {
	const int hash_a = st_hash(key, PRIME_1, size);
	const int hash_b = st_hash(key, PRIME_2, size);
	return (hash_a + (attempt * (hash_b + 1))) % size;
}

// Public Functions

symbol_table* st_new_table() {
	symbol_table* st = malloc(sizeof(symbol_table));
	st->size = INITIAL_SIZE;
	st->count = 0;
	st->ids = calloc((size_t) st->size, sizeof(identifier*));
	return st;
}

void st_del_table(symbol_table* st) {
	int i;
	for (i = 0; i < st->size; i++) {
		identifier* id = st->ids[i];
		if (id != NULL) {
			st_del_id(id);
		}
	}
	free(st->ids);
	free(st);
}

void st_delete(symbol_table* st, const char* key) {
	int index = st_get_hash(key, st->size, 0);
	identifier* id = st->ids[index];
	int i = 1;
	while (id != NULL) {
		if (id != &ST_DELETED_ITEM) {
			if (strcmp(id->key, key) == 0) {
				st_del_id(id);
				st->ids[index] = &ST_DELETED_ITEM;
			}
		}
		index = st_get_hash(key, st->size, i);
		id = st->ids[index];
		i++;
	}
	st->count--;
}

void st_insert(symbol_table* st, const char* key, int* val) {
	identifier* id = st_new_id(key, val);
	int index = st_get_hash(id->key, st->size, 0);
	identifier* current_id = st->ids[index];
	int i = 1;
	while (current_id != NULL) {
		if (current_id != &ST_DELETED_ITEM) {
			if (strcmp(current_id->key, key) == 0) {
				st_del_id(current_id);
				st->ids[index] = id;
				return;
			}
		}
		index = st_get_hash(id->key, st->size, i);
		current_id = st->ids[index];
		i++;
	}
	//printf("insert hash: %d\n", index);
	st->ids[index] = id;
	//if (st->ids[index] != NULL) printf("key inserted\n");
	st->count++;
}

int* st_search(symbol_table* st, const char* key) {
	int index = st_get_hash(key, st->size, 0);
	identifier* id = st->ids[index];
	//printf("search hash: %d\n", index);
	int i = 1;
	while (id != NULL) {
		if (id != &ST_DELETED_ITEM) {
			if (strcmp(id->key, key) == 0) {
				//printf("search success, result: %d\n", id->val);
				return &(id->val);
			}
		}
		index = st_get_hash(key, st->size, i);
		id = st->ids[index];
		i++;
	}
	//printf("search failed\n");
	return NULL;
}

// int main() {
// 	symbol_table* st = st_new_table();
// 	char* p = "Apple";
// 	int num = 8;
// 	//identifier* id = st_new_id(p, &num);
// 	st_insert(st, "Apple", &num);
// 	int* result = st_search(st, p);
// 	if (result != NULL)
// 		printf("Result: %d\n", result);
// 	st_del_table(st);
// 	return 0;
// }
