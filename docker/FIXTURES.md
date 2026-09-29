# Salmon 2.8 synthetic smoke fixture

`piscem-v2.rad` 根据官方 v2.8.0
`crates/salmon-align/tests/rad_input.rs::run_piscem_bulk_quant` 构造：两个长度1000的目标，
400个唯一匹配的proper-pair片段，t0=300、t1=100，长度200。不是生产数据；
来源构造遵循Salmon BSD-3-Clause许可，不需要网络或参考数据库。

生成器使用固定libradicl 0.21.0的官方RadFileWriter，以RAD_FILE/v2.0头、tag角色、
单个未压缩chunk写出；生成器及Cargo.lock归维护者证据目录，不进入运行镜像。
普通smoke仅只读此文件，输出和scratch写本轮唯一/tmp目录。

其余FASTA/FASTQ/SAM/GTF/quant表为脚本生成的小型synthetic fixture。
DAAREM正向使用`--useEM`，默认VBEM拒绝为预期负向；不修改上游算法或降低断言。
