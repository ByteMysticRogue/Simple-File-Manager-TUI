#!/bin/bash


# check if dialog is installed or not

dialog_location=$(which dialog)

if [[ -z $dialog_location ]]; then
    echo 'dialog is not installed on system.'
    apt install dialog -y
else
    echo "dialog is installed on system."
fi

org_dir=$(pwd)
script_dir=$(dirname "$0")

# check if log file exist or not
if [[ -e SFMT.log ]]; then
    :
else
    # creating Log file
    echo "$(date +'%Y-%m-%d - %H:%M:%S') Log File Created Succesfully." >> $org_dir/SFMT.log
fi

# directory list function
dir_only(){
    # extract all directories
    local dirs=$(find $script_dir -type d)
    
    # Prepare the list for dialog
    dir_list=()
    for dir in $dirs; do
        # off is the label for radiolist
        dir_list+=("$dir" "" off)
    done
    return_array=("${dir_list[@]}")
}

dirNfile() {
    # list all dirs and files
    local script_dir=$(dirname "$0")
    local all=$(find $script_dir -maxdepth 1)

    # Prepare the list for dialog
    all_list=()
    for fd in $all; do
        # off is the label for radiolist
        all_list+=("$fd" "" off)
    done
    return_arr=("${all_list[@]}")
}

writableFiles() {
    local script_dir=$(dirname "$0")
    all_files=$(find "$(dirname "$0")" -type f ! \( -name "*.png" -o -name "*.img" \) -writable)
    writable_files=()

    for item in $all_files; do
        writable_files+=("$item" "" off)
    done
    arr=("${writable_files[@]}")
}

# To capture the result, use a nameref
capture_array() {
    local array_name=$1[@]
    local -n _result=$2
    _result=("${!array_name}")
}


while true; do
    menu_option=$(dialog --title "SIMPLE FILE MANAGER TUI" --menu "Operations " 0 0 0 \
        1 "Create a file" \
        2 "Create a Directory" \
        3 "Delete (Directory|File)" \
        4 "Search (Directory|File)" \
        5 "Rename (Directory|File)" \
        6 "Edit a file" \
        7 "Show File Content" \
        3>&1 1>&2 2>&3 3>&-)

    if [[ $? -eq 1 ]]; then
        echo "Exit."
        exit 0
    else
        # directory list function result
        declare -a dir_result
        dir_only
        capture_array return_array dir_result

        # directory and file list function result
        declare -a dirNfile_result
        dirNfile
        capture_array return_arr dirNfile_result

        declare -a writable_result
        writableFiles
        capture_array arr writable_result

        case $menu_option in
        1 )
            while true; do
                # Show directories in dialog
                selected_dir=$(dialog --title "Select Directory" --radiolist "Choose a directory:" 0 0 0 "${dir_result[@]}" 3>&1 1>&2 2>&3 3>&-)
                
                if [[ $? -eq 0 ]]; then
                    if [[ -n "$selected_dir" ]]; then
                        cd "$selected_dir"
                        file_name=$(dialog --title "File Creation" --inputbox "Enter File Name:" 0 0 3>&1 1>&2 2>&3 3>&-)
                        if [[ $? -eq 0 ]]; then
                            if [[ -e "$file_name" ]]; then
                                dialog --msgbox 'File Already Exists.' 0 0
                                cd "$org_dir"
                            else
                                touch $file_name
                                dialog --msgbox "File Created Succesfully!" 0 0
                                cd "$org_dir"
                                break
                            fi
                        else
                            dialog --msgbox "Creation Canceled." 0 0
                            cd "$org_dir"
                            break
                        fi
                    else
                        dialog --msgbox "No Directory is Selected!" 0 0
                    fi
                else
                    dialog --msgbox "Operation Canceled." 0 0
                    break
                fi
            done
            ;;
        2 )
            while true; do
                # Show directories in dialog
                selected_dir=$(dialog --title "Select Directory" --radiolist "Choose a directory:" 0 0 0 "${dir_result[@]}" 3>&1 1>&2 2>&3 3>&-)

                if [[ $? -eq 0 ]]; then
                    if [[ -n "$selected_dir" ]]; then
                        cd "$selected_dir"
                        dir_name=$(dialog --title "Directory Creation" --inputbox "Enter Directory Name:" 0 0 3>&1 1>&2 2>&3 3>&-)
                        if [[ $? -eq 0 ]]; then
                            if [[ -e "$dir_name" ]]; then
                                dialog --msgbox 'Directory Already Exists.' 0 0
                                cd "$org_dir"
                            else
                                mkdir $dir_name
                                dialog --msgbox "Directory Created Succesfully!" 0 0
                                cd "$org_dir"
                                break
                            fi
                        else
                            dialog --msgbox "Creation Canceled." 0 0
                            cd "$org_dir"
                            break
                        fi
                    else
                        dialog --msgbox "No Directory is Selected!" 0 0
                    fi
                else
                    dialog --msgbox "Operation Canceled." 0 0
                    break
                fi
            done
            ;;
        3 )
            while true; do
                # Show directories in dialog
                selected_item=$(dialog --title "Select Directory" --radiolist "Choose a directory or File To Delete:" 0 0 0 "${dirNfile_result[@]}" 3>&1 1>&2 2>&3 3>&-)
                
                if [[ $? -eq 0 ]]; then
                    if [[ -n "$selected_item" ]]; then
                        # check if selected item is directory or not
                        if [[ -d "$selected_item" ]]; then
                            rm -rf $selected_item
                            dialog --msgbox "$selected_item Removed Succesfully." 0 0
                            break
                        else
                            rm $selected_item
                            dialog --msgbox "$selected_item Removed Succesfully." 0 0
                            break
                        fi
                    else
                        dialog --msgbox "No Directory or File is Selected!" 0 0
                    fi
                else
                    dialog --msgbox "Operation Canceled." 0 0
                    break
                fi
            done
            ;;
        4 )
            while true; do
                search_item=$(dialog --inputbox "Enter Directory or File Name to search:" 0 0 3>&1 1>&2 2>&3 3>&-)

                if [[ $? -eq 0 ]]; then
                    if [[ -n $search_item ]]; then
                        path=$(find $script_dir -iname $search_item)
                        dialog --msgbox "Path is: $path" 0 0
                        break
                    else
                        dialog --msgbox "Input Can't Be Empty!" 0 0
                    fi
                else
                    dialog --msgbox "Operation Canceled." 0 0
                    break
                fi
            done
            ;;
        5 )
            while true; do
                # Show directories in dialog
                selected_item=$(dialog --title "Select Directory" --radiolist "Choose a directory or File To Delete:" 0 0 0 "${dirNfile_result[@]}" 3>&1 1>&2 2>&3 3>&-)
                
                if [[ $? -eq 0 ]]; then
                    if [[ -n "$selected_item" ]]; then
                        # check if selected item is directory or not
                        if [[ -d "$selected_item" ]]; then
                            new_dir_name=$(dialog --inputbox "Enter New Name: " 0 0 3>&1 1>&2 2>&3 3>&-)
                            mv $selected_item $new_dir_name
                            dialog --msgbox "$selected_item Renamed Succesfully." 0 0
                            break
                        else
                            new_file_name=$(dialog --inputbox "Enter New Name: " 0 0 3>&1 1>&2 2>&3 3>&-)
                            mv $selected_item $new_file_name
                            dialog --msgbox "$selected_item Renamed Succesfully." 0 0
                            break
                        fi
                    else
                        dialog --msgbox "No Directory or File is Selected!" 0 0
                    fi
                else
                    dialog --msgbox "Operation Canceled." 0 0
                    break
                fi
            done
            ;;
        
        6 )
            while true; do
                selected_file=$(dialog --title "Select Directory" --radiolist "Choose a file:" 0 0 0 "${writable_result[@]}" 3>&1 1>&2 2>&3 3>&-)
                
                if [[ $? -eq 0 ]]; then
                    if [[ -n "$selected_file" ]]; then
                        nano "$selected_file"
                        dialog --msgbox "File Edited Successfully." 0 0
                        break
                    else
                        dialog --msgbox "You didn't Select a file." 0 0
                    fi
                else
                    dialog --msgbox "Operation Canceled!" 0 0
                    break
                fi
            done
            ;;
        7 )
            while true; do
                selected_file=$(dialog --title "Select Directory" --radiolist "Choose a file:" 0 0 0 "${writable_result[@]}" 3>&1 1>&2 2>&3 3>&-)

                if [[ $? -eq 0 ]]; then
                    if [[ -n "$selected_file" ]]; then
                        dialog --textbox "$selected_file" 0 0
                        break
                    else
                        dialog --msgbox "You didn't Select a file." 0 0
                    fi
                else
                    dialog --msgbox "Operation Canceled!" 0 0
                    break
                fi
            done
            ;;
        esac
    fi
done