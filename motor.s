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
#    4. Classifica cada elemento como positivo, negativo ou zero com o
#       padrao if-then-else da Aula 8, acumulando 3 contadores.
#    5. (Milestone 3) A logica esta organizada em funcoes com stack frame
#       propria (prologo/epilogo) e parametros passados pela pilha:
#          obter_elemento(indice)  -> devolve contentor[indice] em %eax
#          somar_elemento(valor)   -> soma o valor ao acumulador de 64 bits
#          classificar(valor)      -> incrementa o contador certo
#       O contentor so e lido dentro de obter_elemento, com enderecamento
#       indexado: contentor(,%ecx,4) = contentor + indice*4.
#
#  Convencao de chamada (cdecl):
#    - quem chama faz push dos parametros, call, e no fim addl $4, %esp
#    - o 1.o parametro fica em 8(%ebp) dentro da funcao
#    - o valor de retorno vem em %eax
#    - %eax, %ecx e %edx podem ser alterados pelas funcoes; %ebx, %esi,
#      %edi e %ebp tem de ser preservados (por isso main guarda %ebx/%esi)
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
#  Resultado da soma total em 64 bits = soma_alta:soma_baixa
#  (mesma convencao de EDX:EAX — parte alta : parte baixa)
# ---------------------------------------------------------------------
soma_baixa:
        .long  0                    # 32 bits menos significativos da soma
soma_alta:
        .long  0                    # 32 bits mais significativos da soma
excede_32:
        .long  0                    # 0 -> soma cabe em 32 bits com sinal

# ---------------------------------------------------------------------
#  Contadores da classificacao
# ---------------------------------------------------------------------
conta_positivos:
        .long  0                    # numero de elementos > 0
conta_negativos:
        .long  0                    # numero de elementos < 0
conta_zeros:
        .long  0                    # numero de elementos == 0

        .text
        .globl main

# =====================================================================
#  main — orquestra o motor
#  Para cada indice i (0, 1, ..., n_elementos-1):
#     valor = obter_elemento(i)
#     somar_elemento(valor)
#     classificar(valor)
#  No fim verifica se a soma cabe em 32 bits (excede_32).
#
#  %ebx = indice i       (callee-saved: as funcoes nao o alteram)
#  %esi = valor atual    (callee-saved: sobrevive as chamadas)
#  Nao se usa %ecx/%edx para isto porque as funcoes podem altera-los
#  (obter_elemento usa %ecx e o cltd de somar_elemento escreve em %edx).
# =====================================================================
main:
        # --- prologo ---
        pushl  %ebp                 # guarda o %ebp de quem chamou main
        movl   %esp, %ebp           # %ebp = base da stack frame de main
        pushl  %ebx                 # main vai usar %ebx e %esi, por isso
        pushl  %esi                 # guarda os valores antigos

        # --- inicializacao dos acumuladores ---
        # Ja estao a 0 em .data, mas inicializamos explicitamente para a
        # rotina estar correta mesmo que seja executada mais do que uma vez.
        xorl   %eax, %eax           # eax = 0 (forma eficiente de zerar)
        movl   %eax, soma_baixa     # soma_baixa = 0
        movl   %eax, soma_alta      # soma_alta  = 0
        movl   %eax, excede_32      # excede_32  = 0
        movl   %eax, conta_positivos # conta_positivos = 0
        movl   %eax, conta_negativos # conta_negativos = 0
        movl   %eax, conta_zeros     # conta_zeros     = 0

# =====================================================================
#  Ciclo sobre o contentor (anatomia da Aula 9):
#   1. inicializar a variavel de controlo
#   2. testar a condicao de paragem (cmp + salto condicional)
#   3. corpo do ciclo (agora so chamadas a funcoes)
#   4. atualizar a variavel de controlo
#   5. saltar incondicionalmente de volta ao teste
#  Este ciclo substitui os 8 blocos copiados da soma do Milestone 1 e o
#  ponteiro %edx do ciclo do Milestone 2.
# =====================================================================
        movl   $0, %ebx             # 1. i = 0

ciclo:
        cmpl   n_elementos, %ebx    # 2. compara i com n_elementos
        jge    fim_ciclo            # 2. se i >= n_elementos, sai do ciclo
                                    #    (jge e nao jg -> sem off-by-one)

        # 3. valor = obter_elemento(i)
        pushl  %ebx                 # parametro: indice i
        call   obter_elemento       # devolve contentor[i] em %eax
        addl   $4, %esp             # retira o parametro da pilha
        movl   %eax, %esi           # guarda o valor (eax nao sobrevive a calls)

        # 3. somar_elemento(valor)
        pushl  %esi                 # parametro: valor
        call   somar_elemento
        addl   $4, %esp             # retira o parametro da pilha

        # 3. classificar(valor)
        pushl  %esi                 # parametro: valor
        call   classificar
        addl   $4, %esp             # retira o parametro da pilha

        incl   %ebx                 # 4. i++
        jmp    ciclo                # 5. volta ao teste
fim_ciclo:

# =====================================================================
#  Verificacao de overflow a 32 bits
#  A soma cabe num long com sinal se e so se a parte alta for igual a
#  extensao de sinal da parte baixa. Estendemos a parte baixa com cltd e
#  comparamos com a parte alta usando xor: resultado 0 <=> sao iguais.
# =====================================================================
        movl   soma_baixa, %eax     # eax = parte baixa
        cltd                        # edx = extensao de sinal de eax
        xorl   soma_alta, %edx      # edx = 0 se a soma cabe em 32 bits
        movl   %edx, excede_32      # guarda o indicador

# =====================================================================
#  Os resultados ficam em memoria (soma_alta:soma_baixa, excede_32,
#  conta_positivos, conta_negativos, conta_zeros).
#  main devolve 0 ao sistema.
# =====================================================================
        xorl   %eax, %eax           # valor de retorno de main = 0

        # --- epilogo ---
        popl   %esi                 # repoe %esi e %ebx (ordem inversa
        popl   %ebx                 # dos push do prologo)
        movl   %ebp, %esp           # liberta a stack frame
        popl   %ebp                 # repoe o %ebp de quem chamou main
        ret


# =====================================================================
#  obter_elemento(indice)
#  Parametro: 8(%ebp) = indice do elemento (0 .. n_elementos-1)
#  Devolve:   %eax = contentor[indice]
#  Enderecamento indexado: contentor(,%ecx,4) -> endereco contentor + ecx*4
#  (o fator de escala 4 e o tamanho de um .long)
#  Quem chama garante que 0 <= indice < n_elementos.
# =====================================================================
obter_elemento:
        pushl  %ebp                 # prologo: guarda o %ebp de quem chamou
        movl   %esp, %ebp           # prologo: nova base da stack frame

        movl   8(%ebp), %ecx        # ecx = indice (1.o parametro)
        movl   contentor(,%ecx,4), %eax   # eax = M[contentor + ecx*4]

        movl   %ebp, %esp           # epilogo: liberta a stack frame
        popl   %ebp                 # epilogo: repoe o %ebp de quem chamou
        ret                         # volta para o endereco de retorno


# =====================================================================
#  somar_elemento(valor)
#  Parametro: 8(%ebp) = valor a somar (32 bits com sinal)
#  Soma o valor ao acumulador de 64 bits soma_alta:soma_baixa (Milestone 1):
#     cltd              -> edx:eax = valor estendido com sinal a 64 bits
#     addl %eax, baixa  -> soma a parte baixa; CF = 1 se houver transporte
#     adcl %edx, alta   -> soma a parte alta + CF (propaga o transporte)
#  Nenhuma instrucao entre addl e adcl altera CF.
#  Nao devolve nada (altera %eax e %edx, que sao caller-saved).
# =====================================================================
somar_elemento:
        pushl  %ebp                 # prologo
        movl   %esp, %ebp

        movl   8(%ebp), %eax        # eax = valor (1.o parametro)
        cltd                        # edx:eax = valor em 64 bits
        addl   %eax, soma_baixa     # parte baixa, CF = transporte
        adcl   %edx, soma_alta      # parte alta + CF

        movl   %ebp, %esp           # epilogo
        popl   %ebp
        ret


# =====================================================================
#  classificar(valor)
#  Parametro: 8(%ebp) = valor a classificar (32 bits com sinal)
#  Incrementa conta_positivos, conta_zeros ou conta_negativos.
#  Padrao if-then-else da Aula 8 (o mesmo do Milestone 2):
#     if (valor > 0) positivos++
#     else if (valor == 0) zeros++
#     else negativos++
#  Saltos COM sinal (jle): com jbe (sem sinal) -7 = 0xFFFFFFF9 seria
#  tratado como "maior" do que 0 e contado como positivo.
#  Nao devolve nada (altera %eax, que e caller-saved).
# =====================================================================
classificar:
        pushl  %ebp                 # prologo
        movl   %esp, %ebp

        movl   8(%ebp), %eax        # eax = valor (1.o parametro)
        cmpl   $0, %eax             # compara o valor com 0
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
        movl   %ebp, %esp           # epilogo
        popl   %ebp
        ret

        .section .note.GNU-stack,"",@progbits   # pilha nao executavel (evita aviso do linker)
