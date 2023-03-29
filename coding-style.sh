#!/bin/bash
# bash script forked from git@github.com:Epitech/coding-style-checker.git
# Remake by : @neo-jgrec

coding_style_error_codes=(
    "C-A3:file not ending with a line break"
    "C-C1:conditional block with more than 3 branches, or at a nesting level of 3 or more"
    "C-C3:use of \"goto\" keyword"
    "C-F2:function name not following the snake_case convention"
    "C-F3:line of more than 80 columns"
    "C-F4:line part of a function with more than 20 lines"
    "C-F5:function with more than 4 parameters"
    "C-F6:function with empty parameter list"
    "C-F8:comment inside function"
    "C-F9:nested function defined"
    "C-G1:file not starting with correctly formatted Epitech standard header"
    "C-G2:zero, two, or more empty lines separating implementations of functions"
    "C-G3:bad indentation of preprocessor directive"
    "C-G4:global variable used"
    "C-G5:\"include\" directive used to include file other than a header"
    "C-G6:carriage return character \r used"
    "C-G7:trailing space"
    "C-G8:leading or trailing empty line"
    "C-H1:bad separation between source file and header file"
    "C-H2:header file not protected against double inclusion"
    "C-L2:bad indentation at the start of a line"
    "C-L3:misplaced or missing space(s)"
    "C-L4:misplaced curly bracket"
    "C-O1:compiled, temporary or unnecessary file"
    "C-O3:more than 5 functions in a single file"
    "C-O4:file name not following the snake_case convention"
    "C-V1:identifier name not following the snake_case convention"
)

help() {
    echo -e "Usage: coding-style.sh\e[0m"
    echo -e "This script will run the coding style checker\n on the current directory and put a report in the \e[1mreport\e[0m directory"
    echo -e "Options:"
    echo -e "  --help\t\tShow this help"
    echo -e "  --pull\t\tPull the latest version of the coding style checker"
    echo -e "  --re-pull\t\tRemove the current version of the coding style checker docker image and pull the latest version"
}

if [ $# == 1 ] && [ $1 == "--help" ]; then
    help
elif [ $# == 0 ] || [ $1 == "--pull" ] || [ $1 == "--re-pull" ]; then
    DOCKER_SOCKET_PATH=/var/run/docker.sock
    HAS_SOCKET_ACCESS=$(test -r $DOCKER_SOCKET_PATH; echo "$?")
    BASE_EXEC_CMD="docker"
    REPORT_FOLDER="report"
    EXPORT_FILE="report"/coding-style-reports.log
    echo -e "\e[32mRunning coding style checker at $(pwd)\e[0m"
    mkdir -p "$REPORT_FOLDER"
    if [ -f "$EXPORT_FILE" ]; then
        rm -f "$EXPORT_FILE"
    fi

    if [ $HAS_SOCKET_ACCESS -ne 0 ]; then
        echo -e "\e[31mNOTICE: Socket access is denied\e[0m, if you want to fix this, add the current user to docker group with : sudo usermod -a -G docker $USER"
        BASE_EXEC_CMD="sudo ${BASE_EXEC_CMD}"
    fi

    if [ "$1" = "--pull" ] || [ "$1" = "--re-pull" ]; then
        echo -e "\e[32mPulling latest version of the coding style checker\e[0m"
        if [ "$1" = "--re-pull" ]; then
            echo -e "\e[32mRemoving old version of the coding style checker\e[0m"
            $BASE_EXEC_CMD rmi ghcr.io/epitech/coding-style-checker:latest
        fi
        $BASE_EXEC_CMD pull ghcr.io/epitech/coding-style-checker:latest
    fi


    $BASE_EXEC_CMD run --rm -i -v "$(pwd)":"/mnt/delivery" -v "$(pwd)/report":"/mnt/reports" ghcr.io/epitech/coding-style-checker:latest "/mnt/delivery" "/mnt/reports"
    if [[ -f "$EXPORT_FILE" ]]; then
        echo -en "\e[0;34m$(wc -l < "$EXPORT_FILE") coding style error(s) reported in $EXPORT_FILE\e[0m"
        echo -en ", $(grep -c ": MAJOR:" "$EXPORT_FILE") \e[31mmajor\e[0m"
        echo -en ", $(grep -c ": MINOR:" "$EXPORT_FILE") \e[33mminor\e[0m"
        echo -e ", $(grep -c ": INFO:" "$EXPORT_FILE") \e[32minfo\e[0m"
        for error_type in "MAJOR" "MINOR" "INFO"; do
            for error_code in "${coding_style_error_codes[@]}"; do
                error_code_name=$(echo "$error_code" | cut -d':' -f1)
                error_code_description=$(echo "$error_code" | cut -d':' -f2)
                error_code_count=$(grep -c "$error_code_name" "$EXPORT_FILE")
                error_color=$(if cat "$EXPORT_FILE" | grep "$error_code_name" | grep -q ": MAJOR:"; then echo -e "\e[31m"; elif cat "$EXPORT_FILE" | grep "$error_code_name" | grep -q ": MINOR:"; then echo -e "\e[33m"; else echo -e "\e[32m"; fi)
                if [ $error_code_count -gt 0 ]; then
                    if cat "$EXPORT_FILE" | grep "$error_code_name" | grep -q ": $error_type:"; then
                        echo -e "$error_color$error_code_name\e[0m: $(echo "$error_code_description" | sed -e "s/\\\\n/ /g")"
                        grep "$error_code_name" "$EXPORT_FILE" | sed -e "s/^/    /" | cut -d':' -f1,2
                    fi
                fi
            done
        done
    else
        echo -e "\e[32mNo coding style error reported\e[0m"
    fi
else
    help
fi
