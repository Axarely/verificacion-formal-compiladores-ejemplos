/* desbordamiento.c
   Programa con comportamiento indefinido (desbordamiento de int con signo).
   Sirve para mostrar por que un compilador "correcto" necesita una
   semantica formal que diga que significa cada programa. */
#include <stdio.h>
#include <limits.h>

int siempre_mayor(int x) {
    int y = x + 1;         /* indefinido si x == INT_MAX */
    return y > x;
}

int main(void) {
    printf("siempre_mayor(INT_MAX) = %d\n", siempre_mayor(INT_MAX));
    return 0;
}
