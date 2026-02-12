# List available commands
default:
    @just --list

# Initialize the project (clone submodules + setup env)
setup:
    git submodule update --init --recursive
    cp -n .env.example .env || true
    @echo "Setup complete! Don't forget to edit .env"

# Start all services
start:
    docker-compose up -d

# Stop all services
stop:
    docker-compose down

# Update all submodules to latest
pull:
    git submodule update --remote --merge

# View logs
logs:
    docker-compose logs -f
