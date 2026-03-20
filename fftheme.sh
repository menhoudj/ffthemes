#!/bin/bash

CONFIG_DIR="$HOME/.config/fastfetch"
THEMES_DIR="$CONFIG_DIR/themes"
THEME_FILE="$CONFIG_DIR/current_theme"
STATE_FILE="$CONFIG_DIR/current_state"

get_themes() {
    for dir in "$THEMES_DIR"/*/; do
        [ -d "$dir" ] || continue
        count=$(find "$dir" -maxdepth 1 \( -name "*.png" -o -name "*.gif" \) 2>/dev/null | wc -l)
        [ "$count" -gt 0 ] && basename "$dir"
    done | sort
}

find_theme() {
    local input="$1"
    for dir in "$THEMES_DIR"/*/; do
        [ -d "$dir" ] || continue
        name=$(basename "$dir")
        if [ "${name,,}" = "${input,,}" ]; then
            echo "$name"
            return 0
        fi
    done
    return 1
}

apply_theme() {
    local THEME="$1"
    local count
    count=$(find "$THEMES_DIR/$THEME" -maxdepth 1 \( -name "*.png" -o -name "*.gif" \) | wc -l)
    echo "$THEME" > "$THEME_FILE"
    rm -f "$STATE_FILE"
    echo "✅ Thème → $THEME ($count images)"
}

# ─── Mode interactif ───
if [ -z "$1" ]; then
    current=$(cat "$THEME_FILE" 2>/dev/null || echo "?")

    if ! command -v gum &>/dev/null; then
        echo "⚠️ Installe 'gum' pour le mode interactif."
        exit 0
    fi

    options=()
    for theme in $(get_themes); do
        count=$(find "$THEMES_DIR/$theme" -maxdepth 1 -name "*.png" | wc -l)
        if [ "$theme" = "$current" ]; then
            options+=("$theme  ($count images) ✓")
        else
            options+=("$theme  ($count images)")
        fi
    done

    selected=$(printf '%s\n' "${options[@]}" | gum filter \
        --placeholder="Rechercher un thème..." \
        --prompt="  ▸ " \
        --indicator="→" \
        --height=12 \
        --header="  Utilise ↑↓ pour naviguer, tape pour filtrer" \
    )

    if [ -z "$selected" ]; then
        echo "Annulé."
        exit 0
    fi

    THEME=$(echo "$selected" | awk '{print $1}')

    if [ "$THEME" = "$current" ]; then
        echo "Déjà sur $THEME."
        exit 0
    fi

    apply_theme "$THEME"

    # ─── Relancer zsh pour appliquer le thème immédiatement ───
    echo "🔄 Rechargement du shell..."
    exec zsh
fi

# ─── Mode direct ───
THEME=$(find_theme "$1")

if [ -z "$THEME" ]; then
    echo "❌ Thème '$1' introuvable."
    echo "Disponibles :"
    for t in $(get_themes); do
        echo "  • $t"
    done
    exit 1
fi

apply_theme "$THEME"

# ─── Relancer zsh pour appliquer le thème immédiatement ───
echo "🔄 Rechargement du shell..."
exec zsh
