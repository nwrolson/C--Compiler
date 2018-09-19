    int num_lines = 1;
    int num_tokens = 0;
    int num_comments = 0;

DIGIT       [0-9]
IDENTIFIER  [a-zA-Z_][a-zA-Z0-9_]*
%x comment
%%
\n { //Lines
    ++num_lines;
}

" " //eating up extra white space

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

"/*" {
    BEGIN(comment);
}

<comment>[^*\n]* {        // eat anything that's not a '*'
    printf("A comment line: %s\n", yytext);
}

<comment>"*"+[^*/\n]* {  // eat up '*'s not followed by '/'s
    printf("A comment line with an asterisk: %s\n", yytext);
}

<comment>\n {
    ++num_lines;
}
<comment>"*"+"/" {
    ++num_comments;
    ++num_tokens;
    BEGIN(INITIAL);
}


"{"|"}"|"("|")"|"="|";"|"," {
    printf ("A misc symbol: %s\n", yytext);
    ++num_tokens;
}

%%
main(){
    yylex();
    printf( "# of lines = %d, # of tokens = %d\n, # of comments = %d\n",
            num_lines, num_tokens, num_comments );
}
