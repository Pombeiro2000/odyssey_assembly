# =====================================================================
#  A ODISSEIA DO ASSEMBLY — Motor de Processamento de Dados Simbolicos
#  Milestone 1 — O Contentor
#  Arquitetura de Sistemas Computacionais · ESTGA / Universidade de Aveiro
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

# ---------------------------------------------------------------------
#  RESULTADO: soma total em 64 bits = soma_alta:soma_baixa
#  (mesma convencao de EDX:EAX — parte alta : parte baixa)
# ---------------------------------------------------------------------
soma_baixa:
        .long  0                    # 32 bits menos significativos da soma
soma_alta:
        .long  0                    # 32 bits mais significativos da soma
excede_32:
        .long  0                    # 0 -> soma cabe em 32 bits com sinal

        .text
        .globl main

main:
# =====================================================================
#  INICIALIZACAO
#  Os acumuladores ja estao a 0 em .data, mas inicializamos explicitamente
#  para a rotina estar correta mesmo que seja executada mais do que uma vez.
# =====================================================================
        xorl   %eax, %eax           # eax = 0 (forma eficiente de zerar)
        movl   %eax, soma_baixa     # soma_baixa = 0
        movl   %eax, soma_alta      # soma_alta  = 0
        movl   %eax, excede_32      # excede_32  = 0

# =====================================================================
#  ROTINA DE SOMA TOTAL
#  Para cada elemento:
#     movl elem, %eax   -> carrega o elemento (32 bits com sinal)
#     cltd              -> edx:eax = elemento estendido com sinal a 64 bits
#                          (edx = 0x00000000 se positivo, 0xFFFFFFFF se negativo)
#     addl %eax, baixa  -> soma a parte baixa; CF = 1 se houver transporte
#     adcl %edx, alta   -> soma a parte alta + CF (propaga o transporte)
#  Nenhuma instrucao entre addl e adcl altera CF (mov e cltd nao mexem
#  nas flags), por isso o transporte chega intacto ao adcl.
# =====================================================================
soma_total:
        # --- elemento [0] ---
        movl   contentor, %eax
        cltd
        addl   %eax, soma_baixa
        adcl   %edx, soma_alta

        # --- elemento [1] ---
        movl   contentor+4, %eax
        cltd
        addl   %eax, soma_baixa
        adcl   %edx, soma_alta

        # --- elemento [2] ---
        movl   contentor+8, %eax
        cltd
        addl   %eax, soma_baixa
        adcl   %edx, soma_alta

        # --- elemento [3] ---
        movl   contentor+12, %eax
        cltd
        addl   %eax, soma_baixa
        adcl   %edx, soma_alta

        # --- elemento [4] ---
        movl   contentor+16, %eax
        cltd
        addl   %eax, soma_baixa
        adcl   %edx, soma_alta

        # --- elemento [5] ---
        movl   contentor+20, %eax
        cltd
        addl   %eax, soma_baixa
        adcl   %edx, soma_alta

        # --- elemento [6] ---
        movl   contentor+24, %eax
        cltd
        addl   %eax, soma_baixa
        adcl   %edx, soma_alta

        # --- elemento [7] ---
        movl   contentor+28, %eax
        cltd
        addl   %eax, soma_baixa
        adcl   %edx, soma_alta

# =====================================================================
#  FIM
#  O resultado fica em memoria (soma_alta:soma_baixa, excede_32).
#  main devolve 0 ao sistema.
# =====================================================================
        xorl   %eax, %eax           # valor de retorno de main = 0
        ret

        .section .note.GNU-stack,"",@progbits   # pilha nao executavel (evita aviso do linker)
