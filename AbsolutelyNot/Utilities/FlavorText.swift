import Foundation

enum FlavorText {
    static let passPhrases = [
        "Absolutely Not!",
        "Hard pass.",
        "Nope nope nope.",
        "Not today, Satan.",
        "I'd rather eat glass.",
        "You couldn't pay me to— oh wait.",
        "That's gonna be a no from me, dawg.",
        "Decline with prejudice.",
        "My pebbles say no.",
        "Over my dead counter.",
        "Respectfully... no.",
        "ABSOLUTELY NOT.",
        "lmao no",
        "Pass. Next.",
        "I have a bad feeling about this one.",
        "Not in this economy.",
        "The council has decided: no.",
    ]

    static let takePhrases = [
        "Fine, I'll take it.",
        "...reluctantly.",
        "This better be worth it.",
        "I've made a huge mistake.",
        "Yoink.",
        "Mine now.",
        "The things I do for runs...",
        "Ugh. FINE.",
        "*sighs in pebbles*",
    ]

    static let forcedTakePhrases = [
        "No pebbles, no choice.",
        "Broke and broken.",
        "The universe said: take it.",
        "Poverty strikes again.",
        "Wallet's empty, card's mine.",
    ]

    static func randomPass() -> String {
        // "ABSOLUTELY NOT." appears more frequently
        if Int.random(in: 0..<5) == 0 {
            return "ABSOLUTELY NOT."
        }
        return passPhrases.randomElement() ?? "Absolutely Not!"
    }

    static func randomTake() -> String {
        takePhrases.randomElement() ?? "Yoink."
    }

    static func randomForcedTake() -> String {
        forcedTakePhrases.randomElement() ?? "No choice."
    }
}
