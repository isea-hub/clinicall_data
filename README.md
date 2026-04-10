# clinicall_data
临床基线特征分析 - README

项目概述

本代码用于分析肝癌患者的临床基线数据，根据SPIN1基因表达水平（中位数分组）比较临床特征的差异，生成标准的临床基线特征表（Table 1）。

主要功能

1. 从Excel文件中读取临床数据
2. 数据清洗和变量类型转换
3. 根据SPIN1表达量中位数将患者分为高低两组
4. 生成包含组间统计比较的基线特征表
5. 将结果保存为Word文档

数据要求

输入文件

• 文件名: clca_临床信息_带SPIN1表达量.xlsx

• 格式: Excel文件，包含临床变量和SPIN1表达量

• 数据位置: 从第5行开始读取（跳过前4行表头）

关键变量

代码处理以下临床变量：

连续变量

• SPIN1（分组依据）

• AFP, PIVKA_II, CA199_U_ML（肿瘤标志物）

• TUMOR_SIZE, TUMOR_DEPTH, NORMAL_DEPTH（肿瘤尺寸）

• 基因组特征：TUMOR_PLOIDY, TUMOR_PURITY, NUMBER_OF_CHOROMOPLEXY等

分类变量

• 临床分级：EDMONDSON, MVI, BCLC

• 病史：SMOKING_HISTORY, ALCOHOL_HISTORY, MULTIPLE_LESIONS

• 肝炎相关：HEPATITIS, CIRRHOSIS_OR_FIBROSIS, HBV, HCV

• 肝炎血清学标志：HBSAG, HBSAB, HSEAG, HBEAB, HBCAB

核心算法说明

1. 肿瘤尺寸提取函数

extract_tumor_size()

• 从自由文本中提取肿瘤最大直径

• 支持多种格式：

  • dmax=5.0 或 dmax=3~5 格式

  • 3.5*4.2 乘法格式

  • 直接提取数值

• 返回所有数值中的最大值

2. 分组方法

• 以SPIN1表达量的中位数为界

• 高于中位数：high组

• 低于等于中位数：low组

3. 统计分析

• 连续变量：均值±标准差，t检验

• 分类变量：频数（百分比），Fisher精确检验

• p值显示3位小数

输出结果

生成的表格包含：

1. 患者特征（Characteristic）
2. 低SPIN1组统计
3. 高SPIN1组统计
4. 组间p值

输出文件

• 文件名: clca_SPIN1_all_variables.docx

• 格式: Word文档

• 内容: 格式化的Table 1表格

使用步骤

1. 将临床数据Excel文件放在工作目录
2. 运行R脚本
3. 查看生成的Table 1
4. 检查输出Word文档

依赖包

# 数据操作
readxl, dplyr, stringr, tidyr, rlang

# 表格生成
gtsummary, gt, flextable, officer

# 统计分析
broom, broom.helpers


注意事项

1. 数据质量: 确保SPIN1列无缺失，缺失行将被删除
2. 变量转换: 分类变量已预设水平顺序
3. 统计方法: 分类变量使用Fisher精确检验，适用于小样本
4. 肿瘤大小提取: 复杂文本格式可能提取不准确，建议检查

可调整参数

1. 分组阈值: 修改median_spin1计算方式可改为其他分界点
2. 统计方法: 在add_p()中修改检验方法
3. 变量选择: 在vars_for_table中增删变量
4. 显示格式: 在label_list中修改变量标签

错误处理

• 文件不存在时：检查路径和文件名

• 变量名错误时：检查Excel列名是否匹配

• 包加载失败时：运行安装代码重新安装

应用场景

适用于临床研究中比较不同基因表达组间基线特征的平衡性检验，为后续多因素分析提供基础。
