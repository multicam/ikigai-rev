#!/bin/bash
# Usage: .ralph/loop.sh [plan|build|review|reverse] [max_iterations]
# Model: Set RALPH_MODEL env var (default: sonnet)
#   anthropic models (sonnet, opus, haiku) → prompts/anthropic/
#   glm models (glm-*)                    → prompts/glm-5/
# Examples (run from repo root):
#   .ralph/loop.sh              # Build mode, sonnet, unlimited iterations
#   .ralph/loop.sh 20           # Build mode, max 20 iterations
#   .ralph/loop.sh plan         # Plan mode, unlimited iterations
#   .ralph/loop.sh plan 5       # Plan mode, max 5 iterations
#   .ralph/loop.sh review       # Review mode, unlimited iterations
#   .ralph/loop.sh reverse      # Reverse mode, unlimited iterations
#   RALPH_MODEL=opus .ralph/loop.sh plan   # Plan with opus
#   RALPH_MODEL=glm-5 .ralph/loop.sh      # Build with GLM-5 prompts

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Determine model and prompt directory
# RALPH_MODEL env var overrides the default (sonnet)
MODEL="${RALPH_MODEL:-sonnet}"

# Map model to prompt directory
case "$MODEL" in
    sonnet|opus|haiku) PROMPT_DIR="anthropic" ;;
    glm-*)            PROMPT_DIR="glm-5" ;;
    *)                PROMPT_DIR="anthropic" ;;
esac

# Parse arguments
if [ "$1" = "plan" ]; then
    MODE="plan"
    MAX_ITERATIONS=${2:-0}
elif [ "$1" = "review" ]; then
    MODE="review"
    MAX_ITERATIONS=${2:-0}
elif [ "$1" = "reverse" ]; then
    MODE="reverse"
    MAX_ITERATIONS=${2:-0}
elif [[ "$1" =~ ^[0-9]+$ ]]; then
    MODE="build"
    MAX_ITERATIONS=$1
else
    MODE="build"
    MAX_ITERATIONS=0
fi

PROMPT_FILE="$SCRIPT_DIR/prompts/$PROMPT_DIR/$MODE.md"

ITERATION=0
cd "$REPO_ROOT"
CURRENT_BRANCH=$(git branch --show-current)

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Repo:   $REPO_ROOT"
echo "Mode:   $MODE"
echo "Model:  $MODEL ($PROMPT_DIR prompts)"
echo "Prompt: $PROMPT_FILE"
echo "Branch: $CURRENT_BRANCH"
[ $MAX_ITERATIONS -gt 0 ] && echo "Max:    $MAX_ITERATIONS iterations"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Verify prompt file exists
if [ ! -f "$PROMPT_FILE" ]; then
    echo "Error: $PROMPT_FILE not found"
    exit 1
fi

while true; do
    if [ $MAX_ITERATIONS -gt 0 ] && [ $ITERATION -ge $MAX_ITERATIONS ]; then
        echo "Reached max iterations: $MAX_ITERATIONS"
        break
    fi

    # Run Ralph iteration with selected prompt
    # -p: Headless mode (non-interactive, reads from stdin)
    # --dangerously-skip-permissions: Auto-approve all tool calls (YOLO mode)
    # --output-format=stream-json: Structured output for logging/monitoring
    # --model opus: Primary agent uses Opus for complex reasoning (task selection, prioritization)
    #               Can use 'sonnet' in build mode for speed if plan is clear and tasks well-defined
    # --verbose: Detailed execution logging
    LOG_FILE="/tmp/ralph/${MODE}-$(date +%Y%m%d-%H%M%S)-iter${ITERATION}.jsonl"
    mkdir -p /tmp/ralph
    cat "$SCRIPT_DIR/shared/tool-preferences.md" "$PROMPT_FILE" | claude -p \
        --dangerously-skip-permissions \
        --output-format=stream-json \
        --model "$MODEL" \
        --verbose \
        2>&1 | tee "$LOG_FILE"

    # Commit and push changes after each iteration
    if [ -n "$(git status --porcelain)" ]; then
        git add -A
        git commit -m "Iteration $ITERATION - $MODE mode"
        git push origin "$CURRENT_BRANCH" || {
            echo "Failed to push. Setting upstream and retrying..."
            git push -u origin "$CURRENT_BRANCH"
        }
    fi

    ITERATION=$((ITERATION + 1))
    echo -e "\n\n======================== LOOP $ITERATION ========================\n"

    # In plan mode, check for pause gate between iterations
    # Usage: touch .pause → edit specs → rm .pause
    if [ "$MODE" = "plan" ] && [ -f "$REPO_ROOT/.pause" ]; then
        echo "⏸ Paused. Edit specs, then: rm .pause"
        while [ -f "$REPO_ROOT/.pause" ]; do sleep 2; done
        echo "Resuming..."
    fi
done
