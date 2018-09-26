%{
#include <stdlib.h>

#include "symbol_table.h"    
#define ID_SIZE 256
%}
    int num_lines = 1;
    int num_tokens = 0;
    int num_comments = 0;
    char comments[1000]="";

    char **id_list;    
    symbol_table* st;

DIGIT       [0-9]
IDENTIFIER  [a-zA-Z_][a-zA-Z0-9_]*
INVLDTOKEN  [0-9][a-zA-Z_]+
%x C_COMMENT
%%
\n { //Lines
    ++num_lines;
}

" " //eating up extra white space

{DIGIT}+ {
    //printf("An integer: %s\n", yytext);
    ++num_tokens;
}

{DIGIT}*"."{DIGIT}+ {
    //printf("A float: %s\n", yytext);
    ++num_tokens;
}

return|typedef|if|else|int|float|for|struct|union|void|while {
    //printf("A keyword: %s\n", yytext);
    ++num_tokens;
}

{IDENTIFIER} {
    char* key = strdup(yytext);
    //printf("Key: %s\n", key);
    int num = 1;
    int* result = st_search(st, key);
    if (result != NULL) {
      num = *result;
      num++;   
    }
    st_insert(st, key, &num);
    ++num_tokens;
}

"+"|"-"|"*"|"/" {
    //printf("An operator: %s\n", yytext );
    ++num_tokens;
}

\"(\\.|[^"\\])*\" {
    //printf ("A string: %s\n", yytext);
    ++num_tokens;
}

"/*" {
    BEGIN(C_COMMENT);
    strcat(comments, "/*");
}

<C_COMMENT>. {        // eat anything that's not a '/n'
    //printf("A comment character: %s\n", yytext);
    strcat(comments, yytext);
}

<C_COMMENT>\n {
    ++num_lines;
    strcat(comments, "\n");
}
<C_COMMENT>"*"+"/" {
    ++num_comments;
    ++num_tokens;
    strcat(comments, "*/\n");
    BEGIN(INITIAL);
}

"{"|"}"|"("|")"|"="|";"|"," {
    //printf ("A misc symbol: %s\n", yytext);
    ++num_tokens;
}

{INVLDTOKEN} {
    printf("An invalid token: %s. Exiting scanner.\n", yytext);
    exit(0);
}

%%

/* qsort C-string comparison function */ 
int cmpstring(const void *a, const void *b) 
{ 
    const char **ia = (const char **)a;
    const char **ib = (const char **)b;
    return strcmp(*ia, *ib);
  /* strcmp functions works exactly as expected from
  comparison function */ 
} 

int main(int argc, char *argv[]) {
    st = st_new_table();

    if (argc > 0)
      yyin = fopen( argv[1], "r");
    else
      yyin = stdin;
    yylex();

    printf("There are %d tokens /* comments are counted as tokens */\nThere are %d lines\nThere are %d comments:\n", num_tokens, num_lines, num_comments);
    printf(comments);

    // copy the contents of the symbol table to an array, and sort it
    printf("Frequency of identifiers:\n");
    char **id_list;
    int i;
    int index = 0;
    id_list = malloc(st->count * sizeof(char*));
    for (i = 0; i < st->count; i++) {
      id_list[i] = malloc((ID_SIZE+1) * sizeof(char));
      while (st->ids[index] == NULL) {
        index++;
      }
      strcpy(id_list[i], st->ids[index]->key);  
      index++;
    }
    qsort(id_list, st->count, sizeof(char *), cmpstring);
    int* val;
    for (i = 0; i < st->count; i++) {
      val = *(st_search(st, id_list[i]));   
      printf("%s %d\n", id_list[i], val); 
    }
}
