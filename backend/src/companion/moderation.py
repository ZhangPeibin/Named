import re
import unicodedata

RESERVED_NAMES = frozenset(
    {
        "admin",
        "assistant",
        "chatgpt",
        "gpt",
        "milo",
        "named",
        "openai",
        "system",
    }
)

BLOCKED_TERMS = frozenset(
    {
        "asshole",
        "bastard",
        "bitch",
        "blowjob",
        "cunt",
        "dick",
        "faggot",
        "fuck",
        "nazi",
        "nigga",
        "nigger",
        "pussy",
        "rape",
        "retard",
        "slut",
        "whore",
    }
)

_BLOCKED_CJK = (
    "傻逼",
    "操你",
    "贱人",
    "婊子",
    "鸡巴",
    "妈卖批",
)

_WORD_SPLIT = re.compile(r"[^a-z0-9]+")


def _normalize(value: str) -> str:
    return " ".join(unicodedata.normalize("NFKC", value).casefold().split())


def _tokens(value: str) -> set[str]:
    return {token for token in _WORD_SPLIT.split(value) if token}


def name_is_allowed(name: str) -> bool:
    normalized = _normalize(name)
    if not normalized:
        return False
    tokens = _tokens(normalized)
    if tokens & RESERVED_NAMES or tokens & BLOCKED_TERMS:
        return False
    return not any(term in normalized for term in _BLOCKED_CJK)


def hobby_is_allowed(hobby: str) -> bool:
    normalized = _normalize(hobby)
    if not normalized:
        return True
    if _tokens(normalized) & BLOCKED_TERMS:
        return False
    return not any(term in normalized for term in _BLOCKED_CJK)
