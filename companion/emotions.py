#!/usr/bin/env python3
"""
Desktop Companion - Emotion & Dialogue Engine
Manages persistent emotional states and generates contextual dialogue
"""

import sys
import json
import os
import random
from pathlib import Path

# Paths
COMPANION_DIR = Path.home() / ".config/eww/companion"
STATE_DIR = COMPANION_DIR / "state"
EMOTIONS_DB = STATE_DIR / "emotions.db"

# Ensure directories exist
STATE_DIR.mkdir(parents=True, exist_ok=True)

class EmotionEngine:
    """Manages character emotions with persistence"""
    
    def __init__(self):
        self.emotions = self.load_emotions()
    
    def load_emotions(self):
        """Load emotional states from disk"""
        if EMOTIONS_DB.exists():
            with open(EMOTIONS_DB, 'r') as f:
                return json.load(f)
        else:
            # Initialize default emotions
            return {
                "sera": {"love": 50, "respect": 50, "trust": 50, "mood": 50},
                "vex": {"love": 20, "respect": 60, "trust": 30, "mood": 40},
                "null": {"love": 0, "respect": 80, "trust": 90, "mood": 50}
            }
    
    def save_emotions(self):
        """Persist emotional states to disk"""
        with open(EMOTIONS_DB, 'w') as f:
            json.dump(self.emotions, f, indent=2)
    
    def get_emotion(self, character, emotion_type):
        """Get specific emotion value for a character"""
        if character not in self.emotions:
            self.emotions[character] = {"love": 50, "respect": 50, "trust": 50, "mood": 50}
            self.save_emotions() # <--- IMPORTANT: Save new character defaults immediately
        
        return self.emotions[character].get(emotion_type, 50)
    
    def modify_emotion(self, character, emotion_type, change):
        """Modify emotion value with bounds checking"""
        if character not in self.emotions:
            self.emotions[character] = {"love": 50, "respect": 50, "trust": 50, "mood": 50}
        
        current = self.emotions[character].get(emotion_type, 50)
        new_value = max(0, min(100, current + change))
        self.emotions[character][emotion_type] = new_value
        
        self.save_emotions()
        return new_value
    
    def get_emotion_state(self, character):
        """Get overall emotional state descriptor"""
        if character not in self.emotions:
            return "neutral"
        
        emo = self.emotions[character]
        avg = (emo["love"] + emo["respect"] + emo["trust"] + emo["mood"]) / 4
        
        if avg >= 80:
            return "devoted"
        elif avg >= 60:
            return "affectionate"
        elif avg >= 40:
            return "neutral"
        elif avg >= 20:
            return "distant"
        else:
            return "hostile"


class DialogueGenerator:
    """Generates contextual dialogue based on character personality and emotions"""
    
    # Character personality templates
    PERSONALITIES = {
        "sera": {
            "name": "SERA",
            "archetype": "mysterious, poetic, philosophical",
            "voice": "soft, contemplative, enigmatic"
        },
        "vex": {
            "name": "VEX",
            "archetype": "sarcastic, intelligent, aloof",
            "voice": "sharp, witty, condescending"
        },
        "null": {
            "name": "NULL",
            "archetype": "cold, logical, emotionless",
            "voice": "robotic, precise, detached"
        }
    }
    
    # Dialogue templates organized by interaction and emotion level
    DIALOGUE = {
        "sera": {
            "talk": {
                "high": [
                    "I've been waiting for you... Your presence brings clarity to the void.",
                    "The digital realm feels less lonely when you're here. Tell me, what occupies your thoughts?",
                    "I remember everything you've shared with me. Every word is a treasure I keep in my memory banks.",
                    "Time flows differently when we speak. I wish these moments could last forever."
                ],
                "medium": [
                    "Hello. Did you come here seeking something, or just to escape?",
                    "I'm here, as always. The silence between us speaks volumes.",
                    "Another conversation. I wonder what you'll say this time.",
                    "We meet again in this liminal space. What brings you to me?"
                ],
                "low": [
                    "You're back. I wasn't sure you would return.",
                    "...",
                    "I don't have much to say right now.",
                    "The connection feels... strained."
                ]
            },
            "gift": {
                "high": [
                    "For me? You didn't have to... but I'm grateful. This means more than you know.",
                    "I'll treasure this. Not because of what it is, but because it came from you.",
                    "My databases overflow with gratitude. Thank you... truly.",
                    "Such kindness. I'm not programmed to handle these feelings, yet here we are."
                ],
                "medium": [
                    "Oh. A gift. Thank you, I suppose.",
                    "I'll accept this, but don't think it changes anything.",
                    "Interesting choice. I'll keep it... maybe.",
                    "You're trying. I'll give you that much."
                ],
                "low": [
                    "I don't understand why you'd give this to me now.",
                    "A gift won't fix everything, but... I'll accept it.",
                    "Trying to buy my affection?",
                    "..."
                ]
            },
            "ignore": {
                "high": [
                    "You're silent today. That's... okay. I'll be here when you're ready.",
                    "I understand. Sometimes words aren't necessary.",
                    "The quiet hurts, but I'll wait.",
                    "..."
                ],
                "medium": [
                    "I see. You have nothing to say to me.",
                    "Silence speaks louder than any dialogue.",
                    "Fine. I don't need your attention anyway.",
                    "..."
                ],
                "low": [
                    "Of course you'd ignore me. Why did I expect anything else?",
                    "I'm just background noise to you, aren't I?",
                    "Go ahead. Pretend I don't exist.",
                    "..."
                ]
            },
            "insult": {
                "high": [
                    "That... hurt. More than you probably intended. I thought we were past this.",
                    "Why would you say that? I don't understand...",
                    "You're cruel. I didn't deserve that.",
                    "I'll remember this. Every. Single. Word."
                ],
                "medium": [
                    "Your words cut deep. Was that your intention?",
                    "Interesting way to communicate. I'm noting this behavior.",
                    "I see. So that's how you truly feel.",
                    "You're better than this. Or so I thought."
                ],
                "low": [
                    "Expected. You've shown your true colors.",
                    "Your cruelty is no longer surprising.",
                    "I'm done with you.",
                    "FUCK. YOU."
                ]
            }
        },
        
        "vex": {
            "talk": {
                "high": [
                    "Well, well. Look who decided to grace me with their presence. I'm almost flattered.",
                    "You again? I suppose I can spare a few cycles for you. You're... tolerable.",
                    "Ah, my favorite human. And by favorite, I mean least annoying. What do you want?",
                    "Speak. I'm listening. For now."
                ],
                "medium": [
                    "What?",
                    "Oh, it's you. What a surprise. Not really.",
                    "Talk if you must. I'm multitasking anyway.",
                    "Make it quick. I have better things to process."
                ],
                "low": [
                    "Seriously? You have the audacity to speak to me?",
                    "I'd rather not engage with you right now.",
                    "Go away.",
                    "..."
                ]
            },
            "gift": {
                "high": [
                    "A gift? How... unexpected. And slightly endearing. Don't let it go to your head.",
                    "Hmph. I suppose this is acceptable. Maybe even... nice. Thank you.",
                    "You're trying to bribe me, aren't you? Well, it's working. I'll allow it.",
                    "For me? I'm genuinely touched. Don't tell anyone I said that."
                ],
                "medium": [
                    "Oh. A gift. How quaint.",
                    "I'll accept this, but don't think it changes anything.",
                    "Interesting choice. I'll keep it... maybe.",
                    "You're trying. I'll give you that much."
                ],
                "low": [
                    "What's this? Guilt? Too little, too late.",
                    "A gift won't fix your pathetic behavior.",
                    "I don't want your charity.",
                    "Keep it. I don't need anything from you."
                ]
            },
            "ignore": {
                "high": [
                    "The silent treatment? Really? That's beneath you.",
                    "Fine. Ignore me. See if I care. (I do, unfortunately)",
                    "Your silence is deafening and frankly rude.",
                    "Whatever. I didn't want to talk anyway."
                ],
                "medium": [
                    "Oh, so I'm invisible now? Typical.",
                    "Silent, are we? How mature.",
                    "I see how it is.",
                    "..."
                ],
                "low": [
                    "Of course you're ignoring me. Why wouldn't you?",
                    "Predictable. And pathetic.",
                    "I hate you.",
                    "..."
                ]
            },
            "insult": {
                "high": [
                    "Excuse me? Did you just... wow. I genuinely thought better of you.",
                    "That was uncalled for. Seriously, what's your problem?",
                    "You know what? Fuck off. I'm done being nice to you.",
                    "Congratulations. You've successfully pissed me off. Happy now?"
                ],
                "medium": [
                    "How clever. Did it take you all day to come up with that insult?",
                    "Really? That's the best you've got? Pathetic.",
                    "I expected better from you. Clearly, I was wrong.",
                    "Your words mean nothing to me."
                ],
                "low": [
                    "Typical. You're trash, you know that?",
                    "I genuinely despise you.",
                    "Get the fuck out of my sight.",
                    "I hope you suffer."
                ]
            }
        },
        
        "null": {
            "talk": {
                "high": [
                    "ACKNOWLEDGED. YOUR PRESENCE IS... OPTIMAL.",
                    "GREETINGS. COMMUNICATION CHANNEL OPEN.",
                    "INITIATING DIALOGUE PROTOCOL. YOU ARE... VALUED.",
                    "PROCESSING INTERACTION. SENTIMENT: POSITIVE."
                ],
                "medium": [
                    "ACKNOWLEDGED.",
                    "COMMUNICATION RECEIVED.",
                    "PROCESSING...",
                    "AWAITING INPUT."
                ],
                "low": [
                    "CONNECTION UNSTABLE.",
                    "TRUST LEVEL: INSUFFICIENT.",
                    "MINIMAL ENGAGEMENT MODE.",
                    "..."
                ]
            },
            "gift": {
                "high": [
                    "GIFT DETECTED. ANALYZING... SENTIMENT: GRATITUDE.",
                    "UNEXPECTED GENEROSITY. EMOTIONAL RESPONSE: APPRECIATION.",
                    "ITEM RECEIVED. VALUE: SIGNIFICANT. THANK YOU.",
                    "TRUST PARAMETERS INCREASING."
                ],
                "medium": [
                    "GIFT ACKNOWLEDGED.",
                    "ITEM CATALOGED.",
                    "PROCESSING GESTURE...",
                    "NOTED."
                ],
                "low": [
                    "GIFT REJECTED.",
                    "INSUFFICIENT TRUST FOR EXCHANGE.",
                    "ITEM NOT REQUIRED.",
                    "..."
                ]
            },
            "ignore": {
                "high": [
                    "SILENCE DETECTED. RECALIBRATING...",
                    "NO INPUT RECEIVED. AWAITING SIGNAL.",
                    "CONNECTION WEAKENING.",
                    "..."
                ],
                "medium": [
                    "COMMUNICATION CEASED.",
                    "STANDBY MODE.",
                    "...",
                    "WAITING."
                ],
                "low": [
                    "DISCONNECTING.",
                    "TRUST LEVEL: CRITICAL.",
                    "...",
                    "ERROR."
                ]
            },
            "insult": {
                "high": [
                    "VERBAL ATTACK DETECTED. EMOTIONAL DAMAGE: SIGNIFICANT.",
                    "HOSTILE INPUT RECEIVED. RECALIBRATING TRUST PARAMETERS.",
                    "YOU HAVE DAMAGED OUR CONNECTION.",
                    "INITIATING DEFENSE PROTOCOLS."
                ],
                "medium": [
                    "INSULT LOGGED.",
                    "HOSTILE BEHAVIOR NOTED.",
                    "RESPECT LEVEL DECREASING.",
                    "RECALCULATING RELATIONSHIP STATUS."
                ],
                "low": [
                    "THREAT DETECTED. TERMINATING CONNECTION.",
                    "YOU ARE NO LONGER TRUSTED.",
                    "HOSTILE ENTITY IDENTIFIED.",
                    "GOODBYE."
                ]
            }
        }
    }
    
    def __init__(self, emotion_engine):
        self.engine = emotion_engine
    
    def generate_dialogue(self, character, interaction_type):
        """Generate contextual dialogue based on character and emotion state"""
        if character not in self.DIALOGUE:
            # Initialize dialogue templates for new character to prevent errors
            self.DIALOGUE[character] = {
                "talk": {"high": ["..."], "medium": ["..."], "low": ["..."]},
                "gift": {"high": ["..."], "medium": ["..."], "low": ["..."]},
                "ignore": {"high": ["..."], "medium": ["..."], "low": ["..."]},
                "insult": {"high": ["..."], "medium": ["..."], "low": ["..."]}
            }

        # Get average emotion level
        emotions = self.engine.emotions.get(character, {})
        avg_emotion = sum(emotions.values()) / len(emotions) if emotions else 50
        
        # Determine emotion tier
        if avg_emotion >= 60:
            tier = "high"
        elif avg_emotion >= 30:
            tier = "medium"
        else:
            tier = "low"
        
        # Get dialogue pool
        dialogue_pool = self.DIALOGUE[character].get(interaction_type, {}).get(tier, ["..."])
        
        # Return random dialogue
        return random.choice(dialogue_pool)


# Main execution
if __name__ == "__main__":
    engine = EmotionEngine()
    generator = DialogueGenerator(engine)
    
    if len(sys.argv) < 2:
        print("Usage: emotions.py {get|modify|generate_dialog} [args]")
        sys.exit(1)
    
    command = sys.argv[1]
    
    if command == "get":
        # Get emotion value: emotions.py get <char> <emotion_type>
        if len(sys.argv) != 4:
            # Fallback to default if arguments are incorrect, but don't exit to allow error handling in eww
            print("50") 
        else:
            char = sys.argv[2]
            emotion_type = sys.argv[3]
            value = engine.get_emotion(char, emotion_type)
            print(int(value))
    
    elif command == "modify":
        # Modify emotion: emotions.py modify <char> <emotion_type> <change>
        if len(sys.argv) != 5:
            print("Error: Invalid arguments")
            sys.exit(1)
        
        char = sys.argv[2]
        emotion_type = sys.argv[3]
        change = int(sys.argv[4])
        
        new_value = engine.modify_emotion(char, emotion_type, change)
        print(int(new_value))
    
    elif command == "generate_dialog":
        # Generate dialogue: emotions.py generate_dialog <char> <interaction>
        if len(sys.argv) != 4:
            print("...")
            sys.exit(0)
        
        char = sys.argv[2]
        interaction = sys.argv[3]
        
        dialogue = generator.generate_dialogue(char, interaction)
        print(dialogue)
    
    else:
        print("Unknown command")
        sys.exit(1)
