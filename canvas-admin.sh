#!/usr/bin/env bash

# Define variables
CANVAS_INSTITUE_URL=""
CANVAS_ACCESS_TOKEN=""
CANVAS_ACCOUNT_ID=""
CANVAS_SCHOOL_NAME=""

CANVAS_ADMIN_HOME="${HOME}/Canvas/"
CANVAS_ADMIN_CONF="${HOME}/Canvas/conf/"
CANVAS_ADMIN_LOG="${HOME}/Canvas/logs/"
CANVAS_ADMIN_DL="${HOME}/Canvas/Downloads/"
CANVAS_ADMIN_TMP="${HOME}/Canvas/tmp/"
CANVAS_ADMIN_BIN="${HOME}/Canvas/bin/"

# Functions

prepare_environment() {
  echo "Preparing environment..."

  # Create directories if they don't exist
  mkdir -p "$CANVAS_ADMIN_HOME"
  mkdir -p "${CANVAS_ADMIN_HOME}bin"
  mkdir -p "${CANVAS_ADMIN_HOME}Downloads"
  mkdir -p "${CANVAS_ADMIN_HOME}tmp"
  mkdir -p "${CANVAS_ADMIN_HOME}logs"
  mkdir -p "${CANVAS_ADMIN_HOME}conf"

  # Check if canvas-admin.sh is executable
  if [ ! -x "${CANVAS_ADMIN_BIN}canvas-admin.sh" ]; then
    echo "Making canvas-admin.sh executable..."
    chmod +x "${CANVAS_ADMIN_BIN}canvas-admin.sh"
  fi

  # Check if the bin directory is in the user PATH environment variable
  if [[ ":$PATH:" != *":${CANVAS_ADMIN_BIN}:"* ]]; then
    echo "Adding ${CANVAS_ADMIN_BIN} to PATH environment variable..."
    echo "export PATH=\$PATH:${CANVAS_ADMIN_BIN}" >> "${HOME}/.bashrc"
    source "${HOME}/.bashrc"
  fi

  echo "Environment prepared."
}


check_for_updates() {
  echo "Checking for updates..."

  # Define the URL for the remote script
  remote_script_url="https://raw.githubusercontent.com/greatkemo/canvas-admin4/main/canvas-admin.sh"

  # Download the remote script into the tmp directory
  curl -s -o "${CANVAS_ADMIN_TMP}canvas-admin.sh" "$remote_script_url"

  # Check if the downloaded script is different from the local script
  if ! cmp -s "${CANVAS_ADMIN_TMP}canvas-admin.sh" "${CANVAS_ADMIN_BIN}canvas-admin.sh"; then
    # Prompt the user to update
    read -p "A new version of canvas-admin.sh is available. Do you want to update? [Y/n]: " update_choice
    if [[ "$update_choice" =~ ^[Yy]$|^$ ]]; then
      # Update the local script
      mv "${CANVAS_ADMIN_TMP}canvas-admin.sh" "${CANVAS_ADMIN_BIN}canvas-admin.sh"
      chmod +x "${CANVAS_ADMIN_BIN}canvas-admin.sh"
      echo "Updated canvas-admin.sh to the latest version."
    else
      echo "Update skipped."
    fi
  else
    echo "canvas-admin.sh is already up-to-date."
  fi

  # Clean up the tmp directory
  rm -f "${CANVAS_ADMIN_TMP}canvas-admin.sh"
}

generate_token() {
  echo "Checking Canvas API access token..."

  # Define the configuration file path
  config_file="${CANVAS_ADMIN_CONF}canvas.conf"

  # Check if the configuration file exists
  if [ ! -f "$config_file" ]; then
    # Prompt the user to enter an API Access Token
    echo "The canvas.conf configuration file was not found."
    echo "Please follow the instructions to generate an API Access Token:"
    echo "https://canvas.instructure.com/doc/api/file.oauth.html#manual-token-generation"
    read -p "Enter your Canvas API Access Token: " entered_token
    read -p "Enter your Canvas Institute URL: " entered_url

    # Save the access token and institute URL in the configuration file
    echo "CANVAS_ACCESS_TOKEN=\"$entered_token\"" > "$config_file"
    echo "CANVAS_INSTITUE_URL=\"$entered_url\"" >> "$config_file"

    # Load the access token and institute URL variables
    source "$config_file"

    echo "Access token and Institute URL saved in the configuration file."
  else
    # Load the access token and institute URL variables
    source "$config_file"

    # Validate the access token (this is a simple check, you may want to perform additional validation)
    if [ -z "$CANVAS_ACCESS_TOKEN" ] || [ -z "$CANVAS_INSTITUE_URL" ]; then
      echo "Error: The Canvas API Access Token or Institute URL is not set in the configuration file."
      exit 1
    else
      echo "Canvas API access token and Institute URL found in the configuration file."
    fi
  fi
}

user_search() {
  search_pattern="$1"
  output_file="${CANVAS_ADMIN_DL}user_search-$(date '+%d-%m-%Y_%H-%M-%S').csv"

  echo "Searching for users matching the pattern: $search_pattern"

  # Define the API endpoint for searching users
  api_endpoint="$CANVAS_INSTITUE_URL/accounts/$CANVAS_ACCOUNT_ID/users"

  # Perform the API request to search for users
  response=$(curl -s -X GET "$api_endpoint" \
    -H "Authorization: Bearer $CANVAS_ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -G --data-urlencode "search_term=$search_pattern")

  # Check if the response is empty
  if [ -z "$response" ] || [ "$response" == "[]" ]; then
    echo "No users found."
    return
  fi

  # Parse the response and create the CSV file
  echo "\"user_id\",\"integration_id\",\"login_id\",\"password\",\"first_name\",\"last_name\",\"full_name\",\"sortable_name\",\"short_name\",\"email\",\"status\"" > "$output_file"
  echo "$response" | jq -r '.[] | [.id, .integration_id, .login_id, .password, .name, .sortable_name, .short_name, .email, .workflow_state] | @csv' >> "$output_file"

  echo "User search results saved to: $output_file"
}

course_settings() {
  setting_type="$1"
  setting_value="$2"
  course_id="$3"

  echo "Applying settings to course ID: $course_id"

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
      echo "Invalid setting type. Please use 'timezone', 'config', or 'all'."
      exit 1
  esac

  # Perform the API request to update course settings
  curl -s -X PUT "$api_endpoint" \
    -H "Authorization: Bearer $CANVAS_ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$api_data"

  echo "Settings applied to course ID: $course_id"
}

course_books() {
  book_type="$1"
  course_id="$2"

  echo "Adding online textbook links to course ID: $course_id"

  # Create the "Online Textbooks" module
  api_endpoint="$CANVAS_INSTITUE_URL/courses/$course_id/modules"
  module_data="{\"module\": {\"name\": \"Online Textbooks\"}}"

  module_id=$(curl -s -X POST "$api_endpoint" \
    -H "Authorization: Bearer $CANVAS_ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$module_data" | jq -r '.id')

  echo "Created 'Online Textbooks' module with ID: $module_id"

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
      echo "Invalid book type. Please use 'redshelf', 'vitalsource', or 'all'."
      exit 1
  esac

  book_data="{\"module_item\": {\"title\": \"$book_title\", \"type\": \"ExternalTool\", \"external_url\": \"$book_url\", \"position\": 1, \"indent\": 1, \"new_tab\": false}}"

  # Perform the API request to add the external link to the module
  curl -s -X POST "$api_endpoint" \
    -H "Authorization: Bearer $CANVAS_ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$book_data"

  echo "Added '$book_title' link to the 'Online Textbooks' module in course ID: $course_id"
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
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done


