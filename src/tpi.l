%option noyywrap
%option yylineno

%{

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "tpi.tab.h"

dataType_t CHAR_T = { "char", 1 };
dataType_t INT_T = { "int", 1 };
dataType_t FLOAT_T = { "float", 2 };
dataType_t DOUBLE_T = { "double", 2 };
dataType_t VOID_T = { "void", 0 };

int escapedCharValue(char a){
    switch(a){
        case 'a':
            return '\a';
        case 'b':
            return '\b';
        case 'f':
            return '\f';
        case 'n':
            return '\n';
        case 'r':
            return '\r';
        case 't':
            return '\t';
        case 'v':
            return '\v';
        case '\\':
            return '\\';
        case '\'':
            return '\'';
    }
}

void reinicializarUbicacion(void){
    yylloc.first_line = yylloc.last_line;
    yylloc.first_column = yylloc.last_column;
}

typeNode_t * newTypeNode(dataType_t * type){
    typeNode_t * newNode = (typeNode_t *) malloc(sizeof(typeNode_t));
    if (newNode == NULL) {
        printf("No hay memoria suficiente.");
        exit(1);
    }
    newNode->type = type;
    newNode->referenceLevel = 0;
    newNode->next = NULL;
    newNode->modifiers = NULL;
    newNode->arraySize = 0;

    return newNode;
}

%}

%x tokenNoReconocido

%%
    reinicializarUbicacion();

0[0-7]* { 
            yylloc.last_column += yyleng; 
            yylval.data.entero = (int)strtol(yytext, NULL, 8);
            yylval.data.tipo = newTypeNode(&INT_T);
            return OCT; 
        }

[1-9][0-9]* { 
                yylloc.last_column += yyleng; 
                yylval.data.entero = atoi(yytext);
                yylval.data.tipo = newTypeNode(&INT_T); 
                return DEC; 
            }

0[xX][0-9a-fA-F]+ { 
                    yylloc.last_column += yyleng; 
                    yylval.data.entero = (int)strtol(yytext, NULL, 16); 
                    
                    return HEX; 
                }

[\+\-]?[0-9]+\. { 
                    yylloc.last_column += yyleng; 
                    yylval.data.real = atof(yytext);
                    yylval.data.tipo = newTypeNode(&FLOAT_T); 
                    return REAL; 
                }

[\+\-]?[0-9]*\.[0-9]*([eE][\+\-]?[0-9]+)? { 
                                            yylloc.last_column += yyleng; 
                                            yylval.data.real = atof(yytext);
                                            yylval.data.tipo = newTypeNode(&FLOAT_T); 
                                            return REAL; 
                                        }

int { 
        yylloc.last_column += yyleng; 
        yylval.data.tipo = newTypeNode(&INT_T);
        yylval.data.es_modificable = 1;
        return DTKW; 
    }

char    { 
            yylloc.last_column += yyleng; 
            yylval.data.tipo = newTypeNode(&CHAR_T);
            yylval.data.es_modificable = 1;
            return DTKW; 
        }

float   { 
            yylloc.last_column += yyleng; 
            yylval.data.tipo = newTypeNode(&FLOAT_T);
            yylval.data.es_modificable = 1;
            return DTKW; 
        }

double  { 
            yylloc.last_column += yyleng; 
            yylval.data.tipo = newTypeNode(&DOUBLE_T); 
            yylval.data.es_modificable = 1;
            return DTKW; 
        }

void    { 
            yylloc.last_column += yyleng; 
            yylval.data.tipo = newTypeNode(&VOID_T); 
            yylval.data.es_modificable = 0;
            return DTKW;
        }

long|short|signed|unsigned { 
                                    yylloc.last_column += yyleng; 
                                    strcpy(yylval.data.estructuraCadena.cadena, yytext);
                                    yylval.data.es_modificable = 1;
                                    return DTMKW; 
                                }

const {
    yylloc.last_column += yyleng; 
    strcpy(yylval.data.estructuraCadena.cadena, yytext);
    yylval.data.es_modificable = 0;
    return DTMKW;
}

if { 
        yylloc.last_column += yyleng; 
        return IFKW; 
    } 

else    { 
            yylloc.last_column += yyleng; 
            return ELSEKW; 
        }

while   {
            yylloc.last_column += yyleng; 
            return WHILEKW; 
        }

for { 
        yylloc.last_column += yyleng; 
        return FORKW; 
    }

do  { 
        yylloc.last_column += yyleng; 
        return DOKW; 
    }

return  { 
            yylloc.last_column += yyleng; 
            return RETKW; 
        }

break   { 
            yylloc.last_column += yyleng; 
            return BREAKKW; 
        }

continue    { 
                yylloc.last_column += yyleng; 
                return CONTINUEKW; 
            }

auto   { 
            yylloc.last_column += yyleng; 
            return OTKW; 
        }

switch {
        yylloc.last_column += yyleng; 
        return SWITCHKW;
    }

default {
            yylloc.last_column += yyleng; 
            return DEFAULTKW;
        }

case {
        yylloc.last_column += yyleng; 
        return CASEKW;
    }

enum|extern|goto|register   { 
                                yylloc.last_column += yyleng; 
                                return OTKW; 
                            }

static|struct|typedef|union|volatile    { 
                                            yylloc.last_column += yyleng; 
                                            return OTKW; 
                                        }

sizeof  { 
            yylloc.last_column += yyleng; 
            return SIZEOP; 
        }

\"((\\\")*[^"\n]*)*\"   { 
                            yylloc.last_column += yyleng; 
                            strcpy(yylval.data.estructuraCadena.cadena, yytext);
                            yylval.data.tipo = newTypeNode(&CHAR_T);
                            yylval.data.tipo -> referenceLevel = 1;
                            return STR; 
                        }

[a-zA-Z_][a-zA-Z0-9_]*  { 
                            yylloc.last_column += yyleng; 
                            strcpy(yylval.data.estructuraCadena.cadena, yytext); 
                            return ID; 
                        }

\[|\]|\(|\)|\{|\}|\.|\*|\+|\-|\/|%|=|;|\?|:|,|&   { 
                                                        yylloc.last_column += yyleng; 
                                                        return yytext[0]; 
                                                    }

! { 
    yylloc.last_column += yyleng; 
    yylval.data.tipo = newTypeNode(&INT_T);
    return yytext[0]; 
}

\+\+|\-\-   { 
                yylloc.last_column += yyleng; 
                return INCOP; 
            }

&&  { 
        yylloc.last_column += yyleng; 
        yylval.data.tipo = newTypeNode(&INT_T);
        return ANDOP; 
    }

\|\|    { 
            yylloc.last_column += yyleng; 
            yylval.data.tipo = newTypeNode(&INT_T);
            return OROP; 
        }

\<|\>|\<=|\>=   { 
                    yylloc.last_column += yyleng; 
                    yylval.data.tipo = newTypeNode(&INT_T);
                    return RELOP; 
                }

==|!=   { 
            yylloc.last_column += yyleng; 
            yylval.data.tipo = newTypeNode(&INT_T);
            return EQOP; 
        }

'([^\\'])'  { 
                yylval.data.entero = yytext[1]; 
                return CHR; 
            }

'(\\[abfnrtv\\'])'  { 
                        yylval.data.entero = escapedCharValue(yytext[2]); 
                        return CHR; 
                    }

[ \t]+  { 
            yylloc.first_column = yylloc.last_column += yyleng; 
        }

\n {
        yylloc.first_line = yylloc.last_line += 1;
        yylloc.first_column = yylloc.last_column = INICIO_CONTEO_COLUMNA;
    }


[^ \t\n] { 
            yylloc.last_column += yyleng; 
            fprintf(stderr, "Flex: %d:%d: Error lexico: token no reconocido: %s", yylloc.first_line, yylloc.first_column, yytext); 
            BEGIN(tokenNoReconocido); 
        }
<tokenNoReconocido>{
    " "|\t|\n {
        yyless(0);
        fprintf(stderr, "\n");
        BEGIN(INITIAL);
    }
    [^ \t\n]+ {
        yylloc.last_column += yyleng;
        fprintf(stderr, "%s\n", yytext);
        BEGIN(INITIAL);
    }
}

%%