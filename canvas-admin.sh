#!/bin/bash

# Constants
DEFAULT_LOG_DIR="${HOME}/Canvas/logs/"
GITHUB_SCRIPT_URL="https://raw.githubusercontent.com/greatkemo/canvas-admin4/main/canvas-admin.sh"
CONF_FILE="${HOME}/Canvas/conf/canvas.conf"


log() {
  # This function is used to log messages to the console and to a log file
  # Usage: log <log_level> <message>
  # Example: log "info" "This is an info message"
  # Example: log "warn" "This is a warning message"
  # Example: log "error" "This is an error message"
  # Example: log "debug" "This is a debug message"
  
  # Define the log level and message
  log_level="$1"
  message="$2"
  # Define the timestamp
  timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  # Define the log output
  if [[ -z "${CANVAS_ADMIN_LOG}" ]]; then
    CANVAS_ADMIN_LOG="${DEFAULT_LOG_DIR}"
  fi
  # Define the log label and color
  case "$log_level" in
    info)
      log_label="INFO"
      log_color="\033[32m" # Green
      ;;
    warn)
      log_label="WARN"
      log_color="\033[33m" # Yellow
      ;;
    error)
      log_label="ERROR"
      log_color="\033[31m" # Red
      ;;
    debug)
      log_label="DEBUG"
      log_color="\033[36m" # Cyan
      ;;
    *)
      echo "Invalid log level. Please use 'info', 'warn', 'error', or 'debug'." >&2
      exit 1
  esac
  # Check if the log directory exists
  if [[ ! -d "${CANVAS_ADMIN_LOG}" ]]; then
    mkdir -p "${CANVAS_ADMIN_LOG}" || { echo "Could not create log directory ${CANVAS_ADMIN_LOG}"; exit 1; }
  fi
  # Define the log output
  log_output="[$timestamp] [$log_label] $message"
  sleep 0.5
  if [ "$log_level" == "error" ]; then
    echo -e "${log_color}${log_output}\033[0m" | tee -a "${CANVAS_ADMIN_LOG}canvas-admin.log" >&2
  elif [ "$log_level" == "debug" ]; then
    echo -e "${log_color}${log_output}\033[0m" >> "${CANVAS_ADMIN_LOG}canvas-admin.log" # Only log debug messages to the log file, not to the console
  else
    echo -e "${log_color}${log_output}\033[0m" | tee -a "${CANVAS_ADMIN_LOG}canvas-admin.log"
  fi
}

prepare_environment() {
  log "info" "BEGIN: the function prepare_environment()..."
  # This function is used to prepare the environment for the canvas-admin.sh script
  local directories=("bin" "downloads" "tmp" "logs" "conf" "cache")
  local canvas_home="${HOME}/Canvas"
  local script_name="canvas-admin.sh"
  local script_path="${canvas_home}/bin/${script_name}"

  log "info" "Preparing environment..."
  # Create directories if they don't exist
  log "info" "Creating necessary directories..."
  
  for dir in "${directories[@]}"; do
    if mkdir -p "${canvas_home}/${dir}"; then
      log "info" "${canvas_home}/${dir} created successfully."
    else
      log "error" "Failed to create ${canvas_home}/${dir}."
    fi
  done
  log "info" "Directories created."
  # Check if canvas-admin.sh exists in the bin directory
  log "info" "Checking if canvas-admin.sh exists and is executable..."
  if [[ ! -f "$script_path" ]]; then
      log "info" "canvas-admin.sh not found. Attempting to download the latest version..."
      if curl --silent --fail -o "$script_path" "$GITHUB_SCRIPT_URL"; then
          log "info" "canvas-admin.sh downloaded successfully."
      else
          log "error" "Failed to download canvas-admin.sh. Check your internet connection and try again."
          exit 1
      fi
  fi
  # Now check if the script is executable
  if [[ ! -x "$script_path" ]]; then
      log "info" "canvas-admin.sh not executable. Attempting to make canvas-admin.sh executable..."
      if chmod +x "$script_path"; then
          log "info" "canvas-admin.sh is now executable."
      else
          log "error" "Failed to make canvas-admin.sh executable. Check your file permissions."
          exit 1
      fi
  else
      log "info" "canvas-admin.sh is already executable."
  fi
  # Check which SHELL is default and update it profile to include the PATH environment variable
  # Check if the ${HOME}/bin directory is in the user PATH environment variable
  if [[ ! -d "${HOME}/bin" ]]; then
      log "warn" "${HOME}/bin directory does not exit. Creating it..."
      mkdir -p "${HOME}/bin"
  fi
  if ! grep -q "${HOME}/bin" <<< "$PATH"; then
    detect_shell() {
      # This function is used to detect the user's shell and update the shell profile to include the ${HOME}/bin directory in the PATH environment variable
      if ! grep -q "${HOME}/bin" "${HOME}/.${1}rc"; then
        log "info" "Shell is ${1} updating .${1}rc with PATH..."
        # Check if the shell is bash, zsh, or ksh
        if [[ "$1" == "bash" ]] || [[ "$1" == "zsh" ]] || [[ "$1" == "ksh" ]]; then
          # Update .bashrc or .bash_profile for bash, zsh, or ksh
          if echo "export PATH=${HOME}/bin:\${PATH}" >> "${HOME}/.${1}rc"; then
            if source "${HOME}/.${1}rc" >/dev/null 2>&1; then
              log "info" "Reloaded .${1}rc"
            else
              log "error" "Failed to reload .${1}rc"
            fi
          else
            log "error" "Failed to update .${1}rc with PATH"
          fi
        elif [[ $1 == "csh" ]] || [[ $1 == "tcsh" ]]; then
          # Update .cshrc or .tcshrc for csh or tcsh
          if echo "setenv PATH=${HOME}/bin:\${PATH}" >> "${HOME}/.${1}rc"; then
            if source "${HOME}/.${1}rc" >/dev/null 2>&1; then
              log "info" "Reloaded .${1}rc"
            else
              log "error" "Failed to reload .${1}rc"
            fi
          else
            log "error" "Failed to update .${1}rc with PATH"
          fi
        fi
      fi
    }
    case "$SHELL" in
        */bash)
          # Update .bashrc or .bash_profile for bash
          detect_shell 'bash'
        ;;
        */zsh)
          # Update .zshrc for zsh
          detect_shell 'zsh'
        ;;
        */csh)
          # Update .cshrc for csh
          detect_shell 'csh'
        ;;
        */tcsh)
          # Update .tcshrc for tcsh
          detect_shell 'tcsh'
        ;;
        */ksh)
          # Update .kshrc for ksh
          detect_shell 'ksh'
        ;;
        *)
          # Handle other shells or exit with a message
          log "error" "Unsupported shell detected. Please manually add ${HOME}/bin to your PATH environment variable."
          exit 1
        ;;
    esac
  fi
 
  # Check if there is a bin directory in user home
  log "info" "Checking for ${HOME}/bin directory..."
  if [[ -d "${HOME}/bin" ]]; then
    log "info" "Found ${HOME}/bin. Attempting to create symbolic link for canvas-admin.sh..."
    # Try to unlink the old symlink, if it exists.
    if unlink "${HOME}/bin/canvas-admin" >/dev/null 2>&1; then
      log "info" "Removed old symbolic link at ${HOME}/bin/canvas-admin."
    else
      log "warn" "No symbolic link at ${HOME}/bin/canvas-admin to remove."
    fi
    # Try to create a new symlink.
    if ln -s "$script_path" "${HOME}/bin/canvas-admin"; then
      log "info" "Symbolic link created at ${HOME}/bin/canvas-admin."
    else
      log "error" "Failed to create symbolic link at ${HOME}/bin/canvas-admin. Check your file permissions."
      exit 1
    fi
  else
    log "error" "${HOME}/bin directory does not exist. Cannot create symbolic link."
    exit 1
  fi
  log "info" "Environment prepared."
  log "info" "END: the function prepare_environment()."
}

generate_conf() {
  log "info" "BEGIN: the function generate_conf()..."
  # This function generates the canvas.conf configuration file
  log "info" "Canvas Configuration Starting..."
  # Define the configuration file path
  local path_conf_file="${HOME}/Canvas/conf/"
  local config_file="${path_conf_file}canvas.conf"
  if [[ ! -d "$path_conf_file" ]]; then
    mkdir -p "$path_conf_file"
  fi
  # Check if the configuration file exists
  if [[ ! -f "$config_file" ]]; then
    # Prompt the user to enter an API Access Token
    log "info" "The canvas.conf configuration file was not found. Creating a new configuration file..."
    log "info" "Please follow the instructions to generate an API Access Token:"
    log "info" "https://canvas.instructure.com/doc/api/file.oauth.html#manual-token-generation"
    read -rp "Enter your Canvas API Access Token: " entered_token
    # Prompt the user to enter the Canvas Institute URL
    log "info" "Please enter your Canvas Institute URL e.g. canvas.school.edu or school.instructure.com"
    read -rp "Enter your Canvas Institute URL: " entered_url
    # Fetch the root account ID    
    log "info" "Fetching accounts infomation..." 
    # Define the API endpoint to fetch the root account  
    api_endpoint="https://$entered_url/api/v1/accounts"
    # Perform the API request to fetch the root account
    if ! response=$(curl -s -X GET --fail "$api_endpoint" \
      -H "Authorization: Bearer $entered_token" \
      -H "Content-Type: application/json"); then
      log "error" "Failed to fetch data from the Canvas API."
      exit 1
    fi
    # Check if the response is valid JSON
    if ! echo "$response" | jq . >/dev/null 2>&1; then
      log "error" "Invalid JSON response from the Canvas API."
      exit 1
    fi
    # Extract the root account ID from the response
    detected_root_account_id=$(echo "$response" | jq '[.[] | select(.root_account_id == null)] | if length > 0 then .[0].id else .[0].root_account_id end')
    # Get the Canvas root account ID
    if ! [[ "$detected_root_account_id" =~ ^[0-9]+$ ]]; then
      log "error" "Failed to fetch the root account. Response: $response"
      exit 1
    else
      log "info" "The detected root account ID is ($detected_root_account_id)."
    fi

    log "info" "Fetching and listing available accounts..."
    # Parse the response and print the accounts
    log "info" "Available accounts: (use the ID number to set the account)"
    echo "$response" | jq -r '.[] | "ID: \(.id) | Name: \(.name) | Time Zone: \(.default_time_zone)"'
    read -rp "Enter your Canvas account ID or leave it blank to use the root account ID ($detected_root_account_id): " entered_account_id
    if [[ -n "$entered_account_id" ]]; then
      detected_account_id="$entered_account_id"
    else
      detected_account_id="$detected_root_account_id"
    fi
    # Find the account with the entered account ID and set the institution name and time zone
    account_info=$(echo "$response" | jq -c --arg id "$detected_account_id" '.[] | select(.id | tostring == $id)')
    if [[ -n "$account_info" ]]; then
      detected_institution_name=$(echo "$account_info" | jq -r '.name')
      detected_time_zone=$(echo "$account_info" | jq -r '.default_time_zone')
    else
      log "error" "No account found with the ID: $detected_account_id. Using the root account's information instead."
      detected_institution_name=$(echo "$response" | jq -r '.[0].name')
      detected_time_zone=$(echo "$response" | jq -r '.[0].default_time_zone')
    fi
    # Prompt the user to confirm or modify the institution name
    log "info" "Detecting the name of your institute..."
    read -rp "Detected Institution Name is $detected_institution_name. Press Enter to accept, or type a new name: " entered_institution_name
    if [[ -n "$entered_institution_name" ]]; then
      detected_institution_name="$entered_institution_name"
    fi
    # Prompt the user to confirm or modify the institution abbreviation
    log "info" "Detecting the abbreviation of your institute name..."
    log "info" "This abbreviation is used for integration with other services such as Zoom, Box, Redshelf etc."
    detected_institute_abbreviation=$(echo "$detected_institution_name" | awk -F' ' '{ for (i=1; i<=NF; ++i) printf substr($i, 1, 1) }' | tr '[:upper:]' '[:lower:]')
    read -rp "Detected istitute abbreviation is ($detected_institute_abbreviation). Press Enter to accept, or type a different abbreviation: " entered_institute_abbreviation
    if [[ -n "$entered_institute_abbreviation" ]]; then
      detected_institute_abbreviation="$entered_institute_abbreviation"
    fi
    # Prompt the user to confirm or modify the time zone
    log "info" "Detecting institue default timezone based on Canvas account..."
    log "info" "This timezone is used for scheduling courses and other events."
    read -rp "Detected Time Zone is $detected_time_zone. Press Enter to accept, or type a new timezone: " entered_time_zone
    if [[ -n "$entered_time_zone" ]]; then
      detected_time_zone="$entered_time_zone"
    fi
    # Save the access token and institute URL in the configuration file
      log "info" "Canvas Configuration Starting..."
  
    # Define the configuration file path
    CONF_FILE="${HOME}/Canvas/conf/canvas.conf"

    # Check if the configuration file exists
    if [[ -f "$CONF_FILE" ]]; then
      log "warn" "The canvas.conf configuration file already exists. Overwriting it will erase the existing configuration."

      # Prompt the user for confirmation before overwriting the file
      while true; do
        read -rp "Are you sure you want to overwrite the existing configuration file? (y/n) " yn
        case $yn in
          [Yy]* ) break;;
          [Nn]* ) return 1;;
          * ) log "error" "Please answer yes (y) or no (n).";;
        esac
      done
    fi    
    echo "CANVAS_ACCESS_TOKEN=\"$entered_token\"" > "$CONF_FILE"
    {

      echo "CANVAS_INSTITUTE_URL=\"https://$entered_url/api/v1\""
      echo "CANVAS_ROOT_ACCOUNT_ID=\"$detected_root_account_id\""
      echo "CANVAS_ACCOUNT_ID=\"$detected_account_id\""
      echo "CANVAS_INSTITUTE_NAME=\"$detected_institution_name\""
      echo "CANVAS_INSTITUTE_ABBREVIATION=\"$detected_institute_abbreviation\""
      echo "CANVAS_DEFAULT_TIMEZONE=\"$detected_time_zone\""
      echo "CANVAS_ADMIN_HOME=\"${HOME}/Canvas/\""
      echo "CANVAS_ADMIN_CONF=\"${HOME}/Canvas/conf/\""
      echo "CANVAS_ADMIN_LOG=\"${HOME}/Canvas/logs/\""
      echo "CANVAS_ADMIN_DL=\"${HOME}/Canvas/downloads/\""
      echo "CANVAS_ADMIN_TMP=\"${HOME}/Canvas/tmp/\""
      echo "CANVAS_ADMIN_BIN=\"${HOME}/Canvas/bin/\""
      echo "CANVAS_ADMIN_CACHE=\"${HOME}/Canvas/cache/\""

    } >> "$CONF_FILE"
    chmod 600 "$CONF_FILE"

    log "info" "Access token, Institute URL, Account ID, School Name, and Time Zone saved in the configuration file."
  fi
  log "info" "END: the function generate_conf()."
}

validate_setup() {
  log "info" "BEGIN: the function validate_setup()..."
  # This function is used to validate the Canvas Admin setup
  log "info" "Validating Canvas Admin setup..."
  # Check if the configuration file exists and contains the required variables
  if [[ ! -f "$CONF_FILE" ]]; then
    log "error" "Configuration file (canvas.conf) is missing. Expected path: $CONF_FILE"
    return 1
  else
    log "info" "Configuration file (canvas.conf) found."
    # Load the configuration file
    source "$CONF_FILE"
  fi
  if [[ -z "$CANVAS_ACCESS_TOKEN" ]] || [[ -z "$CANVAS_INSTITUTE_URL" ]] \
    || [[ -z "$CANVAS_ROOT_ACCOUNT_ID" ]] || [[ -z "$CANVAS_ACCOUNT_ID" ]] \
    || [[ -z "$CANVAS_INSTITUTE_NAME" ]] || [[ -z "$CANVAS_INSTITUTE_ABBREVIATION" ]] \
    || [[ -z "$CANVAS_DEFAULT_TIMEZONE" ]] || [[ -z "$CANVAS_ADMIN_HOME" ]] \
    || [[ -z "$CANVAS_ADMIN_CONF" ]] || [[ -z "$CANVAS_ADMIN_LOG" ]] \
    || [[ -z "$CANVAS_ADMIN_DL" ]] || [[ -z "$CANVAS_ADMIN_TMP" ]] \
    || [[ -z "$CANVAS_ADMIN_BIN" ]]|| [[ -z "$CANVAS_ADMIN_CACHE" ]]; then
    log "error" "Required variables are missing or incorrect in the configuration file (canvas.conf)."
    return 1
  else
    log "info" "Required variables found and validated in the configuration file (canvas.conf)."
  fi
  # Check if the necessary directories exist
  for dir in "${CANVAS_ADMIN_HOME}" "${CANVAS_ADMIN_BIN}" \
              "${CANVAS_ADMIN_DL}" "${CANVAS_ADMIN_TMP}" \
              "${CANVAS_ADMIN_LOG}" "${CANVAS_ADMIN_CONF}" \
              "${CANVAS_ADMIN_CACHE}"; do
    if [[ ! -d "$dir" ]]; then
      log "error" "Required directory $dir is missing or incorrect in the Canvas Admin setup."
      return 1
    else 
      log "info" "Required directory $dir found and validated."
    fi
  done
  log "info" "Directories validation completed successfully."
  # Check if the necessary files exist and if canvas-admin.sh exists and is executable
  if [ ! -x "${CANVAS_ADMIN_BIN}canvas-admin.sh" ]; then
    log "error" "canvas-admin.sh is missing or not executable in the Canvas Admin setup. Expected path: ${CANVAS_ADMIN_BIN}canvas-admin.sh"
    return 1
  else
    log "info" "canvas-admin.sh found and validated as executable by the current user."
  fi
  # If all checks passed, create the .done file
  touch "${CANVAS_ADMIN_HOME}.done"
  log "info" "Canvas Admin setup validation completed successfully."
  log "info" "END: the function validate_setup()."
  return 0
}

check_for_updates() {
  log "info" "BEGIN: the function check_for_updates()..."
  # This function checks for updates to the script and prompts the user to update if a new version is available
  local force_update=false
  local auto_confirm=false

  # Process arguments
  for arg in "$@"; do
    case $arg in
      -force)
        force_update=true
        ;;
      -y)
        auto_confirm=true
        ;;
      *)
        log "error" "Unknown argument: $arg"
        return 1
        ;;
    esac
  done

  # Load the configuration file
  source "$CONF_FILE"

  log "info" "Checking for updates to canvas-admin.sh..."
  # Download the remote script into the tmp directory
  log "info" "Downloading remote script for comparison..."
  if ! curl --fail -s -o "${CANVAS_ADMIN_TMP}canvas-admin.sh" "$GITHUB_SCRIPT_URL"; then
    log "error" "Failed to download the script from $GITHUB_SCRIPT_URL. Please check your network connection or the availability of the server."
    return 1
  fi
  # Check if the downloaded script is different from the local script or if force update is enabled
  if $force_update || ! cmp -s "${CANVAS_ADMIN_TMP}canvas-admin.sh" "${CANVAS_ADMIN_BIN}canvas-admin.sh"; then
    log "info" "A new version of canvas-admin.sh has been detected."
    # Prompt the user to update
    update_choice="n"
    if $auto_confirm; then
      update_choice="y"
    else
      read -rp "A new version of canvas-admin.sh is available. Do you want to update? [Y/n]: " update_choice
    fi

    if [[ "$update_choice" =~ ^[Yy]$|^$ ]]; then
      # Update the local script
      log "info" "Updating canvas-admin.sh to the latest version..."
      mv "${CANVAS_ADMIN_TMP}canvas-admin.sh" "${CANVAS_ADMIN_BIN}canvas-admin.sh"
      chmod +x "${CANVAS_ADMIN_BIN}canvas-admin.sh"
      log "info" "canvas-admin.sh has been successfully updated to the latest version."
    else
      log "info" "Update skipped by user."
    fi
  else
    log "info" "canvas-admin.sh is already up-to-date. No update required."
  fi

  # Clean up the tmp directory
  log "info" "Cleaning up temporary files..."
  rm -f "${CANVAS_ADMIN_TMP}canvas-admin.sh"
  log "info" "Temporary files cleaned up."
  log "info" "END: the function check_for_updates()."
}

download_all_teachers() {
  # This function downloads all teachers from Canvas and outputs them to a CSV file
  # Load the configuration file
  source "$CONF_FILE"

  log "info" "BEGIN: the function download_all_teachers()..."
  
  local page=1
  local per_page=100
  local total_teachers=0
  local teacher_role_id

  # Fetch the teacher role ID from the API
  log "info" "Fetching teacher role ID from API. ${CANVAS_INSTITUTE_URL}/accounts/${CANVAS_ACCOUNT_ID}/roles"
  response=$(curl -sS -X GET "${CANVAS_INSTITUTE_URL}/accounts/${CANVAS_ACCOUNT_ID}/roles" \
    -H "Authorization: Bearer ${CANVAS_ACCESS_TOKEN}" -H "Content-Type: application/json")
  log "debug" "Role response: $response"
  teacher_role_id=$(echo "$response" | jq -r '.[] | select(.label == "Teacher") | .id')
  log "debug" "Teacher role ID: $teacher_role_id"

  # Create the CSV file
  echo "\"canvas_user_id\",\"user_id\",\"login_id\",\"full_name\",\"email\"" > "${CANVAS_ADMIN_CACHE}user_directory.csv"

  # User prompt
  while true; do
    read -rp "This will download the details of all teachers. Do you want to proceed? (y/n): " confirm
    case $confirm in
      [Yy]* ) break;;
      [Nn]* ) return 1;;
      * ) log "info" "Aborting the download." && return 0;;
    esac
  done
  while true; do
    log "info" "Fetching page $page from API..."

    # Fetch the users from the API
    response=$(curl -sS -X GET "${CANVAS_INSTITUTE_URL}/accounts/${CANVAS_ACCOUNT_ID}/users" \
      -H "Authorization: Bearer ${CANVAS_ACCESS_TOKEN}" -H "Content-Type: application/json" \
      -G --data-urlencode "per_page=$per_page" --data-urlencode "page=$page" \
      --data-urlencode "role_filter_id=$teacher_role_id" --data-urlencode "include[]=canvas_user_id" \
      --data-urlencode "include[]=user_id" --data-urlencode "include[]=login_id" \
      --data-urlencode "include[]=full_name" --data-urlencode "include[]=sortable_name" \
      --data-urlencode "include[]=short_name" --data-urlencode "include[]=email" --fail)
    log "debug" "Page $page response: $response"

    # Check if the response is empty
    if [[ -z "$response" ]]; then
      log "warn" "No response received for page $page. Skipping..."
      break
    else
      log "debug" "Setting total_teachers_on_page.."
      total_teachers_on_page=$(echo "$response" | jq -r 'length')
      log "debug" "total_teachers_on_page: $total_teachers_on_page"
      if [[ "$total_teachers_on_page" -eq 0 ]]; then
        log "info" "No teachers found on page $page. Stopping iteration."
        break
      fi
      log "debug" "Setting total_teachers.."
      total_teachers=$((total_teachers + total_teachers_on_page))
      log "debug" "total_teachers: $total_teachers"
      log "debug" "Writing to CSV file.."
      echo "$response" | jq -r '.[] | [.id, .sis_user_id, .login_id, .name, .email] | @csv' >> "${CANVAS_ADMIN_CACHE}user_directory.csv"
      log "debug" "CSV file written to."
      log "info" "Page $page downloaded. $total_teachers teachers downloaded so far."
      page=$((page + 1))
    fi
  done

  log "info" "Downloaded details of $total_teachers teachers to ${CANVAS_ADMIN_CACHE}user_directory.csv"
  log "info" "END: the function download_all_teachers()."
}

input_user_search() {
  # This function searches for users based on the search pattern and saves the results in a CSV file
  source "$CONF_FILE"
  
  log "info" "BEGIN: the function input_user_search()..."
  
  local search_pattern="$1"
  local output_file="${3:-${CANVAS_ADMIN_DL}user_search-$(date '+%d-%m-%Y_%H-%M-%S').csv}"

  local response
  local lastname
  local firstname
  local cached_user
  local user_in_cache=""
  
  local api_endpoint="${CANVAS_INSTITUTE_URL}/accounts/$CANVAS_ACCOUNT_ID/users"
  local cache_file="${CANVAS_ADMIN_CACHE}user_directory.csv"

  log "info" "Initiating user search with pattern: $search_pattern"
  # Check if the search pattern contains a comma
  log "debug" "Checking if the search pattern contains a comma..."
  if [[ $search_pattern == *,* ]]; then
    log "debug" "Search pattern contains a comma."
    # If yes, split the search pattern into first name and last name
    log "debug" "Splitting the search pattern into first name and last name..."
    lastname=$(echo "$search_pattern" | cut -d ',' -f 1 | xargs) # xargs is used to trim leading/trailing spaces
    firstname=$(echo "$search_pattern" | cut -d ',' -f 2 | xargs) # xargs is used to trim leading/trailing spaces
    # Update the search pattern to "Firstname Lastname" format
    search_pattern="${firstname} ${lastname}" 
    log "debug" "Search pattern updated to: $search_pattern"
  fi
      # Check if the cache file exists
    log "debug" "Checking if the cache file exists..."
    if [[ -f "$cache_file" ]]; then
      log "debug" "Cache file exists." 
      # If yes, check if the user is in the cache
      log "debug" "Checking if the user is in the cache..."
      cached_user=$(grep -i "$search_pattern" "$cache_file")

      if [[ -n "$cached_user" ]]; then
        # If the user is in the cache, use the cached data
        log "debug" "User found in the cache."
        user_in_cache="true"
        response="$cached_user"
      else
        user_in_cache="false"
        # If the user is not in the cache, perform the API request
        log "debug" "User not found in the cache."
        # Perform the API request to search for user(s)
        log "debug" "Sending API request to search for user..."
        response=$(curl -sS -X GET "$api_endpoint" \
          -H "Authorization: Bearer ${CANVAS_ACCESS_TOKEN}" \
          -H "Content-Type: application/json" \
          -G --data-urlencode "search_term=$search_pattern" \
          --data-urlencode "include[]=email")
      fi
    fi
    # If the user is not in the cache (or the cache file does not exist), perform the API request
    # Check if the response is empty
    log "debug" "Checking if the response is empty..."
    log "debug" "Response: $response"

    if [[ -z "$response" ]] || [[ "$response" == "[]" ]]; then
      log "warn" "No users found matching the pattern: $search_pattern"
      return
    fi
    if [[ "$user_in_cache" == "false" ]]; then
      # If the user is not in the cache, update the cache file
      log "debug" "Updating the cache file..."
      echo "$response" | jq -r '.[] | [.id, .sis_user_id, .login_id, .name, .email] | @csv' >> "$cache_file"
    fi

  # Display the search results
  if [[ "$user_in_cache" == "true" ]]; then
    log "info" "User search results (from cache):"
    awk 'BEGIN { FS=","; OFS=": " } \
     { gsub(/"/, "", $1); 
      gsub(/"/, "", $2); 
      gsub(/"/, "", $3); 
      gsub(/"/, "", $4); 
      gsub(/"/, "", $5); 
      print "CANVAS_USER_ID", $1; 
      print "USER_ID", $2; 
      print "LOGIN_ID", $3; 
      print "FULL_NAME", $4; 
      print "EMAIL", $5; print "" }' <<< "$response"
  else
    log "info" "User search results (from API):"
    echo "$response" | jq -r '.[] | "CANVAS_USER_ID: \(.id)\nUSER_ID: \(.sis_user_id)\nLOGIN_ID: \(.login_id)\nFULL_NAME: \(.name)\nEMAIL: \(.email)\n"'
  fi

  # Prompt for download
  while true; do
    read -rp "Would you like to download the CSV file? (y/n) " yn
    case $yn in
      [Yy]* )
        # Download the CSV file
        # Parse the response and create the CSV file
        log "info" "Parsing response and generating CSV file..."
        echo "\"canvas_user_id\",\"user_id\",\"login_id\",\"full_name\",\"email\"" > "$output_file"
        if [[ "$user_in_cache" == "true" ]]; then
          log "debug" "User found in cache."
          echo "$response" >> "$output_file"
        else
          log "debug" "User not found in cache. Using API data."
          echo "$response" | jq -r '.[] | [.id, .sis_user_id, .login_id, .name, .email] | @csv' >> "$output_file"
        fi 
        log "info" "You can download the CSV file from: $output_file"
        break
        ;;
      [Nn]* ) 
        log "info" "Okay, the CSV file won't be downloaded."
        break
        ;;
      * ) log "error" "Please answer yes (y) or no (n).";;
    esac
  done
  log "info" "END: the function input_user_search()."
}

file_user_search() {
  # This function searches for users based on an input file and saves the results in a CSV file
  
  source "$CONF_FILE"
  log "info" "BEGIN: the function file_user_search()..."
  local input_file="$1"
  log "debug" "Input file: $input_file"
  local output_file="${3:-${CANVAS_ADMIN_DL}user_search-$(date '+%d-%m-%Y_%H-%M-%S').csv}"
  log "debug" "Output file: $output_file"
  local response
  local lastname
  local firstname
  local cached_user
  local user_in_cache=""
  # Get the total number of lines in the input file
  local total_lines

  log "debug" "Getting the total number of lines in the input file..."
  total_lines=$(wc -l < "$input_file")
  log "debug" "Total number of lines in the input file: $total_lines"
  # Initialize the current line number
  log "debug" "Initializing the current line number..."
  local current_line=1
  # Calculate the number of digits in total_lines
  local num_digits=${#total_lines}
  log "debug" "Number of digits in total_lines: $num_digits"
  local api_endpoint="${CANVAS_INSTITUTE_URL}/accounts/$CANVAS_ACCOUNT_ID/users"
  log "debug" "API endpoint: $api_endpoint"
  local cache_file="${CANVAS_ADMIN_CACHE}user_directory.csv"
  log "debug" "Cache file: $cache_file"
  local user_in_cache="false"

  # Define a function to pad a number with leading zeros
  pad_number() {
    local number=$1
    local total_digits=$2
    printf "%0${total_digits}d" "$number" 2>/dev/null || printf "%s" "$number"
  }
  
  # Parse the response and create the CSV file
  log "info" "Parsing response and generating CSV file..."
  echo "\"canvas_user_id\",\"user_id\",\"login_id\",\"full_name\",\"email\"" > "$output_file"
  # Process each search pattern
  log "info" "Processing each search pattern..."
  while read -r search_pattern; do
    # Clear the response variable
    log "debug" "Clearing the response variable..."
    response=""
    log "debug" "Processing search pattern: $search_pattern"
    # Check if the search pattern contains a comma
    log "debug" "Checking if the search pattern contains a comma..."
    # Skip if line starts with a hash (#) character of if it is empty
    [[ -z "${search_pattern// }" || "$search_pattern" =~ ^\#.*$ ]] && continue
    if [[ $search_pattern == *,* ]]; then
      log "debug" "Search pattern contains a comma."
      # If yes, split the search pattern into first name and last name
      log "debug" "Splitting the search pattern into first name and last name..."
      lastname=$(echo "$search_pattern" | cut -d ',' -f 1 | xargs) # xargs is used to trim leading/trailing spaces
      firstname=$(echo "$search_pattern" | cut -d ',' -f 2 | xargs) # xargs is used to trim leading/trailing spaces
      # Update the search pattern to "Firstname Lastname" format
      search_pattern="${firstname} ${lastname}" 
      log "debug" "Search pattern updated to: $search_pattern"
    fi
    # Pad the search_pattern to a width of 30 with trailing spaces
    #printf -v line_padded "%-40s" "$search_pattern"
    
    # Then, use the pad_number function when padding current_line and total_lines
    current_line_padded=$(pad_number "$current_line" "$num_digits")
    total_lines_padded=$(pad_number "$total_lines" "$num_digits")

    # Get the terminal width
    terminal_width=$(tput cols)

    # Calculate the length of the search pattern
    search_pattern_length=${#search_pattern}

    # Calculate the available width for padding
    padding_width=$((terminal_width - search_pattern_length - 75))  # Adjust the value '7' as per your requirement

    # Generate the padding string with dots and a space
    padding_dots=$(printf "%*s" "$((padding_width - 1))" "")
    padding_dots=${padding_dots// /.}
    line_padded="$search_pattern $padding_dots :($current_line_padded/$total_lines_padded)"

 # Check if the cache file exists
    log "debug" "Checking if the cache file exists..."
    if [[ -f "$cache_file" ]]; then
      log "debug" "Cache file exists." 
      # If yes, check if the user is in the cache
      log "debug" "Checking if the user is in the cache..."
      cached_user=$(grep -i "$search_pattern" "$cache_file")

      if [[ -n "$cached_user" ]]; then
        # If the user is in the cache, use the cached data
        log "debug" "User found in the cache."
        user_in_cache="true"
        response="$cached_user"
      else
        user_in_cache="false"
        # If the user is not in the cache, perform the API request
        log "debug" "User not found in the cache."
        # Perform the API request to search for user(s)
        log "debug" "Sending API request to search for user..."
        response=$(curl -sS -X GET "$api_endpoint" \
          -H "Authorization: Bearer ${CANVAS_ACCESS_TOKEN}" \
          -H "Content-Type: application/json" \
          -G --data-urlencode "search_term=$search_pattern" \
          --data-urlencode "include[]=email")
      fi
    fi
    # If the user is not in the cache (or the cache file does not exist), perform the API request
    # Check if the response is empty
    log "debug" "Checking if the response is empty..."
    log "debug" "Response: $response"

    if [[ -z "$response" ]] || [[ "$response" == "[]" ]]; then
      log "warn" "No users found matching the pattern: $search_pattern"
      return
    fi
    if [[ "$user_in_cache" == "false" ]]; then
      # If the user is not in the cache, update the cache file
      log "debug" "Updating the cache file..."
      echo "$response" | jq -r '.[] | [.id, .sis_user_id, .login_id, .name, .email] | @csv' >> "$cache_file"
    fi

    # Check if the response contains multiple results
    # Placeholder for statement to check for multiple results and prompt user to select one
    # enter the user's choice in the variable below

    # Display the current line number and the total number of lines
    log "info" "Finished processing: $line_padded"
    # Check if the user is in the cache
    if [[ "$user_in_cache" == "true" ]]; then
      log "debug" "User found in cache. Using cached data."
      echo "$response" >> "$output_file"
    else
      log "debug" "User not found in cache. Using API data."
      echo "$response" | jq -r '.[] | [.id, .sis_user_id, .login_id, .name, .email] | @csv' >> "$output_file"
    fi
    # Increment the current line number
    ((current_line++))
  done < "$input_file"

  # Prompt for download
  while true; do
    read -rp "Would you like to download the CSV file? (y/n) " yn
    case $yn in
      [Yy]* ) 
        log "info" "You can download the CSV file from: $output_file"
        break
        ;;
      [Nn]* ) 
        log "info" "Okay, the CSV file won't be downloaded."
        break
        ;;
      * ) log "error" "Please answer yes (y) or no (n).";;
    esac
  done
  log "info" "END: the function file_user_search()."
}

get_user_id() {
  search_pattern="$1"

  # Define the API endpoint for searching users
  api_endpoint="$CANVAS_INSTITUTE_URL/accounts/$CANVAS_ACCOUNT_ID/users"

  # Perform the API request to search for users
  response=$(curl -s -X GET "$api_endpoint" \
    -H "Authorization: Bearer $CANVAS_ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -G --data-urlencode "search_term=$search_pattern" \
    --data-urlencode "include[]=email" \
    --data-urlencode "include[]=enrollments")

  # Extract the user_id from the response
  user_id=$(echo "$response" | jq '.[0].id')

  echo "$user_id"
}

enroll_instructor() {
  course_id="$1"
  instructor_id="$2"

  # Define the API endpoint for enrolling an instructor in the course
  api_endpoint="$CANVAS_INSTITUTE_URL/courses/$course_id/enrollments"

  # Define the API request data
  api_data="{\"enrollment\": {\"user_id\": \"$instructor_id\", \"type\": \"TeacherEnrollment\", \"enrollment_state\": \"active\"}}"

  # Perform the API request to enroll the instructor
  log "info" "Sending API request to enroll instructor (ID: $instructor_id) in course (ID: $course_id)..."
  response=$(curl -s -X POST "$api_endpoint" \
    -H "Authorization: Bearer $CANVAS_ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$api_data")

  # Log the API response
  log "info" "API response: $response"

  log "info" "Instructor (ID: $instructor_id) successfully enrolled in course (ID: $course_id)"
}

course_configuration() {
  validate_setup
  setting_type="$1"
  setting_value="$2"
  course_id="$3"

  log "info" "Initiating course settings update for course ID: $course_id"

  api_endpoint="$CANVAS_INSTITUTE_URL/courses/$course_id"

  case "$setting_type" in
    -timezone)
      # Set the course's IANA time zone
      api_data="{\"course\": {\"time_zone\": \"$setting_value\"}}"
      log "info" "Setting course time zone to: $setting_value"
      ;;
    -prefs)
      # Set the course's hide_distribution_graphs to true
      api_data="{\"course\": {\"hide_distribution_graphs\": true}}"
      log "info" "Hiding course distribution graphs"
      ;;
    -all)
      # Set the course's IANA time zone and hide_distribution_graphs
      api_data="{\"course\": {\"time_zone\": \"$setting_value\", \"hide_distribution_graphs\": true}}"
      log "info" "Setting course time zone to: $setting_value and hiding distribution graphs"
      ;;
    *)
      log "error" "Invalid setting type. Please use 'timezone', 'config', or 'all'."
      exit 1
  esac

  # Perform the API request to update course settings
  log "info" "Sending API request to update course settings..."
  curl -s -X PUT "$api_endpoint" \
    -H "Authorization: Bearer $CANVAS_ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$api_data"

  log "info" "Course settings successfully applied to course ID: $course_id"
}

course_books() {
  validate_setup
  book_type="$1"
  course_id="$2"

  log "info" "Initiating the process to add online textbook links to course ID: $course_id"

  # Create the "Online Textbooks" module
  api_endpoint="$CANVAS_INSTITUTE_URL/courses/$course_id/modules"
  module_data="{\"module\": {\"name\": \"Online Textbooks\"}}"

  log "info" "Creating 'Online Textbooks' module..."
  module_id=$(curl -s -X POST "$api_endpoint" \
    -H "Authorization: Bearer $CANVAS_ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$module_data" | jq -r '.id')

  log "info" "Successfully created 'Online Textbooks' module with ID: $module_id"

  # Define the API endpoint for adding items to the module
  api_endpoint="$CANVAS_INSTITUTE_URL/courses/$course_id/modules/$module_id/items"

  # Add external links to the module based on the book type
  case "$book_type" in
    -redshelf)
      book_title="RedShelf Inclusive"
      book_url="https://${CANVAS_INSTITUTE_SHORT_NAME}.redshelf.com/lti/my_courses/"
      ;;
    -vitalsource)
      book_title="VitalSource Course Materials"
      book_url="https://bc.vitalsource.com/books"
      ;;
    -all)
      course_books "redshelf" "$course_id"
      course_books "vitalsource" "$course_id"
      return
      ;;
    *)
      log "error" "Invalid book type. Please use 'redshelf', 'vitalsource', or 'all'."
      exit 1
  esac

  book_data="{\"module_item\": {\"title\": \"$book_title\", \"type\": \"ExternalTool\", \"external_url\": \"$book_url\", \"position\": 1, \"indent\": 1, \"new_tab\": false}}"

  log "info" "Adding '$book_title' link to the 'Online Textbooks' module..."
  # Perform the API request to add the external link to the module
  curl -s -X POST "$api_endpoint" \
    -H "Authorization: Bearer $CANVAS_ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$book_data"

  log "info" "Successfully added '$book_title' link to the 'Online Textbooks' module in course ID: $course_id"
}

get_term_id() {
  local term_query="$1"
  local api_endpoint="$CANVAS_INSTITUTE_URL/accounts/$CANVAS_ACCOUNT_ID/terms"
  local response

  response=$(curl -s -X GET "$api_endpoint" \
    -H "Authorization: Bearer $CANVAS_ACCESS_TOKEN" \
    -H "Content-Type: application/json")

  if ! echo "$response" | jq 'if type=="array" or type=="null" then true else false end' -e >/dev/null; then
    log "error" "Failed to fetch terms. Response: $response"
    return 1
  fi

  if [ "$(echo "$response" | jq '. | length')" -eq 0 ]; then
    log "error" "No terms found."
    return 1
  fi

  local term_id
  term_id=$(echo "$response" | jq -r --arg term_query "$term_query" '.[] | select(.name | test($term_query; "i")) | .id')

  if [ -z "$term_id" ]; then
    log "error" "No term found with the given search query."
    return 1
  fi

  echo "$term_id"
}

list_subaccounts() {
  # Define the API endpoint for fetching subaccounts
  source "$CONF_FILE"
  api_endpoint="$CANVAS_INSTITUTE_URL/accounts/$CANVAS_ACCOUNT_ID/sub_accounts"

  # Initialize variables
  subaccounts_exist=false

  # Perform the API request to fetch subaccounts

    log "info" "Fetching subaccounts..."
    response=$( curl -s -X GET "$api_endpoint" \
      -H "Authorization: Bearer $CANVAS_ACCESS_TOKEN" \
      -H "Content-Type: application/json" )
   
    # Check if the response is a valid JSON array
    if ! echo "$response" | jq 'if type=="array" then true else false end' -e >/dev/null; then
      log "error" "Failed to fetch subaccounts. Response: $response"
      exit 1
    fi

    # Error and Exit if the response is empty
    if [ "$response" == "[]" ]; then
      log "error" "Failed to fetch subaccounts. Response is empty."    
      exit 1
    fi

    # Set the flag to indicate that subaccounts exist
    subaccounts_exist=true

    # Parse the response and print the subaccounts
    log "info" "Available subaccounts: (use the ID number to set the subaccount)"
    echo "$response" | jq -r '.[] | "ID: \(.id) | Name: \(.name)"'

  if [ "$subaccounts_exist" = false ]; then
    log "info" "No subaccounts found."
  fi
}

create_single_course() {
  course_name="$1"
  course_code="$2"
  term_id="$3"
  sub_account_id="$4"
  instructor_id="$5"

  # Define the API endpoint for creating courses
  api_endpoint="$CANVAS_INSTITUTE_URL/accounts/${sub_account_id:-$CANVAS_ACCOUNT_ID}/courses"

  # Define the API request data
  api_data="{\"course\": {\"name\": \"$course_name\", \"course_code\": \"$course_code\""
  if [ -n "$term_id" ]; then
    api_data="$api_data, \"term_id\": $term_id"
  fi
  api_data="$api_data}}"

  # Perform the API request to create a course
  log "info" "Sending API request to create a new course..."
  response=$(curl -s -X POST "$api_endpoint" \
    -H "Authorization: Bearer $CANVAS_ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$api_data")

  # Extract the course ID from the response
  course_id=$(echo "$response" | jq '.id')

  log "info" "Course successfully created with ID: $course_id"

  # Enroll the instructor in the course, if an instructor ID is provided
  if [ -n "$instructor_id" ]; then
    enroll_instructor "$course_id" "$instructor_id"
  fi

  # Apply course_configuration -all function on the newly created course
  course_configuration "-all" "$CANVAS_DEFAULT_TIMEZONE" "$course_id"
}

create_course() {
  validate_setup
  csv_file="$1"

  if [ -n "$csv_file" ] && [ -f "$csv_file" ]; then
    first_line=1
    while IFS=, read -r course_name course_code term_id; do
      if [ $first_line -eq 1 ]; then
        first_line=0
        continue
      fi
      create_single_course "$course_name" "$course_code" "$term_id" "$sub_account_id" "$instructor_id"
    done < "$csv_file"
  else
    read -rp "Enter the course name: " course_name
    read -rp "Enter the course code: " course_code
    # Search for the term by name if the term_id is not provided
    read -rp "Enter the term name or partial name (optional): " term_query
    if [ -n "$term_query" ]; then
      term_id=$(get_term_id "$term_query")
        if [ -z "$term_id" ]; then
          log "error" "No term found with the given search query."
          exit 1
        fi
    else
      term_id=""
    fi

    list_subaccounts
    read -rp "Enter the sub-account ID (optional): " sub_account_id
    read -rp "Enter the instructor's name or email (optional): " instructor_query
    if [ -n "$instructor_query" ]; then
      instructor_id=$(get_user_id "$instructor_query")
      if [ -z "$instructor_id" ]; then
        log "error" "No user found with the given search query."
        exit 1
      fi
    fi
    create_single_course "$course_name" "$course_code" "$term_id" "$sub_account_id" "$instructor_id"
  fi
}

usage() {
  echo "Usage: ./canvas-admin.sh [options] [arg1] [arg2] [input]"
  echo ""
  echo "Options:"
  echo "help"
  echo "  Show this help message and exit."
  echo ""
  echo "update"
  echo "  Checks GitHub for updates to the canvas-admin.sh script and prompts the user to update."
  echo ""
  echo "usersearch"
  echo "  Search for users based on a search pattern and output their records to a CSV file."
  echo "  Format: ./canvas-admin.sh usersearch \"user search pattern\""
  echo "  Example: ./canvas-admin.sh usersearch \"john doe\""
  echo "  Example: ./canvas-admin.sh usersearch -file \"/path/to/file.txt\""
  echo "  Example: ./canvas-admin.sh usersearch -download # Downloads all users in the account to a CSV cache."
  echo ""
  echo "courseconfig"
  echo "  Apply settings to a course using the specified arguments."
  echo "  Format: ./canvas-admin.sh courseconfig [timezone|config|all] [arg1] [arg2] [course id]"
  echo "  Example: ./canvas-admin.sh courseconfig -timezone \"America/New_York\" 12345"
  echo "           ./canvas-admin.sh courseconfig -prefs 12345"
  echo "           ./canvas-admin.sh courseconfig -all \"America/New_York\" 12345"
  echo ""
  echo "books"
  echo "  Create a module called 'Online Textbooks' and add external links to the module based on the book type."
  echo "  Format: ./canvas-admin.sh books [redshelf|vitalsource|all] [course id]"
  echo "  Example: ./canvas-admin.sh books -redshelf 12345"
  echo "           ./canvas-admin.sh books -vitalsource 12345"
  echo "           ./canvas-admin.sh books -all 12345"
  echo ""
  echo "createcourse"
  echo "  Create a new course using user prompts or a CSV file as input."
  echo "  Format: ./canvas-admin.sh createcourse [input]"
  echo "  Example: ./canvas-admin.sh createcourse"
  echo "           ./canvas-admin.sh createcourse input.csv"
  echo ""
  echo "Please refer to the documentation for more information."
}

# Main script
# Call the necessary functions
if [[ ! -f "${HOME}/Canvas/.done" ]]; then
  # Prompt the user to install Canvas Admin if it is not installed
  log "info" "BEGIN: Canvas Admin Installtion and Configuration..."
  while true; do
    read -rp "Canvas Admin is either not installed or not configured correctly, Install now? (y/n) " yn
    case $yn in
      [Yy]* ) break;;
      [Nn]* ) return 1;;
      * ) log "error" "Please answer yes (y) or no (n).";;
    esac
  done
  prepare_environment && generate_conf && validate_setup
  log "info" "END: Canvas Admin Installtion and Configuration..."
fi

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    help) # show the usage message
      usage 
      exit 0
      ;;
    update) # check for updates
      shift
      if [[ "$1" = "-y" ]]; then
        if check_for_updates "-y"; then
          validate_setup
        fi
      elif [[ "$1" = "-force" ]]; then
        if check_for_updates "-force"; then
          validate_setup
        fi
      else
        if check_for_updates; then
          validate_setup
        fi
      fi
      exit 0
      ;;
    usersearch) # search for users
      shift
      if [[ "$1" == "-download" ]]; then
        validate_setup > /dev/null
        download_all_teachers # download all teachers in the account 
      elif [[ "$1" == "-file" ]]; then
        if [[ -z "$2" ]]; then
          log "error" "Missing input file. Please provide an input file path."
          exit 1
        fi
        validate_setup > /dev/null
        file_user_search "$2" # search for users using an input file
        shift
      else
        validate_setup > /dev/null
        input_user_search "$1" # search for users using a single input
      fi
      shift
      ;;

    createcourse) # create a new course
      shift
      if [[ -n "$1" ]] && [[ -f "$1" ]]; then
        validate_setup > /dev/null
        create_course "$1"
        shift
      else
        validate_setup > /dev/null
        create_course
      fi
      ;;
    courseconfig) # apply course configuration
      shift
      course_configuration "$1" "$2" "$3"
      shift 3
      ;;
    books) # add course books
      shift
      course_books "$1" "$2"
      shift 2
      ;;
    listsubaccounts) # lists all subaccounts in the Canvas instance
      list_subaccounts 
      exit 0
      ;;
    *) # unknown option
      log "error" "Unknown option: $1. Please try again."
      usage
      exit 1
      ;;
  esac
done




