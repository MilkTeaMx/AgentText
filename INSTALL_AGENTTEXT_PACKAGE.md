# Installing the AgentText Python Package

The AgentText Python package is required for the Python scripts to work. Here's how to install it:

## Option 1: Install from Local Clone (Recommended for Development)

### 1. Clone the agenttext_package repository

```bash
# Clone to a location of your choice (e.g., your home directory)
cd ~
git clone https://github.com/MilkTeaMx/agenttext_package.git
```

### 2. Install in editable mode

```bash
# Install using pip in editable mode
pip3 install -e ~/agenttext_package
```

This creates a symlink, so any changes to the package will be immediately available.

### 3. Verify installation

```bash
python3 -c "from agenttext import AgentText; print('✅ AgentText package installed successfully!')"
```

## Option 2: Install Directly from GitHub

```bash
pip3 install git+https://github.com/MilkTeaMx/agenttext_package.git
```

## Option 3: Install from PyPI (if published)

```bash
pip3 install agenttext
```

## Testing the Installation

Once installed, test that it works:

```bash
# Test import
python3 << 'EOF'
from agenttext import AgentText, AgentTextAPIException, AgentTextConnectionException

client = AgentText(base_url="http://localhost:3000", timeout=30)
print("✅ AgentText package is working!")
EOF
```

## Troubleshooting

### Package not found

If you get `ModuleNotFoundError: No module named 'agenttext'`:

1. Check your Python version:
   ```bash
   python3 --version
   ```

2. Make sure you're using the right pip:
   ```bash
   which pip3
   pip3 --version
   ```

3. List installed packages:
   ```bash
   pip3 list | grep agenttext
   ```

4. Reinstall:
   ```bash
   pip3 uninstall agenttext
   pip3 install -e ~/agenttext_package
   ```

### Permission errors

If you get permission errors:

```bash
# Use --user flag
pip3 install --user -e ~/agenttext_package
```

Or use a virtual environment:

```bash
# Create virtual environment
python3 -m venv ~/.venv/agenttext

# Activate it
source ~/.venv/agenttext/bin/activate

# Install package
pip3 install -e ~/agenttext_package
```

### Multiple Python versions

If you have multiple Python versions:

```bash
# Use python3.11 (or your specific version)
python3.11 -m pip install -e ~/agenttext_package
```

## Using in Your Mac App

Once the package is installed, your Mac app's Python scripts will be able to use it. Make sure the Python path in your Swift code (`/usr/bin/python3`) matches the Python version where you installed the package.

To verify:

```bash
/usr/bin/python3 -c "from agenttext import AgentText; print('Works!')"
```

## Next Steps

After installing the agenttext package:

1. ✅ Package installed
2. Start the API server (see [QUICK_START.md](QUICK_START.md))
3. Test the integration in your Mac app
