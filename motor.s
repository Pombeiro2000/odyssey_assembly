# =====================================================================
#  A ODISSEIA DO ASSEMBLY — Motor de Processamento de Dados Simbolicos
#
#  Sintaxe AT&T (GAS), arquitetura IA-32.
#  Compilar:  gcc motor.s -o motor
#
#  O que faz:
#    1. Define um contentor de 8 inteiros de 32 bits COM SINAL (.long).
#    2. Soma todos os elementos num acumulador de 64 bits
#       (soma_alta:soma_baixa) com cltd + addl/adcl.
#    3. Calcula o indicador excede_32 (0 = a soma cabe num long com sinal).
#    4. Percorre o contentor com um ciclo (anatomia da Aula 9: cmp + jge +
#       jmp) e classifica cada elemento como positivo, negativo ou zero
#       com o padrao if-then-else da Aula 8 (cmp + salto para o "senao" +
#       jmp fim_if), acumulando 3 contadores.
#
#  O elemento atual e lido com (%edx): %edx guarda o endereco do elemento
#  e avanca 4 bytes por iteracao.
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
#  Irá ter um resultado da soma total em 64 bits = soma_alta:soma_baixa
#  (mesma convencao de EDX:EAX — parte alta : parte baixa)
# ---------------------------------------------------------------------
soma_baixa:
        .long  0                    # 32 bits menos significativos da soma
soma_alta:
        .long  0                    # 32 bits mais significativos da soma
excede_32:
        .long  0                    # 0 -> soma cabe em 32 bits com sinal

# ---------------------------------------------------------------------
#  Contadores da classificação
# ---------------------------------------------------------------------
conta_positivos:
        .long  0                    # numero de elementos > 0
conta_negativos:
        .long  0                    # numero de elementos < 0
conta_zeros:
        .long  0                    # numero de elementos == 0

        .text
        .globl main

main:
# =====================================================================
#  Dá-se o início dos acumuladores ja estao a 0 em .data, mas inicializamos explicitamente
#  para a rotina estar correta mesmo que seja executada mais do que uma vez.
# =====================================================================
        xorl   %eax, %eax           # eax = 0 (forma eficiente de zerar)
        movl   %eax, soma_baixa     # soma_baixa = 0
        movl   %eax, soma_alta      # soma_alta  = 0
        movl   %eax, excede_32      # excede_32  = 0
        movl   %eax, conta_positivos # conta_positivos = 0
        movl   %eax, conta_negativos # conta_negativos = 0
        movl   %eax, conta_zeros     # conta_zeros     = 0

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
#  Verificação de overflow a 32 bits
#  A soma cabe num long com sinal se e so se a parte alta for igual a
#  extensao de sinal da parte baixa. Estendemos a parte baixa com cltd e
#  comparamos com a parte alta usando xor: resultado 0 <=> sao iguais.
# =====================================================================
        movl   soma_baixa, %eax     # eax = parte baixa
        cltd                        # edx = extensao de sinal de eax
        xorl   soma_alta, %edx      # edx = 0 se a soma cabe em 32 bits
        movl   %edx, excede_32      # guarda o indicador

# =====================================================================
#  O ciclo sobre o contentor é feito:
#   1. inicializar a variavel de controlo
#   2. testar a condicao de paragem (cmp + salto condicional)
#   3. corpo do ciclo
#   4. atualizar a variavel de controlo
#   5. saltar incondicionalmente de volta ao teste
#  %ecx = indice i (0, 1, ..., n_elementos-1)
#  %edx = endereco do elemento i (comeca em contentor, avanca 4 bytes)
# =====================================================================
classificacao:
        movl   $contentor, %edx     # 1. edx = ENDERECO do elemento [0] (com $)
        movl   $0, %ecx             # 1. i = 0

ciclo:
        cmpl   n_elementos, %ecx    # 2. compara i com n_elementos
        jge    fim_ciclo            # 2. se i >= n_elementos, sai do ciclo
                                    #    (jge e nao jg: com jg o ciclo faria
                                    #     uma iteracao a mais -> off-by-one)

        movl   (%edx), %eax         # 3. eax = M[edx] = elemento i

        # Faz-se a classificacao do elemento: padrao if-then-else
        # if (eax > 0) positivos++
        # else if (eax == 0) zeros++
        # else negativos++
        # Saltos COM sinal (jle), porque os valores estao em C2: com a versao
        # sem sinal (jbe) um negativo como -7 = 0xFFFFFFF9 seria tratado
        # como "maior" do que 0 e contado como positivo.
        cmpl   $0, %eax             # compara o elemento com 0
        jle    senao_positivo       # se eax <= 0, salta para o ramo else
        incl   conta_positivos      # ramo then: e positivo
        jmp    fim_if               # salta o ramo else

senao_positivo:                     # ramo else: eax <= 0
        cmpl   $0, %eax             # compara de novo com 0
        jne    senao_zero           # se eax != 0, salta para o else interno
        incl   conta_zeros          # then interno: e zero
        jmp    fim_if               # salta o else interno

senao_zero:                         # else interno: eax < 0
        incl   conta_negativos      # e negativo

fim_if:
        addl   $4, %edx             # 4 endereco do elemento seguinte (+4 bytes)
        incl   %ecx                 # 4 i++
        jmp    ciclo                # 5 volta ao teste
fim_ciclo:

# =====================================================================
#  Os resultados ficam em memoria (soma_alta:soma_baixa, excede_32,
#  conta_positivos, conta_negativos, conta_zeros).
#  main devolve 0 ao sistema.
# =====================================================================
        xorl   %eax, %eax           # valor de retorno de main = 0
        ret

        .section .note.GNU-stack,"",@progbits   # pilha nao executavel (evita aviso do linker)
