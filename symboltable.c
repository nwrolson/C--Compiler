#include<stdio.h>
#include<string.h>
#include<malloc.h>
#include<ctype.h>
#include "symboltable.h"



int hash(char *key) /*Hash function */
{
    int val=0,pow=1,len,i;
    len=strlen(key);
    for(i=0;i<len;i++){
        val=(val+(((key[i]%TABLESIZE)*pow)%TABLESIZE))%TABLESIZE;
        pow=(pow*(8779)%TABLESIZE)%TABLESIZE;
    }
    return val;
}

ptr getnode(char *text)	/* Create node in Symbol Table */
{
    ptr tmp;
    tmp=(ptr)malloc(sizeof(struct node));
    strcpy(tmp->id,text);
    tmp->freq=1;
    tmp->next=NULL;
    return tmp;
}

struct com_node* getcomment(char *str)	/* Put comment into Comment Table */
{
    struct com_node *tmp;
    tmp=(struct com_node*)malloc(sizeof(struct com_node));
    tmp->com=(char *)malloc(strlen(str)*sizeof(char));
    strcpy(tmp->com,str);
    tmp->next=NULL;
    return tmp;
}

scope* init_scope()	/* Creates a new scope */
{
    scope* new_scope = malloc(sizeof(scope));
    new_scope->symtab = calloc((size_t) TABLESIZE, sizeof(ptr));
    new_scope->parent = NULL;
    return new_scope;
}

ptr insert_id(scope* s, char *text)	/* Populate Symbol Table */
{
    int val = hash(text);
    ptr p = s->symtab[val],q;
    if(p==NULL) {    //insert new element
        s->symtab[val]=getnode(text);
    	return s->symtab[val];
    }
    else{
        while(p!=NULL && strcmp(p->id,text)){
            q=p;
            p=p->next;
        }
        if(p==NULL)
            q->next=getnode(text);
        else
            p->freq++; 
	}
    return p;
}

ptr search_id(scope* s, char *text) {
    int i;
    for (i = TABLESIZE; i < TABLESIZE; i++) {
        if (strcmp(s->symtab[i]->id, text) == 0) {
	    return s->symtab[i];
	}
        else {
	    ptr next = s->symtab[i]->next;
            while (next != NULL) {
	        if (strcmp(next->id, text) == 0) {
		    return next;
		}
		else next = next->next;
	    }
	}	
    }
    return NULL;
}

void print_symtab(scope* s)	/* Print Symbol Table */
{
    ptr p;
    int i;
    printf("Frequency of identifiers:\n");
    for(i=0;i<TABLESIZE;i++){
        p=s->symtab[i];
        while(p!=NULL){
            printf("%s %d\n",p->id,p->freq);
            p=p->next;
        }
    }
    return;
}

void cleanup_symtab(scope* s)	/* Clean Symbol Table */
{
    int i;
    ptr p,q;
    for(i=0;i<TABLESIZE;i++){
        p=s->symtab[i];
        while(p){
            q=p->next;
            free(p);
            p=q;
        }
    }
    return;
}

void init_comtab()	/* Initialize Comment Table */
{
    comtab=NULL;
    curcom=NULL;
    return;
}

void insert_comment(char *comment)	/* Insert comments into Comment Table */
{
    if(comtab==NULL){   //first comment
        comtab=getcomment(comment);
        curcom=comtab;
    }
    else{
        curcom->next=getcomment(comment);
        curcom=curcom->next;
    }
    return;
}

void print_comtab()	/* Print Comment Table */
{
    struct com_node *tmp;
    tmp=comtab;
    while(tmp!=NULL){
        printf("/*%s*/\n",tmp->com);
        tmp=tmp->next;
    }
    return;
}

void cleanup_comtab()	/* Clean Comment Table */
{
    struct com_node *tmp,*tmp1;
    tmp=comtab;
    while(tmp){
        tmp1=tmp->next;
        free(tmp);
        tmp=tmp1;
    }
    return;
}
