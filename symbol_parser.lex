
    int num_lines = 0;
    int num_tokens = 0;

DIGIT       [0-9]
IDENTIFIER  [a-zA-Z_][a-zA-Z0-9_]*
%%
\n      ++num_lines;
{DIGIT}+ {
    printf("An integer: %s\n", yytext);
    ++num_tokens;
}

{DIGIT}+"."{DIGIT}* {
    printf("A float: %s\n", yytext);
    ++num_tokens;
}

{IDENTIFIER} {
    printf("An identifier: %s\n", yytext);
    ++num_tokens;
}

"+"|"-"|"*"|"/" {
    printf("An operator: %s\n", yytext );
    ++num_tokens;
}

\"(\\.|[^"\\])*\" {
    printf ("A string: %s\n", yytext);
    ++num_tokens;
}

"/*"((\*+[^/*])|([^*]))*\**"*/" {
    printf ("A comment: %s\n", yytext);
    ++num_tokens;
}

"{"|"}"|"("|")"|"="|";"|"," {
    printf ("A misc symbol: %s\n", yytext);
    ++num_tokens;
}

%%
main(){
    yylex();
    printf( "# of lines = %d, # of tokens = %d\n",
            num_lines, num_tokens );
}
