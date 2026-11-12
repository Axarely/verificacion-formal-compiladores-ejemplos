/* fuera_de_limites.c
   Lectura fuera de los limites de un arreglo: comportamiento indefinido
   tanto en ISO C como en CompCert C. Ejecutar con:  ccomp -interp fuera_de_limites.c */
#include <stdio.h>

int main(void) {
    int a[4] = {1, 2, 3, 4};
    int s = 0;
    for (int i = 0; i <= 4; i++)   /* error: i == 4 sale del arreglo */
        s += a[i];
    printf("s = %d\n", s);
    return 0;
}
