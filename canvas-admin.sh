#!/usr/bin/env bash

# Functions

log() {
    if [[ -e "${config_file}" ]]; then
        source "${config_file}"
    else
        mkdir -p "${HOME}/Canvas/logs/"
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
  echo -e "${log_color}${log_output}\033[0m" | tee -a "${CANVAS_ADMIN_LOG}canvas-admin.log"
}

prepare_environment() {
  log "info" "Preparing environment..."

  # Create directories if they don't exist
  mkdir -p "${HOME}/Canvas/"
  mkdir -p "${HOME}/Canvas/bin/"
  mkdir -p "${HOME}/Canvas/Downloads/"
  mkdir -p "${HOME}/Canvas/tmp/"
  mkdir -p "${HOME}/Canvas/logs/"
  mkdir -p "${HOME}/Canvas/conf/"

  # Define the URL for the remote script
  remote_script_url="https://raw.githubusercontent.com/greatkemo/canvas-admin4/main/canvas-admin.sh"

  # Check if canvas-admin.sh exists in the bin directory
  if [ ! -f "${CANVAS_ADMIN_BIN}canvas-admin.sh" ]; then
    log "info" "Downloading the latest version of canvas-admin.sh..."
    curl -s -o "${CANVAS_ADMIN_BIN}canvas-admin.sh" "$remote_script_url"
  fi

  # Check if canvas-admin.sh is executable
  if [ ! -x "${CANVAS_ADMIN_BIN}canvas-admin.sh" ]; then
    log "info" "Making canvas-admin.sh executable..."
    chmod +x "${CANVAS_ADMIN_BIN}canvas-admin.sh"
  fi

  # Check if the bin directory is in the user PATH environment variable
  if [[ ":$PATH:" != *":${CANVAS_ADMIN_BIN}:"* ]]; then
    log "info" "Adding ${CANVAS_ADMIN_BIN} to PATH environment variable..."
    echo "export PATH=\$PATH:${CANVAS_ADMIN_BIN}" >> "${HOME}/.bashrc"
    source "${HOME}/.bashrc"
  fi

    # Check if there is a bin directory in user home
    if [[ -d "${HOME}/bin" ]]; then
        ln -s "${CANVAS_ADMIN_BIN}canvas-admin.sh" "${HOME}/bin/canvas-admin"
    else
        ln -s "${CANVAS_ADMIN_BIN}canvas-admin.sh" "/usr/local/bin/canvas-admin"
    fi

  log "info" "Environment prepared."
}

generate_conf() {
  log "info" "Checking Canvas API access token..."

  # Define the configuration file path
  config_file="${CANVAS_ADMIN_CONF}canvas.conf"

  # Check if the configuration file exists
  if [ ! -f "$config_file" ]; then
    # Prompt the user to enter an API Access Token
    log "info" "The canvas.conf configuration file was not found."
    log "info" "Please follow the instructions to generate an API Access Token:"
    log "info" "https://canvas.instructure.com/doc/api/file.oauth.html#manual-token-generation"
    read -rp "Enter your Canvas API Access Token: " entered_token
    read -rp "Enter your Canvas Institute URL: " entered_url
    read -rp "Enter your Canvas Account ID: " entered_account_id
    read -rp "Enter your Canvas School Name: " entered_school_name

    # Save the access token and institute URL in the configuration file
    echo "CANVAS_ACCESS_TOKEN=\"$entered_token\"" > "$config_file"
    {
        echo "CANVAS_INSTITUE_URL=\"$entered_url\""
        echo "CANVAS_ACCOUNT_ID=\"$entered_account_id\""
        echo "CANVAS_SCHOOL_NAME=\"$entered_school_name\""
        echo "CANVAS_ADMIN_HOME=\"${HOME}/Canvas/\""
        echo "CANVAS_ADMIN_CONF=\"${HOME}/Canvas/conf/\""
        echo "CANVAS_ADMIN_LOG=\"${HOME}/Canvas/logs/\""
        echo "CANVAS_ADMIN_DL=\"${HOME}/Canvas/Downloads/\""
        echo "CANVAS_ADMIN_TMP=\"${HOME}/Canvas/tmp/\""
        echo "CANVAS_ADMIN_BIN=\"${HOME}/Canvas/bin/\""
    } >> "$config_file"

    # Load the access token and institute URL variables
    source "$config_file"

    log "info" "Access token, Institute URL, Account ID, and School Name saved in the configuration file."
  else
    # Load the access token and institute URL variables
    source "$config_file"

    # Validate the access token (this is a simple check, you may want to perform additional validation)
    if [ -z "$CANVAS_ACCESS_TOKEN" ] || [ -z "$CANVAS_INSTITUE_URL" ] || [ -z "$CANVAS_ACCOUNT_ID" ] || [ -z "$CANVAS_SCHOOL_NAME" ]; then
      log "error" "The Canvas API Access Token, Institute URL, Account ID, or School Name is not set in the configuration file."
      exit 1
    else
      log "info" "Canvas API access token, Institute URL, Account ID, and School Name found in the configuration file."
    fi
  fi
}

validate_setup() {
  # Check if the necessary directories exist
  source "$config_file"
  if [ ! -d "${CANVAS_ADMIN_HOME}" ] || [ ! -d "${CANVAS_ADMIN_HOME}bin" ] || [ ! -d "${CANVAS_ADMIN_HOME}Downloads" ] || [ ! -d "${CANVAS_ADMIN_HOME}tmp" ] || [ ! -d "${CANVAS_ADMIN_HOME}logs" ] || [ ! -d "${CANVAS_ADMIN_HOME}conf" ]; then
    return 1
  fi

  # Check if canvas-admin.sh exists and is executable
  if [ ! -x "${CANVAS_ADMIN_BIN}canvas-admin.sh" ]; then
    return 1
  fi

  # Check if the configuration file exists and contains the required variables
  config_file="${CANVAS_ADMIN_CONF}canvas.conf"
  if [ ! -f "$config_file" ]; then
    return 1
  fi

  if [ -z "$CANVAS_ACCESS_TOKEN" ] || [ -z "$CANVAS_INSTITUE_URL" ] || [ -z "$CANVAS_ACCOUNT_ID" ] || [ -z "$CANVAS_SCHOOL_NAME" ] || [ -z "$CANVAS_ADMIN_HOME" ] || [ -z "$CANVAS_ADMIN_CONF" ] || [ -z "$CANVAS_ADMIN_LOG" ] || [ -z "$CANVAS_ADMIN_DL" ] || [ -z "$CANVAS_ADMIN_TMP" ] || [ -z "$CANVAS_ADMIN_BIN" ]; then
    return 1
  fi

  # If all checks passed, create the .done file
  touch "${CANVAS_ADMIN_HOME}.done"
  return 0
}

check_for_updates() {
    source "$config_file"
  log "info" "Checking for updates..."

  # Define the URL for the remote script
  remote_script_url="https://raw.githubusercontent.com/greatkemo/canvas-admin4/main/canvas-admin.sh"

  # Download the remote script into the tmp directory
  curl -s -o "${CANVAS_ADMIN_TMP}canvas-admin.sh" "$remote_script_url"

  # Check if the downloaded script is different from the local script
  if ! cmp -s "${CANVAS_ADMIN_TMP}canvas-admin.sh" "${CANVAS_ADMIN_BIN}canvas-admin.sh"; then
    # Prompt the user to update
    read -rp "A new version of canvas-admin.sh is available. Do you want to update? [Y/n]: " update_choice
    if [[ "$update_choice" =~ ^[Yy]$|^$ ]]; then
      # Update the local script
      mv "${CANVAS_ADMIN_TMP}canvas-admin.sh" "${CANVAS_ADMIN_BIN}canvas-admin.sh"
      chmod +x "${CANVAS_ADMIN_BIN}canvas-admin.sh"
      log "info" "Updated canvas-admin.sh to the latest version."
    else
      log "info" "Update skipped."
    fi
  else
    log "info" "canvas-admin.sh is already up-to-date."
  fi

  # Clean up the tmp directory
  rm -f "${CANVAS_ADMIN_TMP}canvas-admin.sh"
}

user_search() {
    source "$config_file"
  search_pattern="$1"
  output_file="${CANVAS_ADMIN_DL}user_search-$(date '+%d-%m-%Y_%H-%M-%S').csv"

  log "info" "Searching for users matching the pattern: $search_pattern"

  # Define the API endpoint for searching users
  api_endpoint="$CANVAS_INSTITUE_URL/accounts/$CANVAS_ACCOUNT_ID/users"

  # Perform the API request to search for users
  response=$(curl -s -X GET "$api_endpoint" \
    -H "Authorization: Bearer $CANVAS_ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -G --data-urlencode "search_term=$search_pattern")

  # Check if the response is empty
  if [ -z "$response" ] || [ "$response" == "[]" ]; then
    log "info" "No users found."
    return
  fi

  # Parse the response and create the CSV file
  echo "\"user_id\",\"integration_id\",\"login_id\",\"password\",\"first_name\",\"last_name\",\"full_name\",\"sortable_name\",\"short_name\",\"email\",\"status\"" > "$output_file"
  echo "$response" | jq -r '.[] | [.id, .integration_id, .login_id, .password, .name, .sortable_name, .short_name, .email, .workflow_state] | @csv' >> "$output_file"

  log "info" "User search results saved to: $output_file"
}

course_settings() {
    source "$config_file"
  setting_type="$1"
  setting_value="$2"
  course_id="$3"

  log "info" "Applying settings to course ID: $course_id"

  api_endpoint="$CANVAS_INSTITUE_URL/courses/$course_id"

  case "$setting_type" in
    timezone)
      # Set the course's IANA time zone
      api_data="{\"course\": {\"time_zone\": \"$setting_value\"}}"
      ;;
    config)
      # Set the course's hide_distribution_graphs to true
      api_data="{\"course\": {\"hide_distribution_graphs\": true}}"
      ;;
    all)
      # Set the course's IANA time zone and hide_distribution_graphs
      api_data="{\"course\": {\"time_zone\": \"$setting_value\", \"hide_distribution_graphs\": true}}"
      ;;
    *)
      log "error" "Invalid setting type. Please use 'timezone', 'config', or 'all'."
      exit 1
  esac

  # Perform the API request to update course settings
  curl -s -X PUT "$api_endpoint" \
    -H "Authorization: Bearer $CANVAS_ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$api_data"

  log "info" "Settings applied to course ID: $course_id"
}

ccourse_books() {
    source "$config_file"
  book_type="$1"
  course_id="$2"

  log "info" "Adding online textbook links to course ID: $course_id"

  # Create the "Online Textbooks" module
  api_endpoint="$CANVAS_INSTITUE_URL/courses/$course_id/modules"
  module_data="{\"module\": {\"name\": \"Online Textbooks\"}}"

  module_id=$(curl -s -X POST "$api_endpoint" \
    -H "Authorization: Bearer $CANVAS_ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$module_data" | jq -r '.id')

  log "info" "Created 'Online Textbooks' module with ID: $module_id"

  # Define the API endpoint for adding items to the module
  api_endpoint="$CANVAS_INSTITUE_URL/courses/$course_id/modules/$module_id/items"

  # Add external links to the module based on the book type
  case "$book_type" in
    redshelf)
      book_title="RedShelf Inclusive"
      book_url="https://${CANVAS_SCHOOL_NAME}.redshelf.com/lti/my_courses/"
      ;;
    vitalsource)
      book_title="VitalSource Course Materials"
      book_url="https://bc.vitalsource.com/books"
      ;;
    all)
      course_books "redshelf" "$course_id"
      course_books "vitalsource" "$course_id"
      return
      ;;
    *)
      log "error" "Invalid book type. Please use 'redshelf', 'vitalsource', or 'all'."
      exit 1
  esac

  book_data="{\"module_item\": {\"title\": \"$book_title\", \"type\": \"ExternalTool\", \"external_url\": \"$book_url\", \"position\": 1, \"indent\": 1, \"new_tab\": false}}"

  # Perform the API request to add the external link to the module
  curl -s -X POST "$api_endpoint" \
    -H "Authorization: Bearer $CANVAS_ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$book_data"

  log "info" "Added '$book_title' link to the 'Online Textbooks' module in course ID: $course_id"
}

usage() {
  echo "Usage: ./canvas-admin.sh [options] [arg1] [arg2] [input]"
  echo ""
  echo "Options:"
  echo "-h, -help, --help"
  echo "  Show this help message and exit."
  echo ""
  echo "-u, -user, --user"
  echo "  Search for users and output their record to a CSV file."
  echo "  Format: ./canvas-admin.sh -u \"user search pattern\""
  echo ""
  echo "-s, -settings, --settings"
  echo "  Apply settings to a course using the specified arguments."
  echo "  Format: ./canvas-admin.sh -s [timezone|config|all] [arg1] [arg2] [course id]"
  echo ""
  echo "-b, -books, --books"
  echo "  Create a module called 'Online Textbooks' and add external links to the module."
  echo "  Format: ./canvas-admin.sh -b [redshelf|vitalsource|all] [course id]"
  echo ""
  echo "Please refer to the documentation for more information."
}

# Main script

# Call the necessary functions
if [ ! -f "${CANVAS_ADMIN_HOME}.done" ]; then
  prepare_environment
  generate_conf

  # Validate the setup and create the .done file
  
  if ! validate_setup; then
    log "error" "Validation failed. Please check the setup."
    exit 1
  fi
fi

check_for_updates

source "$config_file"

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|-help|--help)
      usage
      exit 0
      ;;
    -u|-user|--user)
      shift
      user_search "$1"
      shift
      ;;
    -s|-settings|--settings)
      shift
      course_settings "$1" "$2" "$3"
      shift 3
      ;;
    -b|-books|--books)
      shift
      course_books "$1" "$2"
      shift 2
      ;;
    *)
      log "error" "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done



