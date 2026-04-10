# ================================
# 1. 加载所需R包
# ================================
# 若未安装，请先运行：
install.packages(c("readxl", "dplyr", "gtsummary", "stringr", "tidyr"))
install.packages("gtsummary")
install.packages("gt")
install.packages("rlang")
install.packages("dplyr")
# 更新gtsummary和相关包
install.packages(c("gtsummary", "gt", "broom", "broom.helpers", "xfun"))
install.packages(c("flextable", "officer"))
library(readxl)      # 读取Excel文件
library(dplyr)       # 数据清洗与操作
library(gtsummary)   # 生成临床基线表
library(stringr)     # 字符串处理（提取肿瘤直径）
library(tidyr)       # 处理缺失值
library(xfun)
library(gt)
library(flextable)
library(officer)# 保存为word
# ================================
# 2. 读取Excel数据
# ================================
# 请将文件路径替换为您的实际路径，例如 "data.xlsx"
df_raw <- read_excel("clca_临床信息_带SPIN1表达量.xlsx", 
                     col_names = TRUE ,
                     skip = 4) # 使用第一行作为列名        
                  
# 查看数据前几行，确认列名
head(df_raw)

# 定义提取函数（如上）
extract_tumor_size <- function(x) {
  if (is.na(x) || x == "" || x == "NA") return(NA_real_)
  text <- as.character(x)
  # 处理 dmax= 变体
  dmax_pattern <- "(?i)d(?:a|i)?mx?\\s*=\\s*([\\d.]+(?:[~_\\-][\\d.]+)?)"
  dmax_matches <- str_match_all(text, dmax_pattern)[[1]]
  dmax_values <- c()
  if (nrow(dmax_matches) > 0) {
    for (m in dmax_matches[,2]) {
      if (grepl("[~_\\-]", m)) {
        nums <- as.numeric(unlist(strsplit(m, "[~_\\-]")))
        dmax_values <- c(dmax_values, max(nums, na.rm = TRUE))
      } else {
        dmax_values <- c(dmax_values, as.numeric(m))
      }
    }
  }
  text_no_dmax <- gsub("(?i)d(?:a|i)?mx?\\s*=[^/]+", "", text, perl = TRUE)
  star_matches <- str_match_all(text_no_dmax, "(\\d+(?:\\.\\d+)?)\\s*\\*\\s*(\\d+(?:\\.\\d+)?)")
  star_values <- c()
  if (length(star_matches[[1]]) > 0) {
    for (i in 1:nrow(star_matches[[1]])) {
      star_values <- c(star_values, as.numeric(star_matches[[1]][i, 2]), as.numeric(star_matches[[1]][i, 3]))
    }
  }
  all_numbers <- unlist(str_extract_all(text_no_dmax, "\\d+(?:\\.\\d+)?"))
  all_numbers <- as.numeric(all_numbers)
  all_values <- c(star_values, dmax_values, all_numbers)
  all_values <- all_values[!is.na(all_values) & is.finite(all_values)]
  if (length(all_values) == 0) return(NA_real_)
  return(max(all_values))
}

# 用反引号包裹包含特殊字符的列名
# 3. 数据清洗与变量转换
# ================================
df_clean <- df_raw %>%
  mutate(
    # 分组变量：SPIN1 表达量（转为数值）
    SPIN1 = as.numeric(SPIN1),
    
    # ---------- 连续变量（直接转为数值）----------
    AFP = as.numeric(AFP),
    PIVKA_II = as.numeric(PIVKA_II),
    CA199_U_ML = as.numeric(CA199_U_ML),
    # 处理 TUMOR_SIZE
    TUMOR_SIZE = sapply(TUMOR_SIZE, extract_tumor_size),,
    TUMOR_DEPTH = as.numeric(TUMOR_DEPTH),
    NORMAL_DEPTH = as.numeric(NORMAL_DEPTH),
    TUMOR_PLOIDY = as.numeric(TUMOR_PLOIDY),
    NUMBER_OF_CHROMOTHRPSIS = as.numeric(NUMBER_OF_CHROMOTHRPSIS),
    NUMBER_OF_EXTRACHROMOSOMAL_DNA = as.numeric(NUMBER_OF_EXTRACHROMOSOMAL_DNA),
    NUMBER_OF_KATAEGIS = as.numeric(NUMBER_OF_KATAEGIS),
    # 如果还有其它连续变量如 TUMOR_PURITY、NUMBER_OF_CHOROMOPLEXY 等
    TUMOR_PURITY = as.numeric(TUMOR_PURITY),
    NUMBER_OF_CHOROMOPLEXY = as.numeric(NUMBER_OF_CHOROMOPLEXY),
    
    # ---------- 分类变量：转为因子，指定水平顺序 ----------
    # Edmondson Grade (Level I, II, III, IV)
    EDMONDSON = factor(EDMONDSON, levels = c("Level I", "Level II", "Level III", "Level IV")),
    # MVI (M0, M1, M2)
    MVI = factor(MVI, levels = c("M0", "M1", "M2")),
    # BCLC stage (根据实际取值调整，常见为 0, A, B, C, D)
    BCLC = factor(BCLC, levels = c("0", "A", "B", "C")),
    # 二分类变量
    SMOKING_HISTORY = factor(SMOKING_HISTORY, levels = c("No", "Yes")),
    ALCOHOL_HISTORY = factor(ALCOHOL_HISTORY, levels = c("No", "Yes")),
    MULTIPLE_LESIONS = factor(MULTIPLE_LESIONS, levels = c("No", "Yes")),
    HEPATITIS = factor(HEPATITIS, levels = c("HBV+HCV+", "HBV","HBV-HCV-")),
    CIRRHOSIS_OR_FIBROSIS = factor(CIRRHOSIS_OR_FIBROSIS, levels = c("Cirrhosis", "Fibrosis","Normal")),
    HBSAG = factor(HBSAG, levels = c("-", "+")),
    HBSAB = factor(HBSAB, levels = c("-", "+")),
    HSEAG = factor(HSEAG, levels = c("-", "+")),
    HBEAB = factor(HBEAB, levels = c("-", "+")),
    HBCAB = factor(HBCAB, levels = c("-", "+")),
    HBV = factor(HBV, levels = c("No", "Yes")),
    HCV = factor(HCV, levels = c("No", "Yes")),
    # 其他可能的分类型：SAMPLE_CLASS, ONCOTREE_CODE, SOMATIC_STATUS 等（根据需求可选）
  ) %>%
  # 删除 SPIN1 缺失的行（必要）
  filter(!is.na(SPIN1))

# ================================
# 4. 根据 SPIN1 中位数分为高低两组
# ================================
median_spin1 <- median(df_clean$SPIN1, na.rm = TRUE)
df_clean <- df_clean %>%
  mutate(
    SPIN1_group = ifelse(SPIN1 > median_spin1, "high", "low"),
    SPIN1_group = factor(SPIN1_group, levels = c("low", "high"))
  )

# 查看分组样本量
table(df_clean$SPIN1_group)

# ================================
# 5. 使用 gtsummary 生成 Table 1
# 5. 选择要展示的变量（根据需要可增删）
# ================================
# 建议将所有临床相关变量列出，排除 ID 类列和分组列
vars_for_table <- c(
  "SPIN1_group",          # 分组变量（不展示在特征中，仅用于分组）
  # 连续变量
  "AFP", "PIVKA_II", "CA199_U_ML", "TUMOR_SIZE", "TUMOR_DEPTH", "NORMAL_DEPTH",
  "TUMOR_PLOIDY", "TUMOR_PURITY", "NUMBER_OF_CHOROMOPLEXY", "NUMBER_OF_CHROMOTHRPSIS",
  "NUMBER_OF_EXTRACHROMOSOMAL_DNA", "NUMBER_OF_KATAEGIS",
  # 分类变量
  "EDMONDSON", "MVI", "BCLC", "SMOKING_HISTORY", "ALCOHOL_HISTORY", "MULTIPLE_LESIONS",
  "HEPATITIS", "CIRRHOSIS_OR_FIBROSIS", "HBSAG", "HBSAB", "HSEAG", "HBEAB", "HBCAB",
  "HBV", "HCV"
)

# 为每个变量设置显示标签（中文或英文，根据需求）
label_list <- list(
  AFP ~ "AFP (ng/mL)",
  PIVKA_II ~ "PIVKA-II (mAU/mL)",
  CA199_U_ML ~ "CA19-9 (U/mL)",
  TUMOR_SIZE ~ "Tumor size (cm)",
  TUMOR_DEPTH ~ "Tumor depth (cm)",
  NORMAL_DEPTH ~ "Normal depth (cm)",
  TUMOR_PLOIDY ~ "Tumor ploidy",
  TUMOR_PURITY ~ "Tumor purity",
  NUMBER_OF_CHOROMOPLEXY ~ "Chromoplexy count",
  NUMBER_OF_CHROMOTHRPSIS ~ "Chromothripsis count",
  NUMBER_OF_EXTRACHROMOSOMAL_DNA ~ "ecDNA count",
  NUMBER_OF_KATAEGIS ~ "Kataegis count",
  EDMONDSON ~ "Edmondson grade",
  MVI ~ "Microvascular invasion",
  BCLC ~ "BCLC stage",
  SMOKING_HISTORY ~ "Smoking history",
  ALCOHOL_HISTORY ~ "Alcohol history",
  MULTIPLE_LESIONS ~ "Multiple lesions",
  HEPATITIS ~ "Hepatitis",
  CIRRHOSIS_OR_FIBROSIS ~ "Cirrhosis/fibrosis",
  HBSAG ~ "HBsAg",
  HBSAB ~ "HBsAb",
  HSEAG ~ "HBeAg",
  HBEAB ~ "HBeAb",
  HBCAB ~ "HBcAb",
  HBV ~ "HBV infection",
  HCV ~ "HCV infection"
)

# ================================
# 6. 生成 Table 1
# ================================
tbl <- df_clean %>%
  select(all_of(vars_for_table)) %>%
  tbl_summary(
    by = SPIN1_group,
    statistic = list(
      all_continuous() ~ "{mean} ± {sd}",
      all_categorical() ~ "{n} ({p}%)"
    ),
    digits = all_continuous() ~ 2,
    label = label_list,
    missing = "no"   # 不单独显示缺失（如有需要可改为 "ifany"）
  ) %>%
  add_p(
    test = list(
      all_continuous() ~ "t.test",
      all_categorical() ~ "fisher.test"
    ),
    test.args = list(
      all_categorical() ~ list(simulate.p.value = TRUE, B = 5000)
    ),
    pvalue_fun = function(x) style_pvalue(x, digits = 3)
  ) %>%
  modify_header(label = "**Characteristic**") %>%
  modify_spanning_header(all_stat_cols() ~ "**SPIN1 expression**") %>%
  bold_labels()

# 查看表格
tbl

# ================================
# 7. 保存为 Word 文档
# ================================
tbl %>%
  as_flex_table() %>%
  save_as_docx(path = "clca_SPIN1_all_variables.docx")
