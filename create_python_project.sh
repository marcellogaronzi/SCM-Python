#!/bin/bash
<<'Commento'
https://packaging.python.org/en/latest/tutorials/packaging-projects/
https://packaging.python.org/en/latest/tutorials/creating-documentation/
https://github.com/settings/tokens
Commento

# Set the absolute path of running bash script
ABSPathScript=$( dirname -- "$( readlink -f -- "$0"; )"; )
template_directory="$ABSPathScript/TEMPLATE"
echo "script running in: $ABSPathScript"

# Set the parameters
token=$1
python_version=$2
project_name=$3
project_directory=$4

#Set Local Variable
username="ApreaMarco"
name="Aprea Marco"
email="marco.aprea@marconiverona.edu.it"
package="python/it/edu/marconi/"

# Check if all parameters are provided
if [ -z "$token" ] || [ -z "$python_version" ] || [ -z "$project_name" ] || [ -z "$project_directory" ]; then
  echo "Error: All parameters are required. Please provide the token, python version, project name and project directory." >&2
  exit 1
fi
echo "1. Check on parameters passed!"

# Check if the template directory exists
if [ ! -d "$template_directory" ]; then
  echo 'Error: Template directory does not exist.' >&2
  exit 1
fi

# Check if the template files exist
if [ ! -f "$template_directory/pyproject.toml" ] || [ ! -f "$template_directory/LICENSE" ]; then
  echo 'Error: Template files do not exist.' >&2
  exit 1
fi
echo "2. Check on Template directory and files passed!"

# Check if pyenv, pyenv-virtualenv, pipenv, git and curl are installed
if ! [ -x "$(command -v pyenv)" ]; then
  echo 'Error: pyenv is not installed.' >&2
  exit 1
fi

if ! [ -x "$(command -v pyenv-virtualenv)" ]; then
  echo 'Error: pyenv-virtualenv is not installed.' >&2
  exit 1
fi

if ! [ -x "$(command -v pipenv)" ]; then
  echo 'Error: pipenv is not installed.' >&2
  exit 1
fi

if ! [ -x "$(command -v git)" ]; then
  echo 'Error: git is not installed.' >&2
  exit 1
fi

if ! [ -x "$(command -v curl)" ]; then
  echo 'Error: curl is not installed.' >&2
  exit 1
fi
echo "3. Check on installed tools passed!"

# Create the project directory if it doesn't exist
if [ ! -d "$project_directory" ]; then
  mkdir $project_directory
else
  echo 'Error: folder already exists.' >&2
  exit 1
fi

# Create the project structure
touch "$project_directory/README.md"

# Changes all placeholders inside template file
awk -v project_name="$project_name" -v name="$name" -v email="$email"\
 -v python_version="$python_version" -v username="$username"\
 '{ gsub("{project_name}", project_name); gsub("{name}", name); gsub("{email}", email);
  gsub("{python_version}", python_version); gsub("{username}", username); print }'\
 "$template_directory/pyproject.toml" > "$project_directory/pyproject.toml"\

awk -v username="$username" '{ gsub("{username}", username); print }' "$template_directory/LICENSE" > "$project_directory/LICENSE"

mkdir "$project_directory/src"
mkdir "$project_directory/tests"
mkdir -p "$project_directory/src/"$package$project_name"_"$USER
touch "$project_directory/src/"$package$project_name"_"$USER"/"__init__.py
touch "$project_directory/src/"$package$project_name"_"$USER"/""$project_name".py

echo "Created project structure in $project_directory"

cd "$project_directory"
mkdir .venv # In this way pyenv and pipenv create the virtualenv inside this directory instead than default directory

# Check if the specified python version is installed
if [ "$(pyenv versions | grep $python_version)" == "" ]; then
  pyenv install $python_version
fi

# Create the virtual environment
pyenv virtualenv $python_version $project_name"_"$python_version

# Set the virtual environment as the local environment
pyenv local $project_name"_"$python_version # create .python-version file

# Install the virtual environment using pipenv inside pyenv shell
pyenv shell
pipenv install # create Pipfile and Pipfile.lock files
pipenv shell exit

# Config git to global parameters stored inside ~/-gitconfig
git config --global user.name "$username"
git config --global user.email "$email"

# Check if specified github token is already laoded
if [ -f ~/.git-credentials ] && [ "$(cat ~/.git-credentials | grep $token)" == "" ]; then
  git config --global credential.helper "store --file=~/.git-credentials" 'cache --timeout=3600'
  echo "https://$token:x-oauth-basic@github.com" > ~/.git-credentials
fi

#Initialize the Git repository
git init

# Create a new repository on GitHub
curl -u "$username:$token" https://api.github.com/user/repos -d "{\"name\":\"$project_name\"}"

#Add the remote repository to the local Git repository
git config remote.origin.url "https://$username:$token@github.com/$username/$project_name.git"

#Add all files to the Git repository
git add .

#Commit the changes
git commit -m "Initial commit"

#Push the changes to the remote repository
git push -u origin master

#Cleaning the token
git config --global --unset credential.helper
