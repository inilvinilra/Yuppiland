#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  VOID — Emoji Picker (Rofi)                                 ║
# ║  ~/.config/hypr/scripts/emoji-picker.sh                      ║
# ╚══════════════════════════════════════════════════════════════╝
set -euo pipefail

THEME="$HOME/.config/rofi/themes/void.rasi"
EMOJI_FILE="$HOME/.config/hypr/scripts/emoji-data.txt"

# --- GENERATE EMOJI DATA IF MISSING ---
if [[ ! -f "$EMOJI_FILE" ]]; then
    cat > "$EMOJI_FILE" << 'EMOJIS'
😀 grinning face
😁 beaming face
😂 face with tears of joy
🤣 rolling on the floor laughing
😃 grinning face with big eyes
😄 grinning face with smiling eyes
😅 grinning face with sweat
😆 squinting face
😉 winking face
😊 smiling face with smiling eyes
😋 face savoring food
😎 smiling face with sunglasses
😍 smiling face with heart-eyes
😘 face blowing a kiss
🥰 smiling face with hearts
😗 kissing face
😙 kissing face with smiling eyes
🥲 smiling face with tear
😏 smirking face
😐 neutral face
😑 expressionless face
😒 unamused face
🙄 face with rolling eyes
😬 grimacing face
😮‍💨 face exhaling
🤥 lying face
😌 relieved face
😔 pensive face
😪 sleepy face
🤤 drooling face
😴 sleeping face
😷 face with medical mask
🤒 face with thermometer
🤕 face with head-bandage
🤢 nauseated face
🤮 face vomiting
🤧 sneezing face
🥵 hot face
🥶 cold face
🥴 woozy face
😵 face with crossed-out eyes
🤯 exploding head
🤠 cowboy hat face
🥳 partying face
🥸 disguised face
😎 sunglasses
🤓 nerd face
🧐 face with monocle
😕 confused face
😟 worried face
🙁 slightly frowning face
😮 face with open mouth
😯 hushed face
😲 astonished face
😳 flushed face
🥺 pleading face
🥹 face holding back tears
😦 frowning face with open mouth
😧 anguished face
😨 fearful face
😰 anxious face with sweat
😥 sad but relieved face
😢 crying face
😭 loudly crying face
😱 face screaming in fear
😖 confounded face
😣 persevering face
😞 disappointed face
😓 downcast face with sweat
😩 weary face
😫 tired face
🥱 yawning face
😤 face with steam from nose
😡 pouting face
😠 angry face
🤬 face with symbols on mouth
💀 skull
☠️ skull and crossbones
💩 pile of poo
🤡 clown face
👹 ogre
👺 goblin
👻 ghost
👽 alien
👾 alien monster
🤖 robot
🎃 jack-o-lantern
👋 waving hand
🤚 raised back of hand
🖐️ hand with fingers splayed
✋ raised hand
🖖 vulcan salute
👌 OK hand
🤌 pinched fingers
🤏 pinching hand
✌️ victory hand
🤞 crossed fingers
🫰 hand with index finger and thumb crossed
🤟 love-you gesture
🤘 sign of the horns
🤙 call me hand
👈 backhand index pointing left
👉 backhand index pointing right
👆 backhand index pointing up
🖕 middle finger
👇 backhand index pointing down
👍 thumbs up
👎 thumbs down
✊ raised fist
👊 oncoming fist
🤛 left-facing fist
🤜 right-facing fist
👏 clapping hands
🙌 raising hands
🫶 heart hands
👐 open hands
🤝 handshake
🙏 folded hands
💪 flexed biceps
🦾 mechanical arm
❤️ red heart
🧡 orange heart
💛 yellow heart
💚 green heart
💙 blue heart
💜 purple heart
🖤 black heart
🤍 white heart
💔 broken heart
❤️‍🔥 heart on fire
💯 hundred points
💢 anger symbol
💥 collision
💫 dizzy
💦 sweat droplets
🔥 fire
⭐ star
🌟 glowing star
✨ sparkles
⚡ high voltage
🎵 musical note
🎶 musical notes
✅ check mark
❌ cross mark
⚠️ warning
🚫 prohibited
♻️ recycling symbol
💡 light bulb
🔑 key
🔒 locked
🔓 unlocked
🛡️ shield
⚙️ gear
🔧 wrench
🔨 hammer
💻 laptop
🖥️ desktop computer
⌨️ keyboard
🖱️ computer mouse
📱 mobile phone
📁 file folder
📂 open file folder
📄 page facing up
📝 memo
📌 pushpin
📎 paperclip
📊 bar chart
📈 chart increasing
📉 chart decreasing
🗑️ wastebasket
🕐 one o'clock
🕑 two o'clock
🕒 three o'clock
⏰ alarm clock
⏳ hourglass
🏠 house
🏢 office building
🚀 rocket
🛸 flying saucer
🌍 globe
🌙 crescent moon
☀️ sun
🌧️ cloud with rain
❄️ snowflake
🌊 water wave
🍕 pizza
🍔 hamburger
🍺 beer mug
☕ hot beverage
🍷 wine glass
🎮 video game
🎯 direct hit
🏆 trophy
🎨 artist palette
🎭 performing arts
📷 camera
🎬 clapper board
🐱 cat face
🐶 dog face
🐺 wolf
🦊 fox
🐧 penguin
🦅 eagle
🐍 snake
🦇 bat
🕷️ spider
🦂 scorpion
→ right arrow
← left arrow
↑ up arrow
↓ down arrow
↔️ left-right arrow
↕️ up-down arrow
⇒ rightwards double arrow
⇐ leftwards double arrow
• bullet
· middle dot
… ellipsis
— em dash
– en dash
© copyright
® registered
™ trade mark
° degree sign
± plus-minus
× multiplication sign
÷ division sign
≈ almost equal to
≠ not equal to
≤ less-than or equal to
≥ greater-than or equal to
∞ infinity
∑ summation
∏ product
√ square root
∫ integral
α alpha
β beta
γ gamma
δ delta
ε epsilon
θ theta
λ lambda
μ mu
π pi
σ sigma
φ phi
ω omega
EMOJIS
fi

# --- SHOW PICKER ---
choice=$(cat "$EMOJI_FILE" | rofi -dmenu \
    -p "emoji" \
    -theme "$THEME" \
    -theme-str 'window { width: 420px; } listview { lines: 12; }' \
    -i) || exit 0

# --- EXTRACT AND COPY ---
emoji=$(echo "$choice" | cut -d' ' -f1)

if [[ -n "$emoji" ]]; then
    echo -n "$emoji" | wl-copy
    notify-send "Emoji" "Copied $emoji to clipboard" -t 1500
fi
