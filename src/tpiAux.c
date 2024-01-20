#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <stdint.h>
#include <math.h>
#include "tpiAux.h"


errorNode_t * appendError(errorNode_t ** list, char * message, int line, int column){
    errorNode_t ** lastNodePtr = list;
    while(*lastNodePtr != NULL)        
        lastNodePtr = &((*lastNodePtr)->next);

    errorNode_t * newNode = (errorNode_t *) malloc(sizeof(errorNode_t));
    if (newNode == NULL) {
        printf("No hay memoria suficiente.");
        exit(1);
    }

    newNode->message = message;
    newNode->line = line;
    newNode->column = column;
    newNode->next = NULL;
    *lastNodePtr = newNode;

    return newNode;
}

errorNode_t * searchErrorNode(errorNode_t * errors, char * message, int line, int column){
    errorNode_t * currentNode = errors;
    while(currentNode != NULL && (strcmp(currentNode->message, message) != 0 || currentNode->line != line || currentNode->column != column))
        currentNode = currentNode->next;

    return currentNode;
}

errorNode_t * addWithoutDuplicates(errorNode_t ** list, char * message, int line, int column){
    errorNode_t * preexistentNode = searchErrorNode(*list, message, line, column);
    if(preexistentNode == NULL){
        preexistentNode = appendError(list, message, line, column);
    }
    return preexistentNode;
}

labelNode_t * appendLabel(labelNode_t ** list, char * label){
    labelNode_t ** lastNodePtr = list;
    while(*lastNodePtr != NULL)        
        lastNodePtr = &((*lastNodePtr)->next);

    labelNode_t * newNode = (labelNode_t *) malloc(sizeof(labelNode_t));
    if (newNode == NULL) {
        printf("No hay memoria suficiente.");
        exit(1);
    }
    newNode->label = label;
    newNode->next = NULL;
    *lastNodePtr = newNode;
    return newNode;
} 

labelNode_t * searchLabel(labelNode_t * list, char * label){
    labelNode_t * currentNode = list;    
    while(currentNode != NULL && strcmp(currentNode->label, label) != 0)
        currentNode = currentNode->next;

    return currentNode;
}

mainNode_t * appendSymbol(mainNode_t ** list, char * identifier, typeNode_t * type, bool isFunction, bool isModifiable, int declarationLine){

    mainNode_t ** lastNodePtr = list;
    while(*lastNodePtr != NULL)        
        lastNodePtr = &((*lastNodePtr)->next);

    mainNode_t * newNode = (mainNode_t *) malloc(sizeof(mainNode_t));
    if (newNode == NULL) {
        printf("No hay memoria suficiente.");
        exit(1);
    }
    newNode->identifier = identifier;
    newNode->type = type;
    newNode->isFunction = isFunction;
    newNode->isModifiable = isModifiable;
    newNode->declarationLine = declarationLine;
    newNode->next = NULL;
    *lastNodePtr = newNode;
    return newNode;
}

void pushSymbol(mainNode_t ** list, char * identifier, typeNode_t * type, bool isFunction, bool isModifiable, int declarationLine){
    mainNode_t * newNode = (mainNode_t *) malloc(sizeof(mainNode_t));
    if (newNode == NULL) {
        printf("No hay memoria suficiente.");
        exit(1);
    }
    newNode->identifier = identifier;
    newNode->type = type;
    newNode->isFunction = isFunction;
    newNode->isModifiable = isModifiable;
    newNode->declarationLine = declarationLine;
    newNode->next = *list;
    *list = newNode;
}

void frontBackSplitSymbols(mainNode_t * source, mainNode_t ** frontRef, mainNode_t ** backRef){
    mainNode_t * fast;
    mainNode_t * slow;
    slow = source;
    fast = source->next;

    while (fast != NULL){
        fast = fast->next;
        if (fast != NULL){
            slow = slow->next;
            fast = fast->next;
        }
    }
    *frontRef = source;
    *backRef = slow->next;
    slow->next = NULL;
}

mainNode_t * sortedMergeSymbols(mainNode_t * a, mainNode_t * b, int sortCriteria(mainNode_t *, mainNode_t *)){
    mainNode_t * result = NULL;

    if (a == NULL){
        return b;
    } else if (b == NULL){
        return a;
    }

    if(sortCriteria(a,b)){
        result = a;
        result->next = sortedMergeSymbols(a->next, b, sortCriteria);
    }else{
        result = b;
        result->next = sortedMergeSymbols(a, b->next, sortCriteria);
    }
}

void sortSymbols(mainNode_t ** list, int sortCriteria(mainNode_t *, mainNode_t *)){
    mainNode_t * head = *list;
    mainNode_t * a;
    mainNode_t * b;

    if (head == NULL || head->next == NULL){
        return;
    }

    frontBackSplitSymbols(head, &a, &b);

    sortSymbols(&a, sortCriteria);
    sortSymbols(&b, sortCriteria);
    
    head = sortedMergeSymbols(a, b, sortCriteria);
}

mainNode_t * searchSymbol(mainNode_t * list, char * value){
    mainNode_t * currentNode = list;    
    while(currentNode != NULL && strcmp(currentNode->identifier, value) != 0)
        currentNode = currentNode->next;

    return currentNode;
}

void insertOrderedSymbol(mainNode_t **list, char * identifier, typeNode_t * type, bool isFunction, bool isModifiable, int declarationLine, int sortCriteria(mainNode_t *, mainNode_t *)){
    mainNode_t ** prevPointer = list;

    mainNode_t * newNode = (mainNode_t *) malloc(sizeof(mainNode_t));
    if (newNode == NULL) {
        printf("No hay memoria suficiente.");
        exit(1);
    }

    newNode->identifier = identifier;
    newNode->type = type;
    newNode->isFunction = isFunction;
    newNode->isModifiable = isModifiable;
    newNode->declarationLine = declarationLine;
    
    while (*prevPointer != NULL && sortCriteria(*prevPointer, newNode)){
        prevPointer = &(*prevPointer)->next;
    }

    newNode->next = *prevPointer;
    *prevPointer = newNode;
}

void listByCriteria(mainNode_t *list, bool criteria(mainNode_t *), void callback(mainNode_t *)){
    mainNode_t * currentNode = list; 
    while(currentNode != NULL){
        if(criteria(currentNode)){
            callback(currentNode);
        }
        currentNode = currentNode->next;
    }
}

void appendType(typeNode_t ** list, dataType_t * type, uint8_t referenceLevel){

    typeNode_t ** lastNodePtr = list;
    while(*lastNodePtr != NULL)        
        lastNodePtr = &((*lastNodePtr)->next);

    typeNode_t * newNode = (typeNode_t *) malloc(sizeof(typeNode_t));
    if (newNode == NULL) {
        printf("No hay memoria suficiente.");
        exit(1);
    }
    newNode->type = type;
    newNode->referenceLevel = referenceLevel;
    newNode->next = NULL;
    *lastNodePtr = newNode;
}

int typeLength(typeNode_t * list){
    if(list == NULL){
        return 0;
    }
    return 1 + typeLength(list->next);
}

bool alphabeticAscIdentifierCriteria(mainNode_t * a, mainNode_t * b){
    return strcmp(a->identifier, b->identifier) > 0;           
}

bool listFunctionsCriteria(mainNode_t * node){
    return node->isFunction;
}

bool listVariablesCriteria(mainNode_t * node){
    return !node->isFunction;
}

bool listAllCriteria(errorNode_t * node){
    return true;
}

void errorsReportCallback(errorNode_t * node){
    printf("%20s | %30d | %d\n",node->message,node->line,node->column);
}

void variablesReportCallback(mainNode_t * node){
    char * typeString;
    if(!node->isFunction){
        int espacioParaArray = node->type->arraySize == -1 ? 0 : node->type->arraySize == 0 ? 2 : largoNumero(node->type->arraySize);
        typeString = malloc(strlen(node->type->type->humanName)+node->type->referenceLevel+strlen(node->type->modifiers)+espacioParaArray+2);
        if (typeString == NULL) {
            printf("No hay memoria suficiente.");
            exit(1);
        }
        if(node->type->arraySize == -1){
            sprintf(typeString, "%s%s %s", repeat('*', node->type->referenceLevel), node->type->modifiers, node->type->type->humanName);
        }else if(node->type->arraySize == 0){
            sprintf(typeString, "%s%s %s[]", repeat('*', node->type->referenceLevel-1), node->type->modifiers, node->type->type->humanName);
        }else{
            sprintf(typeString, "%s%s %s[%d]", repeat('*', node->type->referenceLevel-1), node->type->modifiers, node->type->type->humanName, node->type->arraySize);
        }
    }else if(typeLength(node->type) == 1){
        typeString = malloc(strlen(node->type->modifiers)+strlen(node->type->type->humanName)+node->type->referenceLevel+14);
        if (typeString == NULL) {
            printf("No hay memoria suficiente.");
            exit(1);
        }
        sprintf(typeString,"(VOID) -> (%s%s %s)", repeat('*', node->type->referenceLevel), node->type->modifiers, node->type->type->humanName);
    }else{
        typeString = "\0";
        typeNode_t * currentNode = node->type->next;
        while(currentNode != NULL){
            int spaceReservedForSeparator = 0;
            if(strlen(typeString) > 1){
                spaceReservedForSeparator = 2;
            }

            int espacioParaArray = currentNode->arraySize == -1 ? 0 : currentNode->arraySize == 0 ? 2 : largoNumero(node->type->arraySize);

            char * auxString = malloc(strlen(typeString)+strlen(currentNode->modifiers)+currentNode->referenceLevel+1+strlen(currentNode->type->humanName)+spaceReservedForSeparator+espacioParaArray+1);
            if (auxString == NULL) {
                printf("No hay memoria suficiente.");
                exit(1);
            }

            auxString[0] = 0;
            strcat(auxString,typeString);
            if(strlen(typeString) > 1){
                strcat(auxString,", ");
            }
            strcat(auxString, repeat('*', currentNode->referenceLevel));
            strcat(auxString, currentNode->modifiers);
            strcat(auxString, " ");
            strcat(auxString, currentNode->type->humanName);
            if(currentNode->arraySize == 0){
                strcat(auxString, "[]");
            }else if(currentNode->arraySize > 0){
                char * auxString2 = malloc(espacioParaArray+1);
                if (auxString2 == NULL) {
                    printf("No hay memoria suficiente.");
                    exit(1);
                }
                auxString2[0] = '\0';
                sprintf(auxString2, "[%d]", currentNode->arraySize);
                strcat(auxString, auxString2);
            }
            typeString = auxString;

            currentNode = currentNode->next;
        }

        char * typeStringAux = malloc(strlen(typeString)+strlen(node->type->modifiers)+node->type->referenceLevel+strlen(node->type->type->humanName)+10);
        if (typeStringAux == NULL) {
            printf("No hay memoria suficiente.");
            exit(1);
        }
        
        sprintf(typeStringAux,"(%s) -> (%s %s%s)", typeString, node->type->modifiers, repeat('*', node->type->referenceLevel), node->type->type->humanName);
        typeString = typeStringAux;
    }
    printf("%20s | %30s | %d\n",node->identifier,typeString,node->declarationLine);
}

void appendReport(reportNode_t ** list, char * estructura, int numeroLinea, int numeroColumna){
    reportNode_t ** lastNodePtr = list;
    while(*lastNodePtr != NULL)        
        lastNodePtr = &((*lastNodePtr)->next);

    reportNode_t * newNode = (reportNode_t *) malloc(sizeof(reportNode_t));
    if (newNode == NULL) {
        printf("No hay memoria suficiente.");
        exit(1);
    }
    newNode->estructura = estructura;
    newNode->numeroLinea = numeroLinea;
    newNode->numeroColumna = numeroColumna;
    newNode->next = NULL;
    *lastNodePtr = newNode;
}

void imprimirReporteDeFunciones(mainNode_t *list) {
    printf("\nFunciones:\n");
    printf("%20s | %30s | %s\n", "Identificador", "Tipo", "Numero de linea");
    listByCriteria(list, listFunctionsCriteria, variablesReportCallback);
    printf("\n");
}

void imprimirReporteDeVariables(mainNode_t *list) {
    printf("\nVariables:\n");
    printf("%20s | %30s | %s\n", "Identificador", "Tipo", "Numero de linea");
    listByCriteria(list, listVariablesCriteria, variablesReportCallback);
    printf("\n");
}

void imprimirReporteDeSentencias(reportNode_t *list) {
    printf("%18s | %7s : %s\n", "Tipo de sentencia", "Linea", "Columna");
    if (list == NULL) {
        printf(" No hay sentencias para mostrar.\n");
    }else {
        reportNode_t * currentNode = list;

        while(currentNode != NULL){
            printf("%18s | %7d : %d\n", currentNode->estructura, currentNode->numeroLinea, currentNode->numeroColumna);
            currentNode = currentNode -> next;
        }
    }
}

void imprimirReporteDeErrores(errorNode_t *list, char * tipoError) {
    printf("\nErrores %s:\n",tipoError);
    errorNode_t * currentNode = list;
    if(currentNode == NULL){
        printf("-----------No se detectaron errores-----------\n");
    }else{
        printf("%100s | %7s : %s\n", "Tipo de sentencia", "Linea", "Columna");
    }
    while(currentNode != NULL){
        printf("%100s | %7d : %d\n", currentNode->message, currentNode->line, currentNode->column);
        currentNode = currentNode->next;
    }
    printf("\n");
}

char * appendString(char * str1, char * str2){
    char * new = malloc(strlen(str1)+strlen(str2)+1);
    if(new == NULL){
        printf("No hay memoria suficiente.");
        exit(1);
    }
    *new = 0;
    strcat(new,str1);
    strcat(new,str2);
    return new;
}

char * makeCopy(char * str){
    char * new = malloc(strlen(str)+1);
    if(new == NULL){
        printf("No hay memoria suficiente.");
        exit(1);
    }
    strcpy(new, str);
    return new;
}

void typeNodeCopy(typeNode_t * destination, typeNode_t * source){
    destination->modifiers = source->modifiers;
    destination->type = source->type;
    destination->referenceLevel = source->referenceLevel;
    destination->arraySize = source->arraySize;
    destination->next = source->next;
}

typeNode_t * makeTypeNodeCopy(typeNode_t * source){
    typeNode_t * newNode = (typeNode_t *) malloc(sizeof(typeNode_t));
    if (newNode == NULL) {
        printf("No hay memoria suficiente.");
        exit(1);
    }
    newNode->type = source->type;
    newNode->modifiers = source->modifiers;
    newNode->referenceLevel = source->referenceLevel;
    newNode->arraySize = source->arraySize;
    newNode->next = source->next;
    return newNode;
}

char * repeat (char c , int count){
    char * string = malloc(count+1);

    if (string == NULL) {
        printf("No hay memoria suficiente.");
        exit(1);
    }

    for (int i = 0; i < count; i++){
        string[i] = c;
    }

    string[count] = '\0';

    return string;
}

bool compararTipos(typeNode_t * t1, typeNode_t * t2){
    typeNode_t * currentNodeT1 = t1;
    typeNode_t * currentNodeT2 = t2;

    while(currentNodeT1 != NULL && currentNodeT2 != NULL){
        if(currentNodeT1->type != currentNodeT2->type || currentNodeT1->referenceLevel != currentNodeT2->referenceLevel){
            return false;
        }
        currentNodeT1 = currentNodeT1->next;
        currentNodeT2 = currentNodeT2->next;
    }
    if(currentNodeT1 != NULL || currentNodeT2 != NULL){
        return false;
    }
    return true;
}

int largoNumero(int numero){
    return ((int) ceil(log10(numero)) + numero % 10 == 0 ? 1 : 0);
}