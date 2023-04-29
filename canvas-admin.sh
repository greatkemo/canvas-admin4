#!/usr/bin/env bash

# constents
CANVAS_ADMIN_HOME="${HOME}/Canvas/"
CANVAS_ADMIN_CONF="${HOME}/Canvas/conf/"
CANVAS_ADMIN_LOG="${HOME}/Canvas/logs/"
CANVAS_ADMIN_DL="${HOME}/Canvas/Downloads/"
CANVAS_ADMIN_TMP="${HOME}/Canvas/tmp/"
CANVAS_ADMIN_BIN="${HOME}/Canvas/bin/"

config_file="${CANVAS_ADMIN_CONF}canvas.conf"

# Functions
log() {
    if [[ -e "${HOME}/Canvas/conf/canvas.conf" ]]; then
        CANVAS_ADMIN_CONF="${HOME}/Canvas/conf/"
        config_file="${CANVAS_ADMIN_CONF}canvas.conf"
        source "${config_file}"
    else
        mkdir -p "${HOME}/Canvas/logs/"
        CANVAS_ADMIN_LOG="${HOME}/Canvas/logs/"
    fi
  log_level="$1"
  message="$2"
  timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  
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
    *)
      echo "Invalid log level. Please use 'info', 'warn', or 'error'."
      exit 1
  esac
  
  log_output="[$timestamp] [$log_label] $message"
  sleep 0.5; echo -e "${log_color}${log_output}\033[0m" | tee -a "${CANVAS_ADMIN_LOG}canvas-admin.log"
}

prepare_environment() {
  log "info" "Preparing environment..."

  # Create directories if they don't exist
  log "info" "Creating necessary directories..."
  mkdir -p "${HOME}/Canvas/"
  mkdir -p "${HOME}/Canvas/bin/"
  mkdir -p "${HOME}/Canvas/Downloads/"
  mkdir -p "${HOME}/Canvas/tmp/"
  mkdir -p "${HOME}/Canvas/logs/"
  mkdir -p "${HOME}/Canvas/conf/"

  CANVAS_ADMIN_HOME="${HOME}/Canvas/"
  CANVAS_ADMIN_CONF="${HOME}/Canvas/conf/"
  CANVAS_ADMIN_LOG="${HOME}/Canvas/logs/"
  CANVAS_ADMIN_DL="${HOME}/Canvas/Downloads/"
  CANVAS_ADMIN_TMP="${HOME}/Canvas/tmp/"
  CANVAS_ADMIN_BIN="${HOME}/Canvas/bin/"

  log "info" "Directories created."

  # Define the URL for the remote script
  remote_script_url="https://raw.githubusercontent.com/greatkemo/canvas-admin4/main/canvas-admin.sh"

  # Check if canvas-admin.sh exists in the bin directory
  if [ ! -f "${CANVAS_ADMIN_BIN}canvas-admin.sh" ]; then
    log "info" "canvas-admin.sh not found. Downloading the latest version of canvas-admin.sh..."
    curl -s -o "${CANVAS_ADMIN_BIN}canvas-admin.sh" "$remote_script_url"
    log "info" "canvas-admin.sh downloaded successfully."
  fi

  # Check if canvas-admin.sh is executable
  if [ ! -x "${CANVAS_ADMIN_BIN}canvas-admin.sh" ]; then
    log "info" "canvas-admin.sh not executable. Making canvas-admin.sh executable..."
    chmod +x "${CANVAS_ADMIN_BIN}canvas-admin.sh"
    log "info" "canvas-admin.sh is now executable."
  fi

  # Check which SHELL is default and update it profile to include the PATH environment variable
  # Check if the ${HOME}/bin directory is in the user PATH environment variable
    if [[ ! -d "${HOME}/bin" ]]; then
        log "warn" "${HOME}/bin directory does not exit. Creating it..."
        mkdir -p "${HOME}/bin"
    fi
        if ! grep -q "${HOME}/bin" <<< "$PATH"; then
        case "$SHELL" in
            */bash)
            # Update .bashrc or .bash_profile for bash
            if ! grep -q "${HOME}/bin" "${HOME}/.bashrc"; then
                log "info" "Shell is $(basename ${SHELL}) updating .$(basename ${SHELL})rc with PATH..."
                echo "export PATH=${HOME}/bin:\${PATH}" >> "${HOME}/.bashrc"
                source "${HOME}/.bashrc" >/dev/null 2>&1
            fi
            ;;
            */zsh)
            # Update .zshrc for zsh
            if ! grep -q "${HOME}/bin" "${HOME}/.zshrc"; then
                log "info" "Shell is $(basename ${SHELL}) updating .$(basename ${SHELL})rc with PATH..."
                echo "export PATH=${HOME}/bin:\${PATH}" >> "${HOME}/.zshrc"
                source "${HOME}/.zshrc" >/dev/null 2>&1
            fi
            ;;
            */csh)
            # Update .cshrc for csh
            if ! grep -q "${HOME}/bin" "${HOME}/.cshrc"; then
                log "info" "Shell is $(basename ${SHELL}) updating .$(basename ${SHELL})rc with PATH..."
                echo "setenv PATH ${HOME}/bin:\${PATH}" >> "${HOME}/.cshrc"
                source "${HOME}/.cshrc" >/dev/null 2>&1
            fi
            ;;
            */tcsh)
            # Update .tcshrc for tcsh
            if ! grep -q "${HOME}/bin" "${HOME}/.tcshrc"; then
                log "info" "Shell is $(basename ${SHELL}) updating .$(basename ${SHELL})rc with PATH..."
                echo "setenv PATH ${HOME}/bin:\${PATH}" >> "${HOME}/.tcshrc"
                source "${HOME}/.tcshrc" >/dev/null 2>&1
            fi
            ;;
            */ksh)
            # Update .kshrc for ksh
            if ! grep -q "${HOME}/bin" "${HOME}/.kshrc"; then
                log "info" "Shell is $(basename ${SHELL}) updating .$(basename ${SHELL})rc with PATH..."
                echo "export PATH=${HOME}/bin:\${PATH}" >> "${HOME}/.kshrc"
                source "${HOME}/.kshrc" >/dev/null 2>&1
            fi
            ;;
            *)
            # Handle other shells or exit with a message
            log "error" "Unsupported shell detected. Please manually add ${HOME}/bin to your PATH environment variable."
            exit 1
            ;;
        esac
    fi
 
  # Check if there is a bin directory in user home
  log "info" "Creating symbolic link for canvas-admin.sh..."
  if [[ -d "${HOME}/bin" ]]; then
    unlink "${HOME}/bin/canvas-admin" >/dev/null 2>&1
    ln -s "${CANVAS_ADMIN_BIN}canvas-admin.sh" "${HOME}/bin/canvas-admin"
    log "info" "Symbolic link created in ${HOME}/bin/canvas-admin."
  else
    unlink "/usr/local/bin/canvas-admin" >/dev/null 2>&1
    ln -s "${CANVAS_ADMIN_BIN}canvas-admin.sh" "/usr/local/bin/canvas-admin"
    log "info" "Symbolic link created in /usr/local/bin/canvas-admin."
  fi

  log "info" "Environment prepared."
}

list_subaccounts() {
  # Define the API endpoint for fetching subaccounts
  source "$config_file"
  api_endpoint="$CANVAS_INSTITUE_URL/accounts/$CANVAS_ACCOUNT_ID/sub_accounts"

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

generate_conf() {
  log "info" "Checking Canvas API access token..."

  # Define the configuration file path
  config_file="${CANVAS_ADMIN_CONF}canvas.conf"

  # Check if the configuration file exists
  if [ ! -f "$config_file" ]; then
    # Prompt the user to enter an API Access Token
    log "info" "The canvas.conf configuration file was not found. Creating a new configuration file..."
    log "info" "Please follow the instructions to generate an API Access Token:"
    log "info" "https://canvas.instructure.com/doc/api/file.oauth.html#manual-token-generation"
    read -rp "Enter your Canvas API Access Token: " entered_token
    log "info" "Please enter your Canvas Institute URL e.g. canvas.school.edu or school.instructure.com"
    read -rp "Enter your Canvas Institute URL: " entered_url

    # Save the access token and institute URL in the configuration file
    echo "CANVAS_ACCESS_TOKEN=\"$entered_token\"" > "$config_file"
    echo "CANVAS_INSTITUE_URL=\"https://$entered_url/api/v1\"" >> "$config_file"
    # Load the access token and institute URL variables
    source "$config_file"
    log "info" "Fetching the root account ID..." 
    api_endpoint="$CANVAS_INSTITUE_URL/accounts"

    # Perform the API request to fetch the root account
    response=$(curl -s -X GET "$api_endpoint" \
      -H "Authorization: Bearer $CANVAS_ACCESS_TOKEN" \
      -H "Content-Type: application/json" \
      --data-urlencode "per_page=1")
    
    # Check if the response is a valid JSON array
    if ! echo "$response" | jq 'if type=="array" then true else false end' -e >/dev/null; then
      log "error" "Failed to fetch the root account. Response: $response"
      exit 1
    fi

    # Extract the root account ID from the response
    root_account_id=$(echo "$response" | jq '.[0].id')

    # Get the Canvas root account ID
    if [ "$root_account_id" == "" ]; then
      log "error" "Failed to fetch the root account ID."
      exit 1
    else
      log "info" "The root account ID is ($root_account_id)."
      echo "CANVAS_ROOT_ACCOUTN_ID=\"$root_account_id\"" >> "$config_file"
    fi
    
    # List the sub-accounts and prompt the user to select one
    echo "Fetching and listing available sub-accounts..."
    CANVAS_ACCOUNT_ID="$CANVAS_ROOT_ACCOUTN_ID"
    list_subaccounts
    read -rp "Enter your Canvas Account ID or leave it blank to use the root account ID ($CANVAS_ROOT_ACCOUTN_ID): " entered_account_id

    if [ -z "$entered_account_id" ]; then
      entered_account_id="$CANVAS_ROOT_ACCOUTN_ID"
    fi
    
    api_endpoint="$CANVAS_INSTITUE_URL/accounts/$CANVAS_ACCOUNT_ID"

    response=$(curl -s -X GET "$api_endpoint" \
      -H "Authorization: Bearer $CANVAS_ACCESS_TOKEN" \
      -H "Content-Type: application/json")

    detected_institution_name=$(echo "$response" | jq -r '.name')
    default_time_zone=$(echo "$response" | jq -r '.default_time_zone')

    log "info" "Detecting the name of you institute..."
    read -rp "Detected istitute name is ($detected_institution_name). Press Enter to accept, or type a different name: " entered_institute_long_name
    if [ -z "$entered_institute_long_name" ]; then
      entered_institute_long_name="$detected_institution_name"
    fi

    log "info" "Detecting the abbreviation of your institute name..."
    log "info" "This abbreviation is used for integration with other services such as Zoom, Box, Redshelf etc."
    detected_institute_short_name=$(echo "$entered_institute_long_name" | awk -F' ' '{ for (i=1; i<=NF; ++i) printf substr($i, 1, 1) }' | tr '[:upper:]' '[:lower:]')
    read -rp "Detected istitute abbreviation is ($detected_institute_short_name). Press Enter to accept, or type a different abbreviation: " entered_institute_short_name
    if [ -z "$entered_institute_short_name" ]; then
      entered_institute_short_name="$detected_institute_short_name"
    fi

    # Get the user's location and timezone based on their IP address
    log "info" "Detecting institue default timezone based on Canvas account..."
    log "info" "This timezone is used for scheduling courses and other events."
    log "info" "Your institutes detected timezone is ($default_time_zone)."
    log "info" "Detecting user timezone based on your IP address..."
    location_info=$(curl -s "http://ip-api.com/json")
    user_time_zone=$(echo "$location_info" | jq -r '.timezone')
    # if the default_time_zone and user_time_zone are the same, inform the user and prompt to confirm or modify, otherwise if the are different, inform user, and prompt to select or modify the timezone
    # if the user selects a different timezone, prompt to confirm or modify
    if [ "$default_time_zone" == "$user_time_zone" ]; then
      read -rp "Your detected timezone is ($user_time_zone). Press Enter to accept, or type a different timezone: " entered_time_zone
      if [ -z "$entered_time_zone" ]; then
        entered_time_zone="$user_time_zone"
      fi
    else
      log "info" "Your institutes default timezone is ($default_time_zone)."
      log "info" "Your actual timezone is ($user_time_zone)."
      read -rp "Press Enter to accept your institutes default timezone, or type a different timezone: " entered_time_zone
      if [ -z "$entered_time_zone" ]; then
        entered_time_zone="$default_time_zone"
      fi
    fi

    # Save the access token, institute URL, account ID, school name, and timezone in the configuration file
    {
        echo "CANVAS_INSTITUTE_LONG_NAME=\"$entered_institute_long_name\""
        echo "CANVAS_INSTITUTE_SHORT_NAME=\"$entered_institute_short_name\""
        echo "CANVAS_DEFAULT_TIMEZONE=\"$entered_time_zone\""
        echo "CANVAS_ADMIN_HOME=\"${HOME}/Canvas/\""
        echo "CANVAS_ADMIN_CONF=\"${HOME}/Canvas/conf/\""
        echo "CANVAS_ADMIN_LOG=\"${HOME}/Canvas/logs/\""
        echo "CANVAS_ADMIN_DL=\"${HOME}/Canvas/Downloads/\""
        echo "CANVAS_ADMIN_TMP=\"${HOME}/Canvas/tmp/\""
        echo "CANVAS_ADMIN_BIN=\"${HOME}/Canvas/bin/\""
    } >> "$config_file"
    
    log "info" "Access token, Institute URL, Account ID, School Name, and Time Zone saved in the configuration file."
  else
    log "info" "canvas.conf configuration file found. Loading access token and other configuration variables..."

    # Load the access token and institute URL variables
    source "$config_file"

    # Validate the access token (this is a simple check, you may want to perform additional validation)
        if [ -z "$CANVAS_ACCESS_TOKEN" ] || [ -z "$CANVAS_INSTITUE_URL" ] || [ -z "$CANVAS_ACCOUNT_ID" ] || [ -z "$CANVAS_INSTITUTE_LONG_NAME" ] || [ -z "$CANVAS_DEFAULT_TIMEZONE" ]; then
      log "error" "The Canvas API Access Token, Institute URL, Account ID, or School Name is not set in the configuration file."
      exit 1
    else
      log "info" "Canvas API access token, Institute URL, Account ID, and School Name found and loaded from the configuration file."
    fi
  fi
}

validate_setup() {
  log "info" "Validating Canvas Admin setup..."

  # Check if the necessary directories exist
  if [ ! -d "${CANVAS_ADMIN_HOME}" ] || [ ! -d "${CANVAS_ADMIN_HOME}bin" ] || [ ! -d "${CANVAS_ADMIN_HOME}Downloads" ] || [ ! -d "${CANVAS_ADMIN_HOME}tmp" ] || [ ! -d "${CANVAS_ADMIN_HOME}logs" ] || [ ! -d "${CANVAS_ADMIN_HOME}conf" ]; then
    log "error" "Required directories are missing or incorrect in the Canvas Admin setup."
    return 1
  else
    log "info" "Required directories found and validated."
  fi

  # Check if canvas-admin.sh exists and is executable
  if [ ! -x "${CANVAS_ADMIN_BIN}canvas-admin.sh" ]; then
    log "error" "canvas-admin.sh is missing or not executable in the Canvas Admin setup."
    return 1
  else
    log "info" "canvas-admin.sh found and validated as executable."
  fi

  # Check if the configuration file exists and contains the required variables
  config_file="${CANVAS_ADMIN_CONF}canvas.conf"
  if [ ! -f "$config_file" ]; then
    log "error" "Configuration file (canvas.conf) is missing in the Canvas Admin setup."
    return 1
  else
    log "info" "Configuration file (canvas.conf) found and validated."
  fi

  if [ -z "$CANVAS_ACCESS_TOKEN" ] || [ -z "$CANVAS_INSTITUE_URL" ] || [ -z "$CANVAS_ACCOUNT_ID" ] || [ -z "$CANVAS_INSTITUTE_LONG_NAME" ] || [ -z "$CANVAS_ADMIN_HOME" ] || [ -z "$CANVAS_ADMIN_CONF" ] || [ -z "$CANVAS_ADMIN_LOG" ] || [ -z "$CANVAS_ADMIN_DL" ] || [ -z "$CANVAS_ADMIN_TMP" ] || [ -z "$CANVAS_ADMIN_BIN" ]; then
    log "error" "Required variables are missing or incorrect in the configuration file (canvas.conf)."
    return 1
  else
    log "info" "Required variables found and validated in the configuration file (canvas.conf)."
  fi

  # If all checks passed, create the .done file
  touch "${CANVAS_ADMIN_HOME}.done"
  log "info" "Canvas Admin setup validation completed successfully."
  return 0
}

check_for_updates() {
  force_update=false

  # Check if the -force option is provided
  if [ "$1" == "-force" ]; then
    force_update=true
  fi

  source "$config_file"
  log "info" "Checking for updates to canvas-admin.sh..."

  # Define the URL for the remote script
  remote_script_url="https://raw.githubusercontent.com/greatkemo/canvas-admin4/main/canvas-admin.sh"

  # Download the remote script into the tmp directory
  log "info" "Downloading remote script for comparison..."
  curl -s -o "${CANVAS_ADMIN_TMP}canvas-admin.sh" "$remote_script_url"

  # Check if the downloaded script is different from the local script or if force update is enabled
  if $force_update || ! cmp -s "${CANVAS_ADMIN_TMP}canvas-admin.sh" "${CANVAS_ADMIN_BIN}canvas-admin.sh"; then
    log "info" "A new version of canvas-admin.sh has been detected."

    # Prompt the user to update
    update_choice="n"
    if [ "$1" == "-y" ]; then
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
}

user_search() {
  validate_setup
  search_pattern="$1"
  output_file="${CANVAS_ADMIN_DL}user_search-$(date '+%d-%m-%Y_%H-%M-%S').csv"

  log "info" "Initiating user search with pattern: $search_pattern"

  # Define the API endpoint for searching users
  api_endpoint="$CANVAS_INSTITUE_URL/accounts/$CANVAS_ACCOUNT_ID/users"

  # Perform the API request to search for users
  log "info" "Sending API request to search for users..."
  response=$(curl -s -X GET "$api_endpoint" \
    -H "Authorization: Bearer $CANVAS_ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -G --data-urlencode "search_term=$search_pattern" \
    --data-urlencode "include[]=email" \
    --data-urlencode "include[]=enrollments")

  # Check if the response is empty
  if [ -z "$response" ] || [ "$response" == "[]" ]; then
    log "info" "No users found matching the pattern: $search_pattern"
    return
  fi

  # Parse the response and create the CSV file
  log "info" "Parsing API response and generating CSV file..."
  echo "\"canvas_user_id\",\"user_id\",\"integration_id\",\"authentication_provider_id\",\"login_id\",\"first_name\",\"last_name\",\"full_name\",\"sortable_name\",\"short_name\",\"email\",\"status\",\"created_by_sis\"" > "$output_file"
  echo "$response" | jq -r '.[] | [.id, .sis_user_id, .integration_id, "", .login_id, (.sortable_name | split(", ")[1]), (.sortable_name | split(", ")[0]), .name, .sortable_name, .short_name, .email, (if .enrollments != null then .enrollments[0].workflow_state else "" end), (if .sis_user_id != null then "TRUE" else "FALSE" end)] | @csv' >> "$output_file"

  log "info" "User search results saved to: $output_file"
}

get_user_id() {
  search_pattern="$1"

  # Define the API endpoint for searching users
  api_endpoint="$CANVAS_INSTITUE_URL/accounts/$CANVAS_ACCOUNT_ID/users"

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
  api_endpoint="$CANVAS_INSTITUE_URL/courses/$course_id/enrollments"

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

  api_endpoint="$CANVAS_INSTITUE_URL/courses/$course_id"

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
  api_endpoint="$CANVAS_INSTITUE_URL/courses/$course_id/modules"
  module_data="{\"module\": {\"name\": \"Online Textbooks\"}}"

  log "info" "Creating 'Online Textbooks' module..."
  module_id=$(curl -s -X POST "$api_endpoint" \
    -H "Authorization: Bearer $CANVAS_ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$module_data" | jq -r '.id')

  log "info" "Successfully created 'Online Textbooks' module with ID: $module_id"

  # Define the API endpoint for adding items to the module
  api_endpoint="$CANVAS_INSTITUE_URL/courses/$course_id/modules/$module_id/items"

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
  local api_endpoint="$CANVAS_INSTITUE_URL/accounts/$CANVAS_ACCOUNT_ID/terms"
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

create_single_course() {
  course_name="$1"
  course_code="$2"
  term_id="$3"
  sub_account_id="$4"
  instructor_id="$5"

  # Define the API endpoint for creating courses
  api_endpoint="$CANVAS_INSTITUE_URL/accounts/${sub_account_id:-$CANVAS_ACCOUNT_ID}/courses"

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
  echo "user"
  echo "  Search for users based on a search pattern and output their records to a CSV file."
  echo "  Format: ./canvas-admin.sh user \"user search pattern\""
  echo "  Example: ./canvas-admin.sh user \"john.doe\""
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
if [ ! -f "${HOME}/Canvas/.done" ]; then
  prepare_environment
  generate_conf

  # Validate the setup and create the .done file
  source "$config_file"
  if ! validate_setup; then
    log "error" "Validation failed. Please check the setup."
    exit 1
  fi
fi

while [ "$#" -gt 0 ]; do
  case "$1" in
    help) # show the usage message
      usage 
      exit 0
      ;;
    update) # check for updates
      shift
      if [ "$1" = "-y" ]; then
        check_for_updates "-y"
      elif [ "$1" = "-force" ]; then
        check_for_updates "-force"
      else
        check_for_updates
      fi
      exit 0
      ;;
    user) # search for users
      shift
      user_search "$1"
      shift
      ;;
    createcourse) # create a new course
      shift
      if [ -n "$1" ] && [ -f "$1" ]; then
        create_course "$1"
        shift
      else
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




