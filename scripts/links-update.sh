#!/bin/bash

# Links Update Script
# 用于更新 Clash 配置文件和规则列表
# 作者: Ohhu
# 仓库: https://github.com/Ohhu/Links

# ============================================
# 配置参数（可根据需要修改）
# ============================================
BRANCH="Clash"
CDN_BASE="https://cdn.jsdelivr.net/gh/Ohhu/Links@${BRANCH}"
GITHUB_BASE="https://raw.githubusercontent.com/Ohhu/Links/refs/heads/${BRANCH}"

# 获取脚本所在目录的父目录（即项目根目录）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 文件存放路径配置
PROFILES_DIR="${PROJECT_ROOT}/rules/Ohhu"    # Profiles 文件存放目录
SNIPPETS_DIR="${PROJECT_ROOT}/snippets"     # Snippets 文件存放目录

# 文件定义
PROFILES_FILES="AdJust.list Assistant.list DIRECT.list HOME.list Manual.list Proxy.list REJECT.list"
SNIPPETS_FILES="groups.toml rulesets.toml"
SCRIPT_NAME="links-update.sh"

# ============================================
# 以下为脚本逻辑，一般无需修改
# ============================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 统计变量
SUCCESS_COUNT=0
FAIL_COUNT=0
FAILED_FILES=""

# 是否使用 CDN
USE_CDN=false

# 保存原始命令行参数
ORIGINAL_ARGS=""

# 打印信息
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# 打印分隔线
print_separator() {
    echo -e "${CYAN}════════════════════════════════════════${NC}"
}

# 打印标题
print_title() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}           ${BLUE}Links Update Script${NC}                              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}        更新 Clash 配置文件和规则列表                        ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# 显示帮助信息
show_help() {
    print_title
    cat << EOF
${YELLOW}用法:${NC}
    $(basename "$0") [选项]

${YELLOW}选项:${NC}
    -c, --cdn       使用 jsdelivr CDN 作为数据源（默认使用 GitHub 直连）
    -h, --help      显示此帮助信息

${YELLOW}示例:${NC}
    # 使用 GitHub 直连更新（默认）
    $(basename "$0")

    # 使用 jsdelivr CDN 更新
    $(basename "$0") -c

${YELLOW}配置说明:${NC}
    Profiles 文件保存位置: ${PROFILES_DIR}
    Snippets 文件保存位置: ${SNIPPETS_DIR}

    可以在脚本开头的配置区域修改这些路径。

EOF
}

# 获取目标目录
get_target_dir() {
    local category=$1
    if [ "$category" = "profiles" ]; then
        echo "$PROFILES_DIR"
    else
        echo "$SNIPPETS_DIR"
    fi
}

# 下载文件
download_file() {
    local filename=$1
    local category=$2
    local base_url=$3
    local target_dir=$(get_target_dir "$category")

    local target_path="${target_dir}/${filename}"
    local temp_path="${target_path}.tmp"
    local url="${base_url}/${category}/${filename}"

    # 确保目标目录存在
    if [ ! -d "$target_dir" ]; then
        log_warning "目标目录不存在，正在创建: ${target_dir}"
        mkdir -p "$target_dir"
    fi

    # 下载文件到临时位置
    echo -ne "  正在下载 ${CYAN}${filename}${NC} ... "

    if curl -s -f \
        --connect-timeout 10 \
        --max-time 60 \
        --retry 3 \
        --retry-delay 2 \
        -o "${temp_path}" \
        "${url}"; then

        if [ -s "${temp_path}" ]; then
            mv "${temp_path}" "${target_path}"
            echo -e "${GREEN}✓${NC}"
            return 0
        else
            rm -f "${temp_path}"
            echo -e "${RED}✗ (空文件)${NC}"
            return 1
        fi
    else
        rm -f "${temp_path}"
        echo -e "${RED}✗ (下载失败)${NC}"
        return 1
    fi
}

# 更新文件列表
update_files() {
    local files=$1
    local category=$2
    local base_url=$3

    for filename in $files; do
        if download_file "$filename" "$category" "$base_url"; then
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        else
            FAIL_COUNT=$((FAIL_COUNT + 1))
            if [ -z "$FAILED_FILES" ]; then
                FAILED_FILES="$filename"
            else
                FAILED_FILES="$FAILED_FILES $filename"
            fi
        fi
    done
}

# 打印统计信息
print_summary() {
    echo ""
    print_separator
    echo -e "${BLUE}更新完成${NC}"
    print_separator
    echo -e "${GREEN}成功: ${SUCCESS_COUNT}${NC}"
    echo -e "${RED}失败: ${FAIL_COUNT}${NC}"

    if [ ${FAIL_COUNT} -gt 0 ]; then
        echo ""
        echo -e "${RED}失败的文件:${NC}"
        for file in $FAILED_FILES; do
            echo -e "  ${RED}✗${NC} ${file}"
        done
    fi
    print_separator
}

# 显示主菜单
show_main_menu() {
    clear
    print_title

    # 显示当前数据源
    if [ "$USE_CDN" = true ]; then
        echo -e "${CYAN}当前数据源: ${YELLOW}jsdelivr CDN${NC}"
    else
        echo -e "${CYAN}当前数据源: ${YELLOW}GitHub 直连${NC}"
    fi
    echo ""

    echo -e "${YELLOW}请选择操作:${NC}"
    echo ""
    echo -e "  ${GREEN}1)${NC} 更新指定文件"
    echo -e "  ${GREEN}2)${NC} 更新 Profiles（规则列表）"
    echo -e "  ${GREEN}3)${NC} 更新 Snippets（配置片段）"
    echo -e "  ${GREEN}4)${NC} 更新所有文件"
    echo -e "  ${GREEN}5)${NC} 更新脚本自身"
    echo -e "  ${RED}0)${NC} 退出"
    echo ""
}

# 显示文件选择菜单
show_file_menu() {
    clear
    print_title
    echo -e "${YELLOW}选择要更新的文件（输入编号，多个用空格或逗号分隔）:${NC}"
    echo ""
    echo -e "${BLUE}Profiles (规则列表):${NC}"
    echo -e "  ${GREEN}1)${NC} AdJust.list"
    echo -e "  ${GREEN}2)${NC} Assistant.list"
    echo -e "  ${GREEN}3)${NC} DIRECT.list"
    echo -e "  ${GREEN}4)${NC} HOME.list"
    echo -e "  ${GREEN}5)${NC} Manual.list"
    echo -e "  ${GREEN}6)${NC} Proxy.list"
    echo -e "  ${GREEN}7)${NC} REJECT.list"
    echo ""
    echo -e "${BLUE}Snippets (配置片段):${NC}"
    echo -e "  ${GREEN}8)${NC} groups.toml"
    echo -e "  ${GREEN}9)${NC} rulesets.toml"
    echo ""
    echo -e "  ${RED}0)${NC} 返回主菜单"
    echo ""
    log_info "提示: 可多选文件，编号用空格或逗号分隔，例如: 1 3 5 或 1,3,5"
    echo ""
}

# 获取用户输入
get_input() {
    local prompt=$1
    local input
    echo -ne "${CYAN}${prompt}${NC}" >&2
    read input
    echo "$input"
}

# 等待用户按键
wait_key() {
    echo ""
    echo -ne "${YELLOW}按回车键继续...${NC}"
    read
}

# 重置统计计数器
reset_counters() {
    SUCCESS_COUNT=0
    FAIL_COUNT=0
    FAILED_FILES=""
}

# 更新所有文件
update_all() {
    local base_url=$1
    reset_counters

    echo ""
    log_info "开始更新所有文件..."
    echo ""

    echo -e "${BLUE}更新 Profiles:${NC}"
    update_files "$PROFILES_FILES" "profiles" "$base_url"

    echo ""
    echo -e "${BLUE}更新 Snippets:${NC}"
    update_files "$SNIPPETS_FILES" "snippets" "$base_url"

    print_summary
    wait_key
}

# 更新 Profiles
update_profiles() {
    local base_url=$1
    reset_counters

    echo ""
    log_info "开始更新 Profiles..."
    echo ""

    update_files "$PROFILES_FILES" "profiles" "$base_url"

    print_summary
    wait_key
}

# 更新 Snippets
update_snippets() {
    local base_url=$1
    reset_counters

    echo ""
    log_info "开始更新 Snippets..."
    echo ""

    update_files "$SNIPPETS_FILES" "snippets" "$base_url"

    print_summary
    wait_key
}

# 更新指定文件（支持多选，用空格或逗号分隔）
update_specific() {
    local base_url=$1

    while true; do
        show_file_menu

        # 读取用户输入（允许输入多个编号，用空格或逗号分隔）
        local input
        echo -ne "${CYAN}请输入文件编号（多个用空格或逗号分隔，如: 1 3 5）:${NC}" >&2
        read -r input

        # 将逗号统一替换为空格，保证按 IFS 正确分割，避免转义歧义
        input=$(printf '%s' "$input" | tr ',' ' ')

        # 用 read -a 安全分割为数组（不会做通配符展开，防止误匹配文件名）
        local -a tokens
        read -ra tokens <<< "$input"

        if [ "${#tokens[@]}" -eq 0 ]; then
            log_error "未输入任何选项，请重新输入"
            sleep 1
            continue
        fi

        # 校验输入只能为数字，拒绝其他字符（防止通配符/命令注入）
        local bad_input=0
        local token
        for token in "${tokens[@]}"; do
            case "$token" in
                ''|*[!0-9]*)
                    log_error "无效输入: ${token}（只能输入数字，用空格或逗号分隔）"
                    bad_input=1
                    ;;
            esac
        done

        if [ "$bad_input" = 1 ]; then
            sleep 1
            continue
        fi

        # 输入中包含 0 则返回主菜单
        local back_requested=0
        for token in "${tokens[@]}"; do
            if [ "$token" = "0" ]; then
                back_requested=1
                break
            fi
        done

        if [ "$back_requested" = 1 ]; then
            return
        fi

        # 将编号映射为文件名与分类（文件名均为固定值，变量一律加双引号防转义）
        local -a selected_names=()
        local -a selected_cats=()
        for token in "${tokens[@]}"; do
            local fname=""
            local fcat=""
            case "$token" in
                1) fname="AdJust.list";    fcat="profiles" ;;
                2) fname="Assistant.list"; fcat="profiles" ;;
                3) fname="DIRECT.list";    fcat="profiles" ;;
                4) fname="HOME.list";      fcat="profiles" ;;
                5) fname="Manual.list";    fcat="profiles" ;;
                6) fname="Proxy.list";     fcat="profiles" ;;
                7) fname="REJECT.list";    fcat="profiles" ;;
                8) fname="groups.toml";    fcat="snippets" ;;
                9) fname="rulesets.toml";  fcat="snippets" ;;
                *) log_error "无效选项: ${token}"; continue ;;
            esac
            if [ -n "$fname" ]; then
                selected_names+=("$fname")
                selected_cats+=("$fcat")
            fi
        done

        local count=${#selected_names[@]}
        if [ "$count" -eq 0 ]; then
            log_error "未选择任何有效文件，请重新输入"
            sleep 1
            continue
        fi

        # 显示待更新文件并逐个下载更新
        reset_counters
        echo ""
        echo -e "${YELLOW}将要更新 ${count} 个文件:${NC}"
        local i
        for ((i = 0; i < count; i++)); do
            echo -e "  ${CYAN}${selected_names[$i]}${NC}（${selected_cats[$i]}）"
        done
        echo ""

        if [ "$USE_CDN" = true ]; then
            log_info "使用数据源: jsdelivr CDN"
        else
            log_info "使用数据源: GitHub 直连"
        fi
        echo ""

        for ((i = 0; i < count; i++)); do
            local name="${selected_names[$i]}"
            local cat="${selected_cats[$i]}"

            log_info "开始更新 ${name}..."
            if download_file "$name" "$cat" "$base_url"; then
                SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
            else
                FAIL_COUNT=$((FAIL_COUNT + 1))
                if [ -z "$FAILED_FILES" ]; then
                    FAILED_FILES="$name"
                else
                    FAILED_FILES="$FAILED_FILES $name"
                fi
            fi
            echo ""
        done

        print_summary
        wait_key
        return
    done
}

# 更新脚本自身
update_self() {
    local base_url=$1
    local script_path="${SCRIPT_DIR}/${SCRIPT_NAME}"
    local temp_path="${script_path}.tmp"
    local url="${base_url}/scripts/${SCRIPT_NAME}"

    echo ""
    log_info "开始更新脚本自身..."
    echo ""

    echo -ne "  正在下载 ${CYAN}${SCRIPT_NAME}${NC} ... "

    if curl -s -f \
        --connect-timeout 10 \
        --max-time 60 \
        --retry 3 \
        --retry-delay 2 \
        -o "${temp_path}" \
        "${url}"; then

        if [ -s "${temp_path}" ]; then
            chmod +x "${temp_path}"
            mv "${temp_path}" "${script_path}"
            echo -e "${GREEN}✓${NC}"
            echo ""
            print_separator
            echo -e "${GREEN}脚本更新成功！正在重新启动...${NC}"
            print_separator
            sleep 1
            exec "$script_path" $ORIGINAL_ARGS
        else
            rm -f "${temp_path}"
            echo -e "${RED}✗ (空文件)${NC}"
        fi
    else
        rm -f "${temp_path}"
        echo -e "${RED}✗ (下载失败)${NC}"
    fi

    wait_key
}

# 解析命令行参数
parse_args() {
    while [ $# -gt 0 ]; do
        case $1 in
            -c|--cdn)
                USE_CDN=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "未知选项: $1"
                echo "使用 -h 或 --help 查看帮助信息"
                exit 1
                ;;
        esac
    done
}

# 主函数
main() {
    # 保存原始命令行参数
    ORIGINAL_ARGS="$*"

    # 解析命令行参数
    parse_args "$@"

    # 确定 base URL
    local base_url
    if [ "$USE_CDN" = true ]; then
        base_url="$CDN_BASE"
    else
        base_url="$GITHUB_BASE"
    fi

    # 主循环
    while true; do
        show_main_menu
        choice=$(get_input "请输入选项 [0-5]: ")

        case $choice in
            1)
                update_specific "$base_url"
                ;;
            2)
                update_profiles "$base_url"
                ;;
            3)
                update_snippets "$base_url"
                ;;
            4)
                update_all "$base_url"
                ;;
            5)
                update_self "$base_url"
                ;;
            0)
                clear
                print_title
                echo -e "${GREEN}感谢使用！再见！${NC}"
                echo ""
                exit 0
                ;;
            *)
                log_error "无效的选项，请重新输入"
                sleep 1
                ;;
        esac
    done
}

# 执行主函数
main "$@"
