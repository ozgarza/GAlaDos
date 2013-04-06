#include "cuadruplos.h"
#include "utilerias.h"
#include "uthash.h"
#include "codigosOperaciones.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

//Pilas Operandos
pila *operandos;    	//Variables
pila *operadores;   	//Signos

//Pilas Avail
pila *availEntero;		//int = 0
pila *availDecimal;		//int = 1
pila *availTexto;		//int = 2
pila *availBoolean;		//int = 3

//Contador de cuadruplos
int contadorIndice = 0;

//Variables para control
nodoOperando *operando;
nodoOperador *operador;

//Division de la memoria
//****************************
//Temporales
int memoriaEnteroTemp = 10000;
int memoriaDecimalTemp = 11000;
int memoriaTextoTemp = 12000;
int memoriaBooleanoTemp = 13000;

//Locales
int memoriaEnteroLocal = 5000;
int memoriaDecimalLocal = 6000;
int memoriaTextoLocal =	7000;
int memoriaBooleanoLocal = 8000;

//****************************
//Lista de cuadruplos
cuadruplos *listaCuadruplos = NULL;

//cuboSemantico
static int cuboSemantico[4][4][14];

//Esto va en nuestro main
void  generarMultiplicacionDivision(){
	listaCuadruplos = verificacionGeneracionCuadruplo(1 , listaCuadruplos, operandos, operadores, cuboSemantico, &contadorIndice, availEntero, availDecimal, availTexto, availBoolean);
}

void  generarSumaResta(){
	listaCuadruplos = verificacionGeneracionCuadruplo(2 , listaCuadruplos, operandos, operadores, cuboSemantico, &contadorIndice, availEntero, availDecimal, availTexto, availBoolean);
}

void  generarRelacional(){
	listaCuadruplos = verificacionGeneracionCuadruplo(3, listaCuadruplos, operandos, operadores, cuboSemantico, &contadorIndice, availEntero, availDecimal, availTexto, availBoolean);
}

void  generarAndOr(){
	listaCuadruplos = verificacionGeneracionCuadruplo(4, listaCuadruplos, operandos, operadores, cuboSemantico, &contadorIndice, availEntero, availDecimal, availTexto, availBoolean);
}


int main()
{   
	
	//Creacion de las pilas en memoria
	operandos = malloc(sizeof(pila));
	operandos->tamanio = 0;
	operandos->primero = NULL;

	operadores = malloc(sizeof(pila));
	operadores->tamanio = 0;
	operadores->primero = NULL;

	//Creacion de las pilas de Avail en Memoria
	availEntero = malloc(sizeof(pila));
	availEntero->tamanio = 0;
	availEntero->primero = NULL;

	availDecimal = malloc(sizeof(pila));
	availDecimal->tamanio = 0;
	availDecimal->primero = NULL;

	availTexto = malloc(sizeof(pila));
	availTexto->tamanio = 0;
	availTexto->primero = NULL;

	availBoolean = malloc(sizeof(pila));
	availBoolean->tamanio = 0;
	availBoolean->primero = NULL;
	
	//Inicializacion de las utilidades
	inicializarAvail(availEntero, availDecimal, availTexto, availBoolean, &memoriaEnteroTemp, &memoriaDecimalTemp, &memoriaTextoTemp, &memoriaBooleanoTemp);
	inicializarSemantica(cuboSemantico);
	

	//Asumimos que los enteros empiezan en 1000
	//Aqui empieza la simulacion del algoritmo
	//Algoritmo para cuadruplo:
	// A * (I * B) * Ẍ * Z;
	// A es entero
	// I es decimal

	// * A I temp1
	// * temp1 B temp2

	//Entramos en SEXPRESION
	//Entramos en EXPRESION
	//Entramos en EXP
	//Entrams en TERMINO
	//Entramos en FACTOR
	//Encontramos A y lo guardamos a la PilaOpernado

	//----------------------------------------------------------------------------------------------------------------------------------------------------
	//Checar si la variable esta declarada
	//Accion 1
	//----------------------------------------------------------------------------------------------------------------------------------------------------
	operando = (nodoOperando*)malloc(sizeof(nodoOperando));
	operando->temp = 0;
	operando->tipo = 0; //Int
	strcpy(operando->nombre, "A");
	operando->direccion = memoriaEnteroLocal;
	memoriaEnteroLocal++;

	push(operandos,operando);

	//Accion 5 de la generacion de codigo intermedio
	generarMultiplicacionDivision();
	//__________________________________________________________________________________________________________
	//Preguntamos si el operador encontrado es una multiplicacion
	//Encontramos el operador lo metemos en la pila
	//Accion 3
	operador = (nodoOperador*)malloc(sizeof(nodoOperador));
	operador->operador = OP_MULTIPLICACION;

	push(operadores, operador);

	//Nos metemos en el fondo falso OP_APARENTESIS
	//****************************
	operador = (nodoOperador*)malloc(sizeof(nodoOperador));
	operador->operador = OP_APARENTESIS;

	push(operadores, operador);

	//Nos metemos en FACTOR
	//Encontramos I y lo guardamos a la PilaOpernado
	//Accion 1
	operando = (nodoOperando*)malloc(sizeof(nodoOperando));
	operando->temp = 0;
	operando->tipo = 1;
	strcpy(operando->nombre, "I");
	operando->direccion = memoriaDecimalLocal;
	memoriaDecimalLocal++;

	push(operandos, operando);

	// //Accion 5 de la generacion de codigo intermedio
	generarMultiplicacionDivision();

	//Encontramos el operador lo metemos en la pila
	//Accion 3
	operador = (nodoOperador*)malloc(sizeof(nodoOperador));
	operador->operador = 3;

	push(operadores, operador);

	//Nos metemos en FACTOR
	//Encontramos I y lo guardamos a la PilaOpernado
	//Accion 1
	operando = (nodoOperando*)malloc(sizeof(nodoOperando));
	operando->temp = 0;
	operando->tipo = 1;
	strcpy(operando->nombre, "B");
	operando->direccion = memoriaDecimalLocal;
	memoriaDecimalLocal++;

	push(operandos, operando);

	//Accion 5 de la generacion de codigo intermedio
	generarMultiplicacionDivision();

	//Prueba en falso checarsi hay alguna operacion de suma pendiente
	generarSumaResta();

	//Encontramos el cierre del parentesis OP_CPARENTESIS
	//Sacamos el ultimo operador
	pop(operadores);
	//operador = pop(operadores);

	//****************************

	//Accion 5 de la generacion de codigo intermedio
	generarMultiplicacionDivision();

	//Prueba en falso checarsi hay alguna operacion de suma pendiente
	generarSumaResta();

	//Encontramos el cierre del parentesis OP_CPARENTESIS
	//Sacamos el ultimo operador

	//Encontramos el operador lo metemos en la pila
	//Accion 3
	operador = (nodoOperador*)malloc(sizeof(nodoOperador));
	operador->operador = 3;

	push(operadores, operador);

	//Nos metemos en FACTOR
	//Encontramos I y lo guardamos a la PilaOpernado
	//Accion 1
	operando = (nodoOperando*)malloc(sizeof(nodoOperando));
	operando->temp = 0;
	operando->tipo = 1;
	strcpy(operando->nombre, "X");
	operando->direccion = memoriaDecimalLocal;
	memoriaDecimalLocal++;

	push(operandos, operando);

	//Accion 5 de la generacion de codigo intermedio
	generarMultiplicacionDivision();

	//Encontramos el operador lo metemos en la pila
	//Accion 3
	operador = (nodoOperador*)malloc(sizeof(nodoOperador));
	operador->operador = 3;

	push(operadores, operador);

	//Nos metemos en FACTOR
	//Encontramos I y lo guardamos a la PilaOpernado
	//Accion 1
	operando = (nodoOperando*)malloc(sizeof(nodoOperando));
	operando->temp = 0;
	operando->tipo = 1;
	strcpy(operando->nombre, "Z");
	operando->direccion = memoriaDecimalLocal;
	memoriaDecimalLocal++;

	push(operandos, operando);

	//Accion 5 de la generacion de codigo intermedio
	generarMultiplicacionDivision();

	//generarSumaResta();

	//----------------------------------------------------------------------------------------------------------------------------------------------------
	imprimeCuadruplos(listaCuadruplos, 0);

	// //Seccion de Frees
	// free(operandos);
	// free(operadores);
	// free(availEntero);
	// free(availDecimal);
	// free(availTexto);
	// free(availBoolean);

	
	return 0;
}
