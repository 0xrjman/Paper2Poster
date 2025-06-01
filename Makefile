# Makefile for Python project using uv

# Try to find uv command, error if not found
UV := $(shell command -v uv)
ifndef UV
    $(error "uv command not found in PATH. Please install uv: https://github.com/astral-sh/uv")
endif

VENV_DIR = .venv
PYTHON_INTERPRETER = $(VENV_DIR)/bin/python
REQUIREMENTS_FILE = requirements.txt
PYTHON_VERSION = 3.12
PDF_PATH ?= "docs/Papers/Demo.pdf" # Default pdf path
MODEL_T ?= "gemini_2_5_flash" # Default model for text
MODEL_V ?= "gpt_4o" # Default model for vision

# Phony targets are not files
.PHONY: all run update-requirements clean setup-env list-models

# Default target when running 'make'
all: run

setup-env:
	@if [ ! -f .env ]; then \
		echo "Copying .env.example to .env ..."; \
		cp .env.example .env; \
	fi
	@echo "🎯 Editing .env to set OPENROUTER_API_KEY..."; \

# Target to run the application
# This depends on the Python interpreter in the venv being ready.
# Make will run the recipe for $(PYTHON_INTERPRETER) if it's out of date
# (e.g., doesn't exist or requirements.txt is newer).
run: list-models setup-env $(PYTHON_INTERPRETER)
	@echo "👍 Running the application using $(PYTHON_INTERPRETER)..."
	$(PYTHON_INTERPRETER) -m PosterAgent.new_pipeline \
		--poster_path=$(PDF_PATH) \
		--model_name_t=$(MODEL_T) \
		--model_name_v=$(MODEL_V) \
		--poster_width_inches=48 \
		--poster_height_inches=36

# Rule to set up the virtual environment and install dependencies.
# This target is the path to the Python interpreter within the virtual environment.
# It depends on the requirements file. If requirements.txt changes,
# or if the interpreter doesn't exist, this recipe runs.
$(PYTHON_INTERPRETER): $(REQUIREMENTS_FILE)
	@echo "Ensuring virtual environment $(VENV_DIR) is set up..."
	@# If the target Python interpreter does not exist within an existing VENV_DIR,
	@# it implies VENV_DIR might be corrupted or not a proper venv.
	@# In such a case, remove VENV_DIR to allow uv to create it cleanly.
	@if [ -d "$(VENV_DIR)" ] && ! [ -e "$(PYTHON_INTERPRETER)" ]; then \
		echo "Warning: Directory $(VENV_DIR) exists but $(PYTHON_INTERPRETER) is missing."; \
		echo "Removing $(VENV_DIR) to ensure a clean virtual environment setup."; \
		rm -rf "$(VENV_DIR)"; \
	fi
	@echo "Creating/updating virtual environment in $(VENV_DIR) if necessary..."
	$(UV) venv "$(VENV_DIR)" --seed --python $(PYTHON_VERSION)
	@echo "Installing/syncing dependencies from $(REQUIREMENTS_FILE) into $(VENV_DIR)..."
	$(UV) pip sync "$(REQUIREMENTS_FILE)" --python "$(PYTHON_INTERPRETER)"
	@# Touch the interpreter path to update its timestamp, satisfying Make
	@# This is only strictly necessary if uv venv or uv pip sync doesn't update it,
	@# but it's harmless and ensures Make knows the target is up-to-date.
	@touch "$(PYTHON_INTERPRETER)"

# Target to update requirements.txt
update-requirements: $(PYTHON_INTERPRETER) # Ensure venv is set up first
	@echo "Updating $(REQUIREMENTS_FILE) from environment $(VENV_DIR)..."
	$(UV) pip freeze --python "$(PYTHON_INTERPRETER)" > "$(REQUIREMENTS_FILE)"

# Target to clean the virtual environment and requirements file
clean:
	@echo "Removing virtual environment $(VENV_DIR)..."
	@rm -rf "$(VENV_DIR)"
	@echo "Removing $(REQUIREMENTS_FILE)..."
	@rm -f "$(REQUIREMENTS_FILE)"

list-models:
	@echo "🔍 Available models:"
	@echo "--------------------------------"
	@echo "➡️ claude_sonnet_4"
	@echo "➡️ claude_opus_4"
	@echo "➡️ deepseek_r1_v2"
	@echo "➡️ gpt_4o"
	@echo "➡️ gemini_2_5_pro"
	@echo "➡️ gemini_2_5_flash"
	@echo "--------------------------------"
