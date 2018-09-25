    int num_lines = 1;
    int num_tokens = 0;
    int num_comments = 0;
    char comments[1000]="";

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
    //printf("An identifier: %s\n", yytext);
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
main(){
    yylex();
    printf("There are %d tokens /* comments are counted as tokens */\nThere are %d lines\nThere are %d comments:\n", num_tokens, num_lines, num_comments);
    printf(comments);
}
