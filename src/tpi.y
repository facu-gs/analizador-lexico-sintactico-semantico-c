/*TP I*/

%{
    #include <stdio.h>
    #include "tpiAux.c"

    #define YYDEBUG 1

    extern FILE *yyin;
    extern int yylineno;

    // Esta función es necesaria por si hay un overflow de la memoria
    void yyerror(const char *str){
        fprintf(stderr,"Error sintactico: %s en la linea %d\n", str, yylineno);
    }

    int yylex();

    int yywrap(){
        return(1);
    }
%}

%define parse.error custom
%locations

%code requires {
    #include "tipos.h"
}

%union {
    struct data{
        yylval_string_t estructuraCadena;
        int entero;
        float real;
        typeNode_t * tipo;
        char es_funcion;
        char es_modificable;
        char es_empty;
        int longitud_array;
    } data;
}

%code {
    reportNode_t * reporteDeSentencias = NULL;
    mainNode_t * identificadores = NULL;
    labelNode_t * etiquetas = NULL;
    errorNode_t * erroresSintacticos = NULL;
    errorNode_t * erroresSemanticos = NULL;
}

%code requires {
    #define YYLTYPE YYLTYPE
    typedef struct YYLTYPE {
        int first_line;
        int first_column;
        int last_line;
        int last_column;
        char *filename;
    } YYLTYPE;
}


%start unidadDeTraduccion

%token <data> DEC
%token <data> OCT
%token <data> HEX
%token <data> ID
%token <data> STR
%token <data> REAL
%token <data> DTKW
%token IFKW
%token OTKW
%token <data> DTMKW
%token EQOP
%token RELOP
%token ANDOP
%token OROP
%token INCOP
%token <data> CHR
%token SIZEOP
%token ELSEKW
%token WHILEKW
%token FORKW
%token DOKW
%token RETKW
%token BREAKKW
%token CONTINUEKW
%token DEFAULTKW
%token CASEKW
%token SWITCHKW

// Le damos precedencia al else
%precedence "THEN"
%precedence ELSEKW

%% /* Reglas y acciones */

unidadDeTraduccion 
    : declaracionExterna 
    | unidadDeTraduccion declaracionExterna 
    | error { yyerrok; yyclearin; }
    ;

declaracionExterna
    : definicionDeFuncion 
    | especificadorDeDeclaracion empiezaConTipoDeDato {
        if($<data>2.es_funcion){
            mainNode_t *nodoPrevio = searchSymbol(identificadores, $<data>2.estructuraCadena.cadena);
            if(nodoPrevio != NULL) {
                char * error = malloc(strlen("Doble declaracion del identificador []. Primera vez declarado en linea [].") + strlen($<data>2.estructuraCadena.cadena) + largoNumero(nodoPrevio -> declarationLine) + 1);
                if (error == NULL) {
                    printf("No hay memoria suficiente.");
                    exit(1);
                }
                sprintf(error, "Doble declaracion del identificador [%s]. Primera vez declarado en linea [%d].", $<data>2.estructuraCadena.cadena, nodoPrevio -> declarationLine);
                addWithoutDuplicates(&erroresSemanticos, error, @2.first_line, @1.first_column);
            } else {
                mainNode_t * nuevoNodo = appendSymbol(&identificadores, makeCopy($<data>2.estructuraCadena.cadena),  $<data>1.tipo, 1, 0, @2.first_line);
                nuevoNodo->type->referenceLevel = $<data>2.entero;
                nuevoNodo->type->arraySize = $<data>2.longitud_array;
                if($<data>2.longitud_array != -1){
                    nuevoNodo->type->referenceLevel++;
                }
                nuevoNodo->type->next = $<data>2.tipo;
            }
        } else {
            mainNode_t *nodoPrevio = searchSymbol(identificadores, $<data>2.estructuraCadena.cadena);
            if(nodoPrevio != NULL) {
                char * error = malloc(strlen("Doble declaracion del identificador []. Primera vez declarado en linea [].") + strlen($<data>2.estructuraCadena.cadena) + largoNumero(nodoPrevio -> declarationLine) + 1);
                if (error == NULL) {
                    printf("No hay memoria suficiente.");
                    exit(1);
                }
                sprintf(error, "Doble declaracion del identificador [%s]. Primera vez declarado en linea [%d].", $<data>2.estructuraCadena.cadena, nodoPrevio -> declarationLine);
                addWithoutDuplicates(&erroresSemanticos, error, @2.first_line, @1.first_column);
            } else {
                mainNode_t * nuevoNodo = appendSymbol(&identificadores, makeCopy($<data>2.estructuraCadena.cadena),  $<data>1.tipo, 0, $<data>1.es_modificable, @2.first_line); 
                nuevoNodo->type->referenceLevel = $<data>2.entero;
                nuevoNodo->type->arraySize = $<data>2.longitud_array;
                if($<data>2.longitud_array != -1){
                    nuevoNodo->type->referenceLevel++;
                }
            }
        }
    }
    ;


empiezaConTipoDeDato
    : definicionDeFuncion { $<data>$.es_funcion = 1; $<data>$.entero = $<data>1.entero; $<data>$.longitud_array = $<data>1.longitud_array; strcpy($<data>$.estructuraCadena.cadena, $<data>1.estructuraCadena.cadena); $<data>$.tipo = $<data>1.tipo; }
    | declaracionAux { $<data>$.es_funcion = 0; $<data>$.entero = $<data>1.entero; $<data>$.longitud_array = $<data>1.longitud_array; strcpy($<data>$.estructuraCadena.cadena, $<data>1.estructuraCadena.cadena); $<data>$.tipo = NULL; }
    ;


definicionDeFuncion
    : declarador listaDeDeclaracionOpcional sentenciaCompuesta { 
            strcpy($<data>$.estructuraCadena.cadena, $<data>1.estructuraCadena.cadena); 
            $<data>$.entero = $<data>1.entero;
            $<data>$.longitud_array = $<data>1.longitud_array;
            if($<data>2.es_empty){
                $<data>$.tipo = $<data>1.tipo;
            }else{
                $<data>$.tipo = $<data>2.tipo;
            }
        }
    ;


listaDeDeclaracionOpcional
    : listaDeDeclaracion {$<data>$.es_empty = 0;}
    | %empty { $<data>$.es_empty = 1;}
    ;


declaracion
    : especificadorDeDeclaracion declaracionAux { 
        mainNode_t *nodoPrevio = searchSymbol(identificadores, $<data>2.estructuraCadena.cadena);
        if(nodoPrevio != NULL) {
            char * error = malloc(strlen("Doble declaracion del identificador []. Primera vez declarado en linea [].") + strlen($<data>2.estructuraCadena.cadena) + largoNumero(nodoPrevio -> declarationLine) + 1);
            if (error == NULL) {
                printf("No hay memoria suficiente.");
                exit(1);
            }
            sprintf(error, "Doble declaracion del identificador [%s]. Primera vez declarado en linea [%d].", $<data>2.estructuraCadena.cadena, nodoPrevio -> declarationLine);
            addWithoutDuplicates(&erroresSemanticos, error, @2.first_line, @1.first_column);
        } else {
            mainNode_t * nuevoNodo = appendSymbol(&identificadores, makeCopy($<data>2.estructuraCadena.cadena), $<data>1.tipo, 0, $<data>1.es_modificable, @2.first_line); 
            nuevoNodo->type->referenceLevel = $<data>2.entero;
            nuevoNodo->type->arraySize = $<data>2.longitud_array;
            if(nuevoNodo->type->arraySize != -1){
                nuevoNodo->type->referenceLevel ++;
            }

            $<data>$.tipo = makeTypeNodeCopy($<data>1.tipo);
            $<data>$.tipo->referenceLevel = $<data>2.entero;
            $<data>$.tipo->arraySize = $<data>2.longitud_array;
            if($<data>$.tipo->arraySize != -1){
                $<data>$.tipo->referenceLevel++;
            }
        }            
    }
    ;


declaracionAux
    : inicializacionOpcional ';' { strcpy($<data>$.estructuraCadena.cadena, $<data>1.estructuraCadena.cadena); $<data>$.entero = $<data>1.entero; $<data>$.longitud_array = $<data>1.longitud_array; }
    | error ';'
    ; 


inicializacionOpcional
    : inicializadorDeDeclaracion { strcpy($<data>$.estructuraCadena.cadena, $<data>1.estructuraCadena.cadena); $<data>$.entero = $<data>1.entero; $<data>$.longitud_array = $<data>1.longitud_array; }
    | %empty {$<data>$.estructuraCadena.cadena[0] = '\0'; $<data>$.entero = 0; $<data>$.longitud_array = -1; }
    ;


listaDeDeclaracion
    : declaracion { $<data>$.tipo = $<data>1.tipo; } 
    | declaracion listaDeDeclaracion { $<data>$.tipo = $<data>1.tipo; $<data>1.tipo->next = $<data>2.tipo; }
    ;


especificadorDeDeclaracion
    : modificadorTipoDatoOpcional DTKW { $<data>$.tipo = $<data>2.tipo; $<data>$.tipo->modifiers = makeCopy($<data>1.estructuraCadena.cadena); $<data>$.es_modificable = $<data>1.es_modificable && $<data>2.es_modificable; }
    ;


modificadorTipoDatoOpcional
    : modificadorTipoDato { strcpy($<data>$.estructuraCadena.cadena, $<data>1.estructuraCadena.cadena); $<data>$.es_modificable = $<data>1.es_modificable; }
    | %empty { $<data>$.estructuraCadena.cadena[0] = '\0'; $<data>$.es_modificable = 1; }
    ;


modificadorTipoDato 
    : DTMKW { $<data>$.es_modificable = $<data>1.es_modificable; $<data>$.estructuraCadena.cadena[0] = '\0'; strcpy($<data>$.estructuraCadena.cadena, $<data>1.estructuraCadena.cadena); }
    | modificadorTipoDato DTMKW { $<data>$.es_modificable = $<data>1.es_modificable && $<data>2.es_modificable; $<data>$.estructuraCadena.cadena[0] = '\0'; sprintf($<data>$.estructuraCadena.cadena, "%s %s",$<data>1.estructuraCadena.cadena, $<data>2.estructuraCadena.cadena);}
    ;


inicializadorDeDeclaracion
    : declarador segmentoDeInicializacion { 
            strcpy($<data>$.estructuraCadena.cadena, $<data>1.estructuraCadena.cadena); 
            $<data>$.entero = $<data>1.entero; 
            if($<data>1.longitud_array == 0){
                $<data>$.longitud_array = $<data>2.entero;
            }else{
                $<data>$.longitud_array = $<data>1.longitud_array;
            }
        }
    ;


segmentoDeInicializacion
    : '=' inicializador { $<data>$.entero = $<data>2.entero; }
    | %empty { $<data>$.entero = 0; }
    ;


declarador
    : punteroOpcional declaradorPropio { strcpy($<data>$.estructuraCadena.cadena, $<data>2.estructuraCadena.cadena); $<data>$.tipo = $<data>2.tipo; $<data>$.entero = $<data>1.entero; $<data>$.longitud_array = $<data>2.entero; } 
    ;


punteroOpcional
    : puntero { $<data>$.entero = $<data>1.entero; }
    | %empty { $<data>$.entero = 0; }
    ;


declaradorPropio
    : ID { strcpy($<data>$.estructuraCadena.cadena, $<data>1.estructuraCadena.cadena); $<data>$.tipo = NULL; $<data>$.entero = -1; }
    | '(' declarador ')' 
    | declaradorPropio '(' opcionesDeParentesis ')' { strcpy($<data>$.estructuraCadena.cadena, $<data>1.estructuraCadena.cadena); $<data>$.tipo = $<data>3.tipo; $<data>$.entero = -1; }
    | declaradorPropio '[' expresionConstante ']' { strcpy($<data>$.estructuraCadena.cadena, $<data>1.estructuraCadena.cadena); $<data>$.tipo = NULL; $<data>$.entero = $<data>3.entero; }
    ;


opcionesDeParentesis
    : listaDeTiposDeParametros { $<data>$.tipo = $<data>1.tipo; }
    | listaDeIdentificadores { $<data>$.tipo = NULL; }
    | %empty { $<data>$.tipo = NULL; }
    ;


puntero
    : '*' punteros { $<data>$.entero = $<data>2.entero + 1; }
    ;


punteros
    : puntero { $<data>$.entero = $<data>1.entero; }
    | %empty { $<data>$.entero = 0; }
    ;


listaDeTiposDeParametros
    : listaDeParametros { $<data>$.tipo = $<data>1.tipo; }
    ;

listaDeParametros
    : declaracionDeParametro { $<data>$.tipo = $<data>1.tipo; }
    | declaracionDeParametro ',' listaDeParametros { $<data>$.tipo = $<data>1.tipo; $<data>1.tipo->next = $<data>3.tipo; }
    ;


declaracionDeParametro
    : especificadorDeDeclaracion declarador  { 
        mainNode_t *nodoPrevio = searchSymbol(identificadores, $<data>2.estructuraCadena.cadena);
        if(nodoPrevio != NULL) {
            char * error = malloc(strlen("Doble declaracion del identificador []. Primera vez declarado en linea [].") + strlen($<data>2.estructuraCadena.cadena) + largoNumero(nodoPrevio -> declarationLine) + 1);
            if (error == NULL) {
                printf("No hay memoria suficiente.");
                exit(1);
            }
            sprintf(error, "Doble declaracion del identificador [%s]. Primera vez declarado en linea [%d].", $<data>2.estructuraCadena.cadena, nodoPrevio -> declarationLine);
            addWithoutDuplicates(&erroresSemanticos, error, @2.first_line, @1.first_column);
        } else {
            $<data>$.tipo = $<data>1.tipo; 
            $<data>$.tipo->referenceLevel = $<data>2.entero; 
            $<data>$.tipo->arraySize = $<data>2.longitud_array;
            if($<data>$.tipo->arraySize != -1){
                $<data>$.tipo->referenceLevel++;
            }
            appendSymbol(&identificadores, makeCopy($<data>2.estructuraCadena.cadena), makeTypeNodeCopy($<data>$.tipo), 0, $<data>1.es_modificable, @1.first_line);
        }
    }
    ;


listaDeIdentificadores
    : ID
    | listaDeIdentificadores ',' ID 
    ;


inicializador
    : expresionDeAsignacion { $<data>$.entero = 0; }
    | '{' listaDeInicializadores '}' { $<data>$.entero = $<data>2.entero; }
    ;


listaDeInicializadores
    : inicializador { $<data>$.entero = 1; }
    | listaDeInicializadores ',' inicializador { $<data>$.entero = $<data>1.entero + 1;}
    ;


sentencia
    : sentenciaDeExpresion { appendReport(&reporteDeSentencias, "Expresion", @1.first_line, @1.first_column); }
    | sentenciaCompuesta 
    | sentenciaDeSeleccion { appendReport(&reporteDeSentencias, "Seleccion", @1.first_line, @1.first_column); }
    | sentenciaDeIteracion { appendReport(&reporteDeSentencias, "Iteracion", @1.first_line, @1.first_column); }
    | sentenciaDeSalto { appendReport(&reporteDeSentencias, "Salto", @1.first_line, @1.first_column); }
    | sentenciaEtiquetada { appendReport(&reporteDeSentencias, "Etiquetada", @1.first_line, @1.first_column); }
    | error
    ;

sentenciaEtiquetada
    : ID ':' sentencia { appendLabel(&etiquetas, makeCopy($<data>1.estructuraCadena.cadena)); }
    | ':' sentencia {  appendError(&erroresSintacticos, "Querido humano programador. Se ha usted olvidado de colocar el identificador de la etiqueta", @1.first_line, @1.first_column); yyerrok; }
    | CASEKW expresionConstanteCase ':' sentencia 
    | DEFAULTKW ':' sentencia
    ;
    


sentenciaDeExpresion
    : expresion';' 
    | ';'
    ;


sentenciaCompuesta
    : '{' listaDeDeclaracionesOpcional listaDeSentenciasOpcional '}' { appendReport(&reporteDeSentencias, "Compuesta", @1.first_line, @1.first_column); }
    ;


listaDeDeclaracionesOpcional
    : listaDeDeclaracion
    | %empty
    ;


listaDeSentenciasOpcional
    : listaDeSentencias
    | %empty
    ;


listaDeSentencias
    : sentencia
    | listaDeSentencias sentencia
    ;


sentenciaDeSeleccion
    : IFKW '(' expresion ')' sentencia %prec "THEN"
    | IFKW '(' expresion ')' sentencia ELSEKW sentencia
    | SWITCHKW '(' expresion ')' sentencia
    ;


sentenciaDeIteracion
    : WHILEKW '(' expresion ')' sentencia
    | DOKW sentencia WHILEKW '(' expresion ')' ';'
    | FORKW '(' expresionOVacio ';' expresionOVacio ';' expresionOVacio ')' sentencia
    ;


expresionOVacio
    : expresion
    | %empty
    ;


sentenciaDeSalto
    : CONTINUEKW ';'
    | BREAKKW ';'
    | RETKW expresionOVacio ';'
    ;


expresion
    : expresionDeAsignacion
    | expresion ',' expresionDeAsignacion
    ;


expresionDeAsignacion
    : expresionCondicional { $<data>$.tipo = $<data>1.tipo; }
    | expresionUnaria '=' expresionDeAsignacion { 
                                                    $<data>$.tipo = $<data>1.tipo; 

                                                    if(!$<data>1.es_modificable){
                                                        addWithoutDuplicates(&erroresSintacticos, "La expresion debe ser un L-Value modificable", @1.first_line, @1.first_column); yyerrok;
                                                    } 
                                                    if($<data>1.tipo == NULL || $<data>3.tipo == NULL){
                                                        addWithoutDuplicates(&erroresSemanticos, "Identificador no declarado", @1.first_line, @1.first_column);
                                                    } else if (!(($<data>1.tipo->type->additionClass == $<data>3.tipo->type->additionClass && $<data>1.tipo->referenceLevel == $<data>3.tipo->referenceLevel == 0) || ($<data>1.tipo->type == $<data>3.tipo->type && $<data>1.tipo->referenceLevel == $<data>3.tipo->referenceLevel))){
                                                        addWithoutDuplicates(&erroresSemanticos, "Asignacion entre tipos de dato no compatibles", @1.first_line, @1.first_column);
                                                    }
                                                }   
    ;



expresionCondicional
    : expresionOr ternarioOpcional { 
                                        $<data>$.entero = $<data>1.entero; 
                                        if($<data>2.es_empty){
                                            $<data>$.tipo = $<data>1.tipo;
                                        }else{
                                            $<data>$.tipo = $<data>2.tipo;
                                        }
                                    }
    ;


ternarioOpcional
    : '?' expresion ':' expresionCondicional {
                                                $<data>$.es_empty = 0;
                                                if(!compararTipos($<data>2.tipo,$<data>4.tipo)){
                                                    printf("Warning: Las alternativas de retorno del operador ternario tienen tipos diferentes. Linea: %d.\n", @1.first_line);
                                                }
                                                $<data>$.tipo = $<data>2.tipo;
                                            }
    | %empty { $<data>$.es_empty = 1; }
    ;


expresionConstante
    : expresionCondicional { 
                                $<data>$.entero = $<data>1.entero;
                                if($<data>1.tipo == NULL || $<data>1.tipo->type->additionClass != 1 || $<data>1.tipo->referenceLevel != 0){
                                    addWithoutDuplicates(&erroresSemanticos, "El valor utilizado en el operador de acceso debe ser un numero entero", @1.first_line, @1.first_column);
                                }
                            }
    | %empty { $<data>$.entero = 0; }
    ;

//A fines prácticos sólo consideramos como posibles argumentos del case constantes numéricas directas. Ignoramos las constantes numéricas resultantes de expresiones aritméticas estáticas.
expresionConstanteCase
    : DEC
    | HEX   
    | CHR
    ;


expresionOr
    : expresionAnd { $<data>$.entero = $<data>1.entero; $<data>$.tipo = $<data>1.tipo; }
    | expresionOr OROP expresionAnd { $<data>$.tipo = $<data>2.tipo; }
    ;


expresionAnd
    : expresionDeIgualdad { $<data>$.entero = $<data>1.entero; $<data>$.tipo = $<data>1.tipo; }
    | expresionAnd ANDOP expresionDeIgualdad { $<data>$.tipo = $<data>2.tipo; }
    ;


expresionDeIgualdad
    : expresionRelacional { $<data>$.entero = $<data>1.entero; $<data>$.tipo = $<data>1.tipo; }
    | expresionDeIgualdad EQOP expresionRelacional { $<data>$.tipo = $<data>2.tipo; }
    ;


expresionRelacional
    : expresionAditiva { $<data>$.entero = $<data>1.entero; $<data>$.tipo = $<data>1.tipo; }
    | expresionRelacional RELOP expresionAditiva { $<data>$.tipo = $<data>2.tipo; }
    ;


expresionAditiva
    : expresionMultiplicativa { $<data>$.entero = $<data>1.entero; $<data>$.tipo = $<data>1.tipo; }
    | expresionAditiva segundoTermino { 
                                        $<data>$.tipo = $<data>1.tipo; 
                                        if($<data>1.tipo != NULL && $<data>2.tipo != NULL && $<data>1.tipo->type->additionClass != $<data>2.tipo->type->additionClass){
                                            addWithoutDuplicates(&erroresSemanticos, "Tipos no compatibles para realizar la operacion suma/resta", @1.first_line, @1.first_column);
                                        }
                                    }
    ;


segundoTermino
    : '+' expresionMultiplicativa { $<data>$.tipo = $<data>2.tipo; }
    | '-' expresionMultiplicativa { $<data>$.tipo = $<data>2.tipo; }
    ;


expresionMultiplicativa
    : expresionUnaria { $<data>$.entero = $<data>1.entero; $<data>$.tipo = $<data>1.tipo; }
    | expresionMultiplicativa segundoFactor { 
                                                $<data>$.tipo = $<data>1.tipo; 
                                                if($<data>2.entero == 3){
                                                    if($<data>1.tipo == NULL){
                                                        addWithoutDuplicates(&erroresSemanticos, "Identificador no declarado", @1.first_line, @1.first_column);
                                                    }else if($<data>1.tipo->type->additionClass != 1 || $<data>1.tipo->referenceLevel != 0){
                                                        addWithoutDuplicates(&erroresSemanticos, "La operacion modulo (%%) solo se puede realizar entre numeros enteros", @1.first_line, @1.first_column);
                                                    }
                                                }
                                            }
    ;


segundoFactor
    : '*' expresionUnaria { $<data>$.entero = 1; }
    | '/' expresionUnaria { $<data>$.entero = 2; }
    | '%' expresionUnaria { 
                            $<data>$.entero = 3; 
                            if($<data>2.tipo == NULL){
                                addWithoutDuplicates(&erroresSemanticos, "Identificador no declarado", @1.first_line, @1.first_column);
                            } else if($<data>2.tipo->type->additionClass != 1 || $<data>2.tipo->referenceLevel != 0){
                                addWithoutDuplicates(&erroresSemanticos, "La operacion modulo (%%) solo se puede realizar entre numeros enteros", @1.first_line, @1.first_column);
                            }
                        }
    ;


expresionUnaria
    : expresionPosfijo { $<data>$.es_modificable = $<data>1.es_modificable; $<data>$.entero = $<data>1.entero; $<data>$.tipo = $<data>1.tipo; }
    | INCOP expresionUnaria {                                 
                                $<data>$.tipo = $<data>2.tipo;
                                $<data>$.es_modificable = $<data>2.es_modificable; 
                                if(!$<data>2.es_modificable){
                                    addWithoutDuplicates(&erroresSemanticos, "No se puede realizar un preincremento sobre un L-Value no modificable", @1.first_line, @1.first_column);
                                }
                            }
    | operadorUnario expresionUnaria { 
                                        $<data>$.es_modificable = $<data>2.es_modificable; 
                                        $<data>$.tipo = $<data>2.tipo;
                                        if($<data>$.tipo != NULL){
                                            switch($<data>1.entero){
                                                case 1:
                                                    $<data>$.tipo->referenceLevel++;
                                                    break;
                                                case 2:
                                                    $<data>$.tipo->referenceLevel--;
                                                    break;
                                                case 5:
                                                    $<data>$.tipo = $<data>1.tipo;
                                                    $<data>$.es_modificable = 0;
                                                    break;
                                            }
                                        }else{
                                            addWithoutDuplicates(&erroresSemanticos, "Identificador no declarado", @1.first_line, @1.first_column);
                                        }
                                    }
    ;


operadorUnario
    : '&' { $<data>$.entero = 1; }
    | '*' { $<data>$.entero = 2; }
    | '+' { $<data>$.entero = 3; }
    | '-' { $<data>$.entero = 4; }
    | '!' { $<data>$.entero = 5; $<data>$.tipo = $<data>1.tipo; }
    ;


expresionPosfijo
    : expresionPrimaria { 
                            $<data>$.es_modificable = $<data>1.es_modificable; 
                            $<data>$.entero = $<data>1.entero;
                            $<data>$.real = $<data>1.real; 
                            $<data>$.tipo = $<data>1.tipo;
                            if ($<data>1.tipo == NULL) {
                                addWithoutDuplicates(&erroresSemanticos, "Identificador no declarado", @1.first_line, @1.first_column);
                            }
                        }
    | expresionPosfijo continuacionExpresionPosfijo { 
                                                        $<data>$.es_modificable = $<data>1.es_modificable; 

                                                        if ($<data>1.tipo != NULL) {
                                                            switch($<data>2.entero) {
                                                                case 1: 
                                                                        $<data>$.tipo = $<data>1.tipo; 
                                                                        $<data>$.tipo->referenceLevel --;
                                                                        if ($<data>$.tipo->referenceLevel < 0) {
                                                                            addWithoutDuplicates(&erroresSemanticos, "Operador de acceso utilizado en tipo de dato no puntero", @1.first_line, @1.first_column);
                                                                        } else if ($<data>$.tipo -> arraySize == -1 || $<data>$.tipo -> arraySize == 0) {
                                                                            printf("Warning: Operador de acceso utilizado en identificador de tamaño desconocido, linea %d.\n", @1.first_line);
                                                                        }
                                                                        break;
                                                                case 2:
                                                                    if(!compararTipos($<data>1.tipo->next, $<data>2.tipo)){
                                                                        addWithoutDuplicates(&erroresSemanticos, "Los argumentos utilizados para invocar a la funcion no coinciden en cantidad y/o tipo", @1.first_line, @1.first_column);
                                                                    }
                                                                    $<data>$.tipo = makeTypeNodeCopy($<data>1.tipo);
                                                                    $<data>$.tipo->next = NULL;
                                                                    break;
                                                                case 3:
                                                                    $<data>$.tipo = $<data>2.tipo;
                                                                    break;
                                                                case 4:
                                                                    if(!$<data>1.es_modificable) 
                                                                        addWithoutDuplicates(&erroresSintacticos, "La expresion debe ser un L-Value modificable", @1.first_line, @1.first_column); yyerrok;
                                                                    break;
                                                            }
                                                        }
                                                    }
    ;


continuacionExpresionPosfijo
    : '[' expresion ']' { $<data>$.entero = 1; }
    | '(' listaDeArgumentosOp ')' { $<data>$.entero = 2; $<data>$.tipo = $<data>2.tipo; }
    | '.' ID { $<data>$.entero = 3; $<data>$.tipo = $<data>2.tipo; }
    | INCOP { $<data>$.entero = 4; }
    ;


listaDeArgumentosOp
    : listaDeArgumentos { $<data>$.tipo = $<data>1.tipo; }
    | %empty { $<data>$.tipo = NULL; }
    ;


expresionPrimaria
    : ID { 
            $<data>$.entero = 0; 
            $<data>$.real = 0; 
            mainNode_t *nodoPrevio = searchSymbol(identificadores, $<data>1.estructuraCadena.cadena);
            if( nodoPrevio != NULL){
                $<data>$.es_modificable = nodoPrevio -> isModifiable;
                $<data>$.tipo = makeTypeNodeCopy(nodoPrevio -> type);
            }else{
                $<data>$.tipo = NULL;
            }
        }
    | DEC { $<data>$.es_modificable = 0; $<data>$.entero = $<data>1.entero; $<data>$.real = 0; $<data>$.tipo = $<data>1.tipo; }
    | HEX { $<data>$.es_modificable = 0; $<data>$.entero = $<data>1.entero; $<data>$.real = 0; $<data>$.tipo = $<data>1.tipo; }
    | OCT { $<data>$.es_modificable = 0; $<data>$.entero = $<data>1.entero; $<data>$.real = 0; $<data>$.tipo = $<data>1.tipo; }
    | CHR { $<data>$.es_modificable = 0; $<data>$.entero = $<data>1.entero; $<data>$.real = 0; $<data>$.tipo = $<data>1.tipo; }
    | REAL { $<data>$.es_modificable = 0; $<data>$.entero = 0;  $<data>$.real = $<data>1.real; $<data>$.tipo = $<data>1.tipo; }
    | STR { $<data>$.es_modificable = 0; $<data>$.entero = 0; $<data>$.real = 0; $<data>$.tipo = $<data>1.tipo; }
    | '(' expresion ')' { $<data>$.es_modificable = 0; $<data>$.entero = 0; $<data>$.real = 0; $<data>$.tipo = $<data>2.tipo; }
    ;


listaDeArgumentos
    : expresionDeAsignacion { $<data>$.tipo = $<data>1.tipo; }
    | expresionDeAsignacion ',' listaDeArgumentos { 
                                                    $<data>$.tipo = $<data>1.tipo; 
                                                    if($<data>$.tipo != NULL)
                                                        $<data>$.tipo->next = $<data>3.tipo; 
                                                }
    ;

%%

int yyreport_syntax_error(const yypcontext_t *ctx) {
    int res = 0;
    char * message = "";

    YYLTYPE location = *yypcontext_location(ctx);

    // Imprime el token inesperado
    yysymbol_kind_t lookahead = yypcontext_token(ctx);
    if (lookahead != YYSYMBOL_YYEMPTY){
        message = appendString(message, yysymbol_name(lookahead));
        message = appendString(message, " inesperado");
    }

    // Imprime los tokens esperados
    enum { TOKENMAX = 10 };
    yysymbol_kind_t expected[TOKENMAX];
    int n = yypcontext_expected_tokens(ctx, expected, TOKENMAX);
    if (n < 0)
        res = n;
    else
        for (int i = 0; i < n; ++i){
            if(i==0){
                message = appendString(message, ": se esperaba ");
            }else{
                message = appendString(message, ": o ");
            }
            message = appendString(message, yysymbol_name(expected[i]));
        }

    addWithoutDuplicates(&erroresSintacticos, message, location.first_line, location.first_column);

    return res;
}

void inicializarUbicacion(void){
    yylloc.first_line = yylloc.last_line = INICIO_CONTEO_LINEA;
    yylloc.first_column = yylloc.last_column = INICIO_CONTEO_COLUMNA;
}

int main(int argc, char const* argv[]){
    inicializarUbicacion();

    #ifdef BISON_DEBUG
        yydebug = 1;
    #endif    
    
    yyin = fopen("entrada.c", "r");


    while(!feof(yyin)){
        yyparse();
    }

    imprimirReporteDeFunciones(identificadores);
    imprimirReporteDeVariables(identificadores);
    imprimirReporteDeSentencias(reporteDeSentencias);
    imprimirReporteDeErrores(erroresSintacticos, "sintacticos");
    imprimirReporteDeErrores(erroresSemanticos, "semanticos");
    return 0;
}