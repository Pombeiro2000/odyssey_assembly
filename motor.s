# =====================================================================
#  A ODISSEIA DO ASSEMBLY — Motor de Processamento de Dados Simbolicos
#  Milestone 1 — O Contentor
#
#  Sintaxe AT&T (GAS), arquitetura IA-32.
#  Compilar:  gcc motor.s -o motor        (em sistema de 64 bits: gcc -m32 motor.s -o motor)
#
#  O que faz:
#    1. Define um contentor de 8 inteiros de 32 bits COM SINAL (.long).
#    2. Inicializa um acumulador de 64 bits (soma_alta:soma_baixa) a zero.
#    3. Soma todos os elementos usando addl (parte baixa) + adcl (parte
#       alta), com extensao de sinal (cltd) de cada elemento para 64 bits.
#       Assim a soma nunca perde informacao, mesmo que ultrapasse 32 bits.
#    4. Calcula o indicador excede_32 (0 = a soma cabe num long com sinal;
#       != 0 = a soma so e representavel nos 64 bits).
#
#  Usa apenas materia das Aulas 1-6 (mov, add, adc, xor, cltd, flags).
#  Cada elemento e acedido por enderecamento direto
#  (rotulo + deslocamento constante).
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
# =====================================================================
#  FIM
#  main devolve 0 ao sistema.
# =====================================================================
        xorl   %eax, %eax           # valor de retorno de main = 0
        ret

        .section .note.GNU-stack,"",@progbits   # pilha nao executavel (evita aviso do linker)
