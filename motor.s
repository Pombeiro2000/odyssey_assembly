# =====================================================================
#  Milestone 1 — O Contentor
#
# =====================================================================

        .data

# ---------------------------------------------------------------------
#  O CONTENTOR: 8 posicoes x 4 bytes = 32 bytes
#  Valores escolhidos para testar: positivos, negativos, zero e valores
#  grandes cuja soma ultrapassa a gama de 32 bits (overflow).
# ---------------------------------------------------------------------
contentor:
        .long  2000000000           # [0] contentor+0   positivo grande
        .long  1500000000           # [1] contentor+4   positivo grande
        .long  -7                   # [2] contentor+8   negativo
        .long  0                    # [3] contentor+12  zero
        .long  42                   # [4] contentor+16  positivo
        .long  -300                 # [5] contentor+20  negativo
        .long  1000000000           # [6] contentor+24  positivo grande
        .long  25                   # [7] contentor+28  positivo

n_elementos:
        .long  8                    # numero de posicoes do contentor

        .text
        .globl main

main:

        xorl   %eax, %eax           # valor de retorno de main = 0
        ret

        .section .note.GNU-stack,"",@progbits   