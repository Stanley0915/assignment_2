# ===== 查找表 =====


.align 2

.data

rsqrt_table:

.word 65536 # 2^0

.word 46341 # 2^1

.word 32768 # 2^2

.word 23170 # 2^3

.word 16384 # 2^4

.word 11585 # 2^5

.word 8192 # 2^6

.word 5793 # 2^7

.word 4096 # 2^8

.word 2896 # 2^9

.word 2048 # 2^10

.word 1448 # 2^11

.word 1024 # 2^12

.word 724 # 2^13

.word 512 # 2^14

.word 362 # 2^15

.word 256 # 2^16

.word 181 # 2^17

.word 128 # 2^18

.word 90 # 2^19

.word 64 # 2^20

.word 45 # 2^21

.word 32 # 2^22

.word 23 # 2^23

.word 16 # 2^24

.word 11 # 2^25

.word 8 # 2^26

.word 6 # 2^27

.word 4 # 2^28

.word 3 # 2^29

.word 2 # 2^30

.word 1 # 2^31

.text

.globl rsqrt_fast

.align 2

main:

li a0,4



rsqrt:

beq a0,x0,return1

li a5,1

beq a0,a5,return2

mv a7,a0

addi sp,sp,-16

sw s0,12(sp)

#clz_begin

mv t1, a0

li t2, 32

li t3, 16

1: srl t4, t1, t3

beqz t4, 2f

sub t2, t2, t3

mv t1, t4

2: srai t3, t3, 1

bnez t3, 1b

sub t2, t2, t1

mv a4,t2

#clz_end

li a3, 31

sub a3, a3, a4 # 31 - clz(value)

la a2, rsqrt_table

slli a1,a3,2

#addi a2,a2,%lo(rsqrt_table)

li a5,1

add a1,a2,a1

sll a5,a5,a3

lw a0,0(a1)

bleu a7,a5,loop

#線性插直法

li a1,32

sub a4,a1,a4

slli a4,a4,2

add a2,a2,a4 # a2 = &rsqrt_table[exp+1]

lw a2,0(a2)

sub a2,a0,a2



frace:

# 計算分數部分：frac = ((x - (1 << exp)) << 16) >> exp

sub a5,a7,a5

sltu a4,a7,a5

neg a4,a4

srli a6,a5,16

slli a4,a4,16

addi a1,a3,-32

add a4,a6,a4

slli a5,a5,16

blt a1,zero,exp_smaller_32

srl a5,a4,a1



Correction_frace:

mul a5,a2,a5 # a5 = delta * frac

srli a5,a5,16

sub a0,a0,a5 # y -= (delta * frac) >> 16



# ===== 第一次牛頓迭代準備 =====

loop:

li t3,2

li a6,31

li a1,32

srli t1,a7,1

li t5,196608

li t4,1



# ===== 第一次牛頓迭代：計算 y^2 =====

Iteration:

li t0,0

li a5,0



# 展開的乘法循環：y * y

y_mul_y:

addi a2,a5,-32

srl a3,a0,a5

sll a4,a0,a5

srai a2,a2,31

andi a3,a3,1

and a4,a4,a2

addi a5,a5,1

beq a3,zero,x_mul_y_2

add t0,t0,a4



x_mul_y_2:

bne a5,a1,y_mul_y



# ===== 計算 x * y^2 =====

li a2,0

li t6,0

li a5,0

j check_bit



# 展開的乘法循環：x * y^2

bit_is_1:

li a4,0

sll a3,a7,a3



_1_xy2_add:

add a4,a2,a4

sltu t2,a4,a2

add t6,t6,a3

mv a2,a4

add t6,t2,t6



next_bit:

addi a5,a5,1

beq a5,a1,first



check_bit:

srl a4,t0,a5

andi a4,a4,1

addi a3,a5,-32

beq a4,x0,next_bit

sub a4,a6,a5

bge a3,x0,bit_is_1

srl a3,t1,a4

sll a4,a7,a5

j _1_xy2_add



# ===== 第一次牛頓迭代：更新 y =====

first:

slli t6,t6,16

srli a2,a2,16

add a2,t6,a2 # xy2 = (x * y^2) >> 16

sub a2,t5,a2 # a2 = (3 << 16) - xy2

li t0,0

li t6,0

li a5,0

srli s0,a0,1 # s0 = y >> 1

j check_bit_2



# ===== 第二次牛頓迭代：計算 y * ((3 << 16) - xy2) =====

bit_is_1_two:

li a4,0

sll a3,a0,a3



add2:

add a4,t0,a4

sltu t2,a4,t0

add t6,t6,a3

mv t0,a4

add t6,t2,t6



next_bit2:

addi a5,a5,1

beq a5,a1,Iteration2



check_bit_2:

srl a4,a2,a5 # 檢查 ((3 << 16) - xy2) 的第 i 位

andi a4,a4,1

addi a3,a5,-32

beq a4,zero,next_bit2

sub a4,a6,a5

bge a3,zero,bit_is_1_two

srl a3,s0,a4

sll a4,a0,a5

j add2



# ===== 第二次牛頓迭代：最終結果 =====

Iteration2:

slli t6,t6,15

srli t0,t0,17

add a0,t6,t0

beq t3,t4,end

li t3,1 # 設置迭代計數器為 1

j Iteration



# ===== 函數返回 =====

end:

lw s0,12(sp)
addi sp,sp,16
li a7, 10
ecall



# ===== 特殊情況返回 =====



exp_smaller_32:

# 處理 exp >= 32 的情況

li a1,31
slli a4,a4,
sub a1,a1,a3
srl a5,a5,a3
sll a4,a4,a1
add a5,a4,a5
j Correction_frace




return1:
li a0,-1
li a7, 10
ecall


return2:
li a0,65536
li a7, 93

ecall


